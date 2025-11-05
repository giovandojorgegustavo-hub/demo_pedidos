import 'package:flutter/material.dart';

import '../models/producto.dart';
import '../widgets/app_drawer.dart';
import 'productos_form.dart';

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
    return Scaffold(
      drawer: const AppDrawer(current: AppSection.productos),
      appBar: AppBar(
        title: const Text('Productos'),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Producto>> snapshot) {
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
            return Center(
              child: Padding(
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
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: productos.length,
              itemBuilder: (BuildContext context, int index) {
                final Producto producto = productos[index];
                return ListTile(
                  leading: const Icon(Icons.fastfood_outlined),
                  title: Text(producto.nombre),
                  subtitle: Text('Precio: S/ ${producto.precio.toStringAsFixed(2)}'),
                );
              },
            ),
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
}
