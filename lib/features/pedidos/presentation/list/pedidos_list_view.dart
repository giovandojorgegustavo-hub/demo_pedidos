import 'package:demo_pedidos/models/pedido.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

import '../detail/pedidos_detalle_view.dart';
import '../form/pedidos_form_view.dart';

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
  bool get _hasSelection => _selectedPedidoIds.isNotEmpty;
  final Set<String> _selectedPedidoIds = <String>{};

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

  void _togglePedidoSelection(Pedido pedido, bool selected) {
    setState(() {
      if (selected) {
        _selectedPedidoIds.add(pedido.id);
      } else {
        _selectedPedidoIds.remove(pedido.id);
      }
    });
  }

  void _clearSelection() {
    if (_selectedPedidoIds.isEmpty) {
      return;
    }
    setState(() {
      _selectedPedidoIds.clear();
    });
  }

  Future<void> _deleteSelectedPedidos() async {
    if (_selectedPedidoIds.isEmpty) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar pedidos'),
          content: Text(
            '¿Deseas eliminar ${_selectedPedidoIds.length} '
            'pedido${_selectedPedidoIds.length == 1 ? '' : 's'}? '
            'Esta acción no se puede deshacer.',
          ),
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
      for (final String id in _selectedPedidoIds) {
        await Pedido.deleteById(id);
      }
      if (!mounted) {
        return;
      }
      _clearSelection();
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron eliminar los pedidos: $error')),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $h:$min';
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
    final int porCobrar = items.where(_needsPago).length;
    final int porEntregar = items.where(_needsEntrega).length;
    setState(() {
      _countPorCobrar = porCobrar;
      _countPorEntregar = porEntregar;
      _selectedPedidoIds
          .removeWhere((String id) => items.every((Pedido p) => p.id != id));
    });
    return items;
  }

  Widget _buildPedidosList(
    List<Pedido> items,
    String emptyMessage, {
    bool showCreateShortcut = false,
  }) {
    return TableSection<Pedido>(
      items: items,
      columns: _pedidoColumns,
      onRowTap: _openDetalle,
      onRefresh: _reload,
      filters: _pedidoFilters,
      searchTextBuilder: (Pedido pedido) =>
          '${pedido.clienteNombre ?? ''} ${pedido.clienteNumero ?? ''} ${pedido.observacion ?? ''}',
      searchPlaceholder: 'Buscar cliente o número',
      emptyMessage: emptyMessage,
      noResultsMessage: 'No hay pedidos con los filtros seleccionados.',
      minTableWidth: 720,
      dense: true,
      selectionConfig: TableSelectionConfig<Pedido>(
        isItemSelected: (Pedido pedido) =>
            _selectedPedidoIds.contains(pedido.id),
        onSelectionChange: (Pedido pedido, bool selected) {
          _togglePedidoSelection(pedido, selected);
        },
        selectionMode: _hasSelection,
        showCheckboxColumn: true,
        onRequestSelectionStart: (Pedido pedido) {
          if (_selectedPedidoIds.contains(pedido.id)) {
            return;
          }
          setState(() {
            _selectedPedidoIds.add(pedido.id);
          });
        },
      ),
      emptyBuilder: showCreateShortcut
          ? (BuildContext context) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(emptyMessage),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _openCreate,
                      child: const Text('Crear primer pedido'),
                    ),
                  ],
                ),
              )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PageScaffold(
        title: 'Listado de pedidos',
        currentSection: AppSection.pedidos,
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
        floatingActionButton: _hasSelection
            ? FloatingActionButton.extended(
                onPressed: _deleteSelectedPedidos,
                icon: const Icon(Icons.delete_outline),
                label: Text('Eliminar (${_selectedPedidoIds.length})'),
              )
            : FloatingActionButton(
                onPressed: _openCreate,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  void _openCreate() {
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
  }

  void _openDetalle(Pedido pedido) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PedidosDetalleView(pedidoId: pedido.id),
      ),
    ).then((Object? result) {
      if (result == true) {
        _reload();
      }
    });
  }

  List<TableColumnConfig<Pedido>> get _pedidoColumns {
    return <TableColumnConfig<Pedido>>[
      TableColumnConfig<Pedido>(
        label: 'Fecha',
        sortAccessor: (Pedido pedido) => pedido.fechapedido,
        cellBuilder: (Pedido pedido) =>
            Text(_formatDateTime(pedido.fechapedido)),
      ),
      TableColumnConfig<Pedido>(
        label: 'Cliente',
        sortAccessor: (Pedido pedido) => pedido.clienteNombre ?? '',
        cellBuilder: (Pedido pedido) =>
            Text(pedido.clienteNombre ?? 'Cliente desconocido'),
      ),
      TableColumnConfig<Pedido>(
        label: 'Pago',
        sortAccessor: (Pedido pedido) =>
            (pedido.estadoPago ?? '').toLowerCase(),
        cellBuilder: (Pedido pedido) => Text(_formatState(pedido.estadoPago)),
      ),
      TableColumnConfig<Pedido>(
        label: 'Entrega',
        sortAccessor: (Pedido pedido) =>
            (pedido.estadoEntrega ?? '').toLowerCase(),
        cellBuilder: (Pedido pedido) =>
            Text(_formatState(pedido.estadoEntrega)),
      ),
      TableColumnConfig<Pedido>(
        label: 'General',
        sortAccessor: (Pedido pedido) =>
            (pedido.estadoGeneral ?? '').toLowerCase(),
        cellBuilder: (Pedido pedido) =>
            Text(_formatState(pedido.estadoGeneral)),
      ),
    ];
  }

  List<TableFilterConfig<Pedido>> get _pedidoFilters {
    return <TableFilterConfig<Pedido>>[
      TableFilterConfig<Pedido>(
        label: 'Estado pago',
        options: <TableFilterOption<Pedido>>[
          const TableFilterOption<Pedido>(label: 'Todos', isDefault: true),
          TableFilterOption<Pedido>(
            label: 'Pendiente',
            predicate: (Pedido p) =>
                (p.estadoPago ?? '').toLowerCase() == 'pendiente',
          ),
          TableFilterOption<Pedido>(
            label: 'Parcial',
            predicate: (Pedido p) =>
                (p.estadoPago ?? '').toLowerCase() == 'parcial',
          ),
          TableFilterOption<Pedido>(
            label: 'Terminado',
            predicate: (Pedido p) =>
                (p.estadoPago ?? '').toLowerCase() == 'terminado',
          ),
        ],
      ),
      TableFilterConfig<Pedido>(
        label: 'Estado entrega',
        options: <TableFilterOption<Pedido>>[
          const TableFilterOption<Pedido>(label: 'Todos', isDefault: true),
          TableFilterOption<Pedido>(
            label: 'Pendiente',
            predicate: (Pedido p) =>
                (p.estadoEntrega ?? '').toLowerCase() == 'pendiente',
          ),
          TableFilterOption<Pedido>(
            label: 'Parcial',
            predicate: (Pedido p) =>
                (p.estadoEntrega ?? '').toLowerCase() == 'parcial',
          ),
          TableFilterOption<Pedido>(
            label: 'Terminado',
            predicate: (Pedido p) =>
                (p.estadoEntrega ?? '').toLowerCase() == 'terminado',
          ),
        ],
      ),
    ];
  }

  String _formatState(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return 'Sin datos';
    }
    final String lower = normalized.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
