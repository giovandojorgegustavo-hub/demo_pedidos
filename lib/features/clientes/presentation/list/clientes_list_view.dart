import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

import '../form/clientes_form_view.dart';

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
    return PageScaffold(
      title: 'Clientes',
      currentSection: AppSection.clientes,
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
                        const Text('Aún no registras clientes.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openNuevoCliente,
                          child: const Text('Agregar cliente'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return TableSection<Cliente>(
            items: clientes,
            columns: <TableColumnConfig<Cliente>>[
              TableColumnConfig<Cliente>(
                label: 'Nombre',
                sortAccessor: (Cliente c) => c.nombre,
                cellBuilder: _clienteNombre,
              ),
              TableColumnConfig<Cliente>(
                label: 'Contacto',
                sortAccessor: (Cliente c) => c.numero,
                cellBuilder: _clienteNumero,
              ),
              TableColumnConfig<Cliente>(
                label: 'Canal',
                sortAccessor: (Cliente c) => c.canal,
                cellBuilder: _clienteCanal,
              ),
              TableColumnConfig<Cliente>(
                label: 'Referido por',
                sortAccessor: (Cliente c) => c.referidoPor ?? '',
                cellBuilder: _clienteReferido,
              ),
            ],
            onRefresh: _reload,
            searchTextBuilder: (Cliente c) =>
                '${c.nombre} ${c.numero} ${c.canal}',
            searchPlaceholder: 'Buscar cliente',
            filters: <TableFilterConfig<Cliente>>[
              TableFilterConfig<Cliente>(
                label: 'Canal',
                options: <TableFilterOption<Cliente>>[
                  const TableFilterOption<Cliente>(
                    label: 'Todos',
                    isDefault: true,
                  ),
                  TableFilterOption<Cliente>(
                    label: 'Telegram',
                    predicate: (Cliente c) =>
                        c.canal.toLowerCase() == 'telegram',
                  ),
                  TableFilterOption<Cliente>(
                    label: 'Referido',
                    predicate: (Cliente c) =>
                        c.canal.toLowerCase() == 'referido',
                  ),
                ],
              ),
            ],
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

  static Widget _clienteNombre(Cliente cliente) => Text(cliente.nombre);

  static Widget _clienteNumero(Cliente cliente) =>
      Text(cliente.numero.isEmpty ? '-' : cliente.numero);

  static Widget _clienteCanal(Cliente cliente) =>
      Text(cliente.canal.isEmpty ? '-' : cliente.canal);

  static Widget _clienteReferido(Cliente cliente) =>
      Text(cliente.referidoPor ?? '-');
}
