import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/bases/presentation/form/bases_form_view.dart';
import 'package:demo_pedidos/models/base_packing.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class BaseDetailView extends StatefulWidget {
  const BaseDetailView({
    super.key,
    required this.baseId,
    required this.currentSection,
  });

  final String baseId;
  final AppSection currentSection;

  @override
  State<BaseDetailView> createState() => _BaseDetailViewState();
}

class _BaseDetailViewState extends State<BaseDetailView> {
  late Future<void> _future = _load();
  LogisticaBase? _base;
  List<BasePacking> _packings = <BasePacking>[];
  bool _hasChanges = false;

  Future<void> _load() async {
    final List<dynamic> result = await Future.wait<dynamic>(<Future<dynamic>>[
      LogisticaBase.getById(widget.baseId),
      BasePacking.fetchByBase(widget.baseId),
    ]);
    final LogisticaBase? base = result[0] as LogisticaBase?;
    final List<BasePacking> packings =
        result[1] as List<BasePacking>;
    if (!mounted) {
      return;
    }
    setState(() {
      _base = base;
      _packings = packings;
    });
  }

  Future<void> _reload() {
    final Future<void> future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _edit() async {
    final LogisticaBase? base = _base;
    if (base == null) {
      return;
    }
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => BasesFormView(base: base),
      ),
    );
    if (result != null) {
      _hasChanges = true;
      await _reload();
    }
  }

  void _handlePop() {
    Navigator.pop(context, _hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        _handlePop();
      },
      child: PageScaffold(
        title: 'Base',
        currentSection: widget.currentSection,
        includeDrawer: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handlePop,
          tooltip: 'Volver',
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _base == null ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        floatingActionButton: FloatingActionButton(
          onPressed: _base == null ? null : _edit,
          tooltip: 'Editar base',
          child: const Icon(Icons.edit),
        ),
        body: FutureBuilder<void>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
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
                      const Text('No se pudo cargar la base.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
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

            final LogisticaBase? base = _base;
            if (base == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('No encontramos esta base.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _handlePop,
                        child: const Text('Volver'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            base.nombre,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Base logística registrada en Supabase.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PackingsSection(packings: _packings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PackingsSection extends StatelessWidget {
  const _PackingsSection({required this.packings});

  final List<BasePacking> packings;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Packings (${packings.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TableSection<BasePacking>(
              items: packings,
              columns: <TableColumnConfig<BasePacking>>[
                TableColumnConfig<BasePacking>(
                  label: 'Nombre',
                  sortAccessor: (BasePacking item) => item.nombre,
                  cellBuilder: (BasePacking item) => Text(item.nombre),
                ),
                TableColumnConfig<BasePacking>(
                  label: 'Estado',
                  sortAccessor: (BasePacking item) => item.activo ? 1 : 0,
                  cellBuilder: (BasePacking item) => Text(
                    item.activo ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color:
                          item.activo ? Colors.green[700] : Colors.red[700],
                    ),
                  ),
                ),
              ],
              emptyMessage: 'Sin packings registrados.',
              shrinkWrap: true,
              showTableHeader: true,
            ),
          ],
        ),
      ),
    );
  }
}
