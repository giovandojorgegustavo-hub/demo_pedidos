import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

import '../form/productos_form_view.dart';

class ProductosListView extends StatefulWidget {
  const ProductosListView({super.key});

  @override
  State<ProductosListView> createState() => _ProductosListViewState();
}

class _ProductosListViewState extends State<ProductosListView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _future = Producto.getProductos();
  }

  Future<void> _reload() async {
    setState(() {
      _future = Producto.getProductos();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Productos',
      currentSection: AppSection.productos,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
      ],
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder:
            (BuildContext context, AsyncSnapshot<List<Producto>> snapshot) {
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
                    const Text('No se pudo cargar la lista de productos.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
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

          final List<Producto> productos = snapshot.data ?? <Producto>[];
          if (productos.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('Aún no registras productos.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openNuevoProducto,
                          child: const Text('Agregar producto'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return TableSection<Producto>(
            items: productos,
            columns: <TableColumnConfig<Producto>>[
              TableColumnConfig<Producto>(
                label: 'Producto',
                sortAccessor: (Producto p) => p.nombre,
                cellBuilder: _nombre,
              ),
              TableColumnConfig<Producto>(
                label: 'Precio (S/)',
                isNumeric: true,
                sortAccessor: (Producto p) => p.precio,
                cellBuilder: _precio,
              ),
            ],
            onRefresh: _reload,
            searchTextBuilder: (Producto p) => p.nombre,
            searchPlaceholder: 'Buscar producto',
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNuevoProducto,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openNuevoProducto() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ProductosFormView(),
      ),
    );
    if (result != null) {
      _reload();
    }
  }

  static Widget _nombre(Producto producto) => Text(producto.nombre);

  static Widget _precio(Producto producto) =>
      Text(producto.precio.toStringAsFixed(2));
}
