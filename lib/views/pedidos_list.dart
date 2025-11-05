import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pedido.dart';
import '../widgets/app_drawer.dart';
import 'pedidos_detalle.dart';
import 'pedidos_form.dart';

class PedidosListView extends StatefulWidget {
  const PedidosListView({super.key});

  @override
  State<PedidosListView> createState() => _PedidosListViewState();
}

class _PedidosListViewState extends State<PedidosListView> {
  late Future<List<Pedido>> _future;
  int _countPorCobrar = 0;
  int _countPorEntregar = 0;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _future = _loadPedidos();
    _setupRealtime();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadPedidos();
    });
    try {
      await _future;
    } catch (_) {
      // El error se mostrará en el FutureBuilder.
    }
  }

  String _formatDate(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  String _statusLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sin datos';
    }
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  bool _needsPago(Pedido pedido) {
    final String status = (pedido.estadoPago ?? '').toLowerCase();
    return status.isEmpty || status == 'pendiente' || status == 'parcial';
  }

  bool _needsEntrega(Pedido pedido) {
    final String status = (pedido.estadoEntrega ?? '').toLowerCase();
    return status.isEmpty || status != 'terminado';
  }

  void _setupRealtime() {
    final SupabaseClient client = Supabase.instance.client;
    final RealtimeChannel channel = client.channel('public:pedidos_realtime');

    void registerTable(String table) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (PostgresChangePayload payload) {
          if (!mounted) {
            return;
          }
          _reload();
        },
      );
    }

    for (final String table in <String>[
      'pedidos',
      'detallepedidos',
      'pagos',
      'cargos_cliente',
      'movimientopedidos',
      'detallemovimientopedidos',
    ]) {
      registerTable(table);
    }

    channel.subscribe();
    _realtimeChannel = channel;
  }

  Future<List<Pedido>> _loadPedidos() async {
    final List<Pedido> items = await Pedido.getPedidos();
    if (!mounted) {
      return items;
    }
    final int porCobrar =
        items.where(_needsPago).length;
    final int porEntregar =
        items.where(_needsEntrega).length;
    setState(() {
      _countPorCobrar = porCobrar;
      _countPorEntregar = porEntregar;
    });
    return items;
  }

  Color _stateColor(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'terminado':
        return Colors.green.shade600;
      case 'parcial':
        return Colors.blueGrey;
      case 'pendiente':
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _buildStateChip(String label, String? value) {
    final Color color = _stateColor(value);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        value == null || value.isEmpty ? 'Sin datos' : label,
        style: TextStyle(color: color),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildPedidosList(
    List<Pedido> items,
    String emptyMessage, {
    bool showCreateShortcut = false,
  }) {
    if (items.isEmpty) {
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
                  Text(emptyMessage),
                  if (showCreateShortcut) ...<Widget>[
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const PedidosFormView(),
                          ),
                        ).then((Object? result) {
                          if (result == true) {
                            _reload();
                          }
                        });
                      },
                      child: const Text('Crear primer pedido'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

          return RefreshIndicator(
            onRefresh: _reload,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double breakpoint = 600;
                if (constraints.maxWidth < breakpoint) {
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Pedido pedido = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    PedidosDetalleView(pedidoId: pedido.id),
                              ),
                            ).then((Object? result) {
                              if (result == true) {
                                _reload();
                              }
                            });
                          },
                          title: Text(
                            pedido.clienteNombre ?? 'Cliente desconocido',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Fecha: ${_formatDate(pedido.fechapedido)}'),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: <Widget>[
                                  _buildStateChip('Pago', pedido.estadoPago),
                                  _buildStateChip('Entrega', pedido.estadoEntrega),
                                  _buildStateChip('General', pedido.estadoGeneral),
                                ],
                              ),
                              if (pedido.observacion != null &&
                                  pedido.observacion!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text('Obs: ${pedido.observacion}'),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                        ),
                      );
                    },
                  );
                }

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: <Widget>[
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowHeight: 48,
                          dataRowHeight: 52,
                          columns: const <DataColumn>[
                            DataColumn(label: Text('Cliente')),
                            DataColumn(label: Text('Fecha')),
                            DataColumn(label: Text('Pago')),
                            DataColumn(label: Text('Entrega')),
                            DataColumn(label: Text('General')),
                            DataColumn(label: Text('Obs')),
                          ],
                          rows: items.map((Pedido pedido) {
                            return DataRow(
                              onSelectChanged: (bool? selected) {
                                if (selected == true) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          PedidosDetalleView(pedidoId: pedido.id),
                                    ),
                                  ).then((Object? result) {
                                    if (result == true) {
                                      _reload();
                                    }
                                  });
                                }
                              },
                              cells: <DataCell>[
                                DataCell(
                                  Text(
                                    pedido.clienteNombre ??
                                        'Cliente desconocido',
                                  ),
                                ),
                                DataCell(
                                  Text(_formatDate(pedido.fechapedido)),
                                ),
                                DataCell(
                                  Text(_statusLabel(pedido.estadoPago)),
                                ),
                                DataCell(
                                  Text(_statusLabel(pedido.estadoEntrega)),
                                ),
                                DataCell(
                                  Text(_statusLabel(pedido.estadoGeneral)),
                                ),
                                DataCell(
                                  Text(
                                    (pedido.observacion ?? '').isEmpty
                                        ? '-'
                                        : pedido.observacion!,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        drawer: const AppDrawer(current: AppSection.pedidos),
        appBar: AppBar(
          title: const Text('Listado de pedidos'),
          actions: <Widget>[
            IconButton(
              onPressed: _reload,
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              const Tab(text: 'Todos'),
              Tab(text: 'Por cobrar (${_countPorCobrar})'),
              Tab(text: 'Por entregar (${_countPorEntregar})'),
            ],
          ),
        ),
        body: FutureBuilder<List<Pedido>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Pedido>> snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text('No se pudo cargar la lista.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error}',
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

            final List<Pedido> items = snap.data ?? <Pedido>[];
            final List<Pedido> porCobrar =
                items.where(_needsPago).toList(growable: false);
            final List<Pedido> porEntregar =
                items.where(_needsEntrega).toList(growable: false);

            return TabBarView(
              children: <Widget>[
                _buildPedidosList(
                  items,
                  'Sin pedidos',
                  showCreateShortcut: true,
                ),
                _buildPedidosList(
                  porCobrar,
                  'Todos los pedidos están al día en pagos.',
                ),
                _buildPedidosList(
                  porEntregar,
                  'Todos los pedidos fueron entregados.',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PedidosFormView(),
              ),
            ).then((Object? result) {
              if (result == true) {
                _reload();
              }
            });
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
