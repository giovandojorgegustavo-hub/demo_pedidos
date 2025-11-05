import 'package:flutter/material.dart';

import '../models/cliente.dart';
import '../widgets/app_drawer.dart';
import 'clientes_form.dart';

class ClientesListView extends StatefulWidget {
  const ClientesListView({super.key});

  @override
  State<ClientesListView> createState() => _ClientesListViewState();
}

class _ClientesListViewState extends State<ClientesListView> {
  late Future<List<Cliente>> _future;

  @override
  void initState() {
    super.initState();
    _future = Cliente.getClientes();
  }

  Future<void> _reload() async {
    setState(() {
      _future = Cliente.getClientes();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(current: AppSection.clientes),
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _openNuevoCliente,
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Agregar cliente',
          ),
        ],
      ),
      body: FutureBuilder<List<Cliente>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Cliente>> snapshot) {
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
                    const Text('No se pudo cargar la lista de clientes.'),
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

          final List<Cliente> clientes = snapshot.data ?? <Cliente>[];
          if (clientes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Aún no registras clientes.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _openNuevoCliente,
                      child: const Text('Agregar cliente'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: clientes.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (BuildContext context, int index) {
                final Cliente cliente = clientes[index];
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(cliente.nombre),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Contacto: ${cliente.numero}'),
                      Text('Canal: ${cliente.canal}'),
                      if (cliente.referidoPor != null)
                        Text('Referido por: ${cliente.referidoPor}'),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNuevoCliente,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openNuevoCliente() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ClientesFormView(),
      ),
    );
    if (result != null) {
      _reload();
    }
  }
}
