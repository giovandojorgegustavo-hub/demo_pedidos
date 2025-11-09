import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/proveedor.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

import '../form/proveedores_form_view.dart';

class ProveedoresListView extends StatefulWidget {
  const ProveedoresListView({super.key});

  @override
  State<ProveedoresListView> createState() => _ProveedoresListViewState();
}

class _ProveedoresListViewState extends State<ProveedoresListView> {
  late Future<List<Proveedor>> _future;

  @override
  void initState() {
    super.initState();
    _future = Proveedor.fetchAll();
  }

  Future<void> _reload() async {
    setState(() {
      _future = Proveedor.fetchAll();
    });
    await _future;
  }

  Future<void> _openForm({Proveedor? proveedor}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ProveedoresFormView(proveedor: proveedor),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _delete(Proveedor proveedor) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar proveedor'),
          content: Text('¿Eliminar a ${proveedor.nombre}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    try {
      await Proveedor.deleteById(proveedor.id);
      if (!mounted) {
        return;
      }
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Proveedores',
      currentSection: AppSection.proveedores,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () => _openForm(),
          tooltip: 'Nuevo proveedor',
          icon: const Icon(Icons.add_business),
        ),
      ],
      body: FutureBuilder<List<Proveedor>>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<List<Proveedor>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudo cargar la lista de proveedores.'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final List<Proveedor> items = snapshot.data ?? <Proveedor>[];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: <Widget>[
                        const Text('Aún no registras proveedores.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _openForm(),
                          child: const Text('Agregar proveedor'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return TableSection<Proveedor>(
            items: items,
            columns: <TableColumnConfig<Proveedor>>[
              TableColumnConfig<Proveedor>(
                label: 'Nombre',
                sortAccessor: (Proveedor p) => p.nombre,
                cellBuilder: (Proveedor p) => Text(p.nombre),
              ),
              TableColumnConfig<Proveedor>(
                label: 'Contacto',
                sortAccessor: (Proveedor p) => p.numero,
                cellBuilder: (Proveedor p) => Text(p.numero.isEmpty ? '-' : p.numero),
              ),
              TableColumnConfig<Proveedor>(
                label: 'Acciones',
                cellBuilder: (Proveedor p) => Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      tooltip: 'Editar',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openForm(proveedor: p),
                    ),
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _delete(p),
                    ),
                  ],
                ),
              ),
            ],
            onRefresh: _reload,
            searchTextBuilder: (Proveedor p) => '${p.nombre} ${p.numero}',
            searchPlaceholder: 'Buscar proveedor',
            emptyMessage: 'Sin proveedores registrados',
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Nuevo proveedor',
        child: const Icon(Icons.add),
      ),
    );
  }
}
