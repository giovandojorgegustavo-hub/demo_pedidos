import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/finanzas/presentation/cuentas_contables/cuentas_contables_form_view.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';

class CuentasContablesListView extends StatefulWidget {
  const CuentasContablesListView({super.key});

  @override
  State<CuentasContablesListView> createState() =>
      _CuentasContablesListViewState();
}

class _CuentasContablesListViewState
    extends State<CuentasContablesListView> {
  late Future<List<CuentaContable>> _future = _load();
  List<CuentaContable> _cuentas = <CuentaContable>[];
  List<_CuentaNode> _rootNodes = <_CuentaNode>[];
  final Map<String, _CuentaNode> _nodeById = <String, _CuentaNode>{};

  Future<List<CuentaContable>> _load() => CuentaContable.fetchAll();

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _prepareTree(List<CuentaContable> cuentas) {
    _cuentas = cuentas;
    _nodeById.clear();
    final Map<String, _CuentaNode> nodes = <String, _CuentaNode>{
      for (final CuentaContable cuenta in cuentas)
        cuenta.id: _CuentaNode(cuenta: cuenta),
    };
    final List<_CuentaNode> roots = <_CuentaNode>[];
    for (final _CuentaNode node in nodes.values) {
      final String? parentId = node.cuenta.parentId;
      if (parentId == null || !nodes.containsKey(parentId)) {
        roots.add(node);
      } else {
        nodes[parentId]!.children.add(node);
      }
      _nodeById[node.cuenta.id] = node;
    }
    _sortNodes(roots);
    _rootNodes = roots;
  }

  void _sortNodes(List<_CuentaNode> nodes) {
    nodes.sort(
      (_CuentaNode a, _CuentaNode b) =>
          a.cuenta.codigo.compareTo(b.cuenta.codigo),
    );
    for (final _CuentaNode node in nodes) {
      _sortNodes(node.children);
    }
  }

  Future<void> _openForm({
    CuentaContable? cuenta,
    CuentaContable? parent,
  }) async {
    final _CuentaNode? node =
        cuenta == null ? null : _nodeById[cuenta.id];
    final Set<String> excluded = <String>{
      if (node != null) ..._collectIds(node),
    };
    final bool hasChildren = node?.children.isNotEmpty ?? false;

    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CuentaContableFormView(
          cuenta: cuenta,
          cuentas: _cuentas,
          initialParentId: cuenta?.parentId ?? parent?.id,
          initialTipo: cuenta?.tipo ?? parent?.tipo,
          excludedParentIds: excluded,
          hasChildren: hasChildren,
        ),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Set<String> _collectIds(_CuentaNode node) {
    final Set<String> ids = <String>{node.cuenta.id};
    for (final _CuentaNode child in node.children) {
      ids.addAll(_collectIds(child));
    }
    return ids;
  }

  List<Widget> _buildTreeWidgets(List<_CuentaNode> nodes, int depth) {
    final List<Widget> widgets = <Widget>[];
    for (final _CuentaNode node in nodes) {
      widgets.add(
        Card(
          margin: EdgeInsets.only(
            left: 16 + depth * 16,
            right: 16,
            top: 4,
            bottom: 4,
          ),
          child: ListTile(
            title: Text('${node.cuenta.codigo} · ${node.cuenta.nombre}'),
            subtitle: Text(_tipoLabel(node.cuenta.tipo)),
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  label: Text(
                    node.cuenta.esTerminal ? 'Terminal' : 'Agrupador',
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    switch (value) {
                      case 'edit':
                        _openForm(cuenta: node.cuenta);
                        break;
                      case 'child':
                        _openForm(parent: node.cuenta);
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'child',
                      child: ListTile(
                        leading: Icon(Icons.subdirectory_arrow_right),
                        title: Text('Agregar subcuenta'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _openForm(cuenta: node.cuenta),
          ),
        ),
      );
      widgets.addAll(_buildTreeWidgets(node.children, depth + 1));
    }
    return widgets;
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'activo':
        return 'Activo';
      case 'pasivo':
        return 'Pasivo';
      case 'patrimonio':
        return 'Patrimonio';
      case 'ingreso':
        return 'Ingreso';
      case 'gasto':
        return 'Gasto';
      default:
        return tipo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Cuentas contables',
      currentSection: AppSection.finanzasCuentas,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        IconButton(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          tooltip: 'Nueva cuenta',
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<CuentaContable>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<CuentaContable>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No se pudieron cargar las cuentas.'),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          final List<CuentaContable> cuentas =
              snapshot.data ?? <CuentaContable>[];
          _prepareTree(cuentas);
          if (cuentas.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras cuentas contables.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            );
          }
          final List<Widget> treeWidgets =
              _buildTreeWidgets(_rootNodes, 0);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Organiza tus cuentas contables en jerarquías. '
                    'Sólo las cuentas terminales pueden usarse en movimientos.',
                  ),
                ),
                const SizedBox(height: 8),
                ...treeWidgets,
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CuentaNode {
  _CuentaNode({required this.cuenta});

  final CuentaContable cuenta;
  final List<_CuentaNode> children = <_CuentaNode>[];
}
