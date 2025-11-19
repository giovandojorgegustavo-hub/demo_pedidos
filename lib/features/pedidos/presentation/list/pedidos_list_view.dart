import 'package:demo_pedidos/features/pedidos/presentation/actions/pedidos_actions.dart';
import 'package:demo_pedidos/models/pedido.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/templates/list_view_template.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidosListView extends StatefulWidget {
  const PedidosListView({super.key});

  @override
  State<PedidosListView> createState() => _PedidosListViewState();
}

class _PedidosListViewState extends State<PedidosListView> {
  RealtimeChannel? _realtimeChannel;

  @override
  void dispose() {
    _disposeRealtime();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListViewTemplate<Pedido>(
      config: ListViewTemplateConfig<Pedido>(
        title: 'Listado de pedidos',
        currentSection: AppSection.pedidos,
        loader: Pedido.getPedidos,
        idSelector: (Pedido pedido) => pedido.id,
        columns: _pedidoColumns,
        filters: _pedidoFilters,
        searchTextBuilder: (Pedido pedido) => '${pedido.clienteNombre ?? ''} '
            '${pedido.clienteNumero ?? ''} '
            '${pedido.observacion ?? ''}',
        searchPlaceholder: 'Buscar cliente o número',
        minTableWidth: 720,
        noResultsMessage: 'No hay pedidos con los filtros seleccionados.',
        onRowTap: _openDetalle,
        onCreate: _openCreate,
        onDeleteSelected: _deleteSelected,
        confirmDeleteBuilder: _confirmDelete,
        deleteSelectionLabelBuilder: (int count) => 'Eliminar ($count)',
        deleteErrorMessageBuilder: (Object error) =>
            'No se pudieron eliminar los pedidos: $error',
        tabs: <ListViewTemplateTab<Pedido>>[
          ListViewTemplateTab<Pedido>(
            labelBuilder: (_) => 'Todos',
            emptyMessage: 'Sin pedidos',
            showCreateShortcut: true,
          ),
          ListViewTemplateTab<Pedido>(
            labelBuilder: (List<Pedido> items) =>
                'Por cobrar (${items.where(_needsPago).length})',
            predicate: _needsPago,
            emptyMessage: 'Todos los pedidos están al día en pagos.',
          ),
          ListViewTemplateTab<Pedido>(
            labelBuilder: (List<Pedido> items) =>
                'Por entregar (${items.where(_needsEntrega).length})',
            predicate: _needsEntrega,
            emptyMessage: 'Todos los pedidos fueron entregados.',
          ),
        ],
        onInit: _setupRealtime,
        onDispose: _disposeRealtime,
      ),
    );
  }

  Future<void> _openCreate(
    ListViewTemplateController<Pedido> controller,
  ) async {
    final bool created = await PedidosActions.create(context);
    if (created) {
      await controller.reload();
    }
  }

  Future<void> _openDetalle(
    Pedido pedido,
    ListViewTemplateController<Pedido> controller,
  ) async {
    final bool changed = await PedidosActions.openDetail(context, pedido.id);
    if (changed) {
      await controller.reload();
    }
  }

  Future<void> _deleteSelected(
    ListViewTemplateController<Pedido> controller,
    Set<String> ids,
  ) async {
    await PedidosActions.deleteByIds(ids);
  }

  Future<bool> _confirmDelete(BuildContext context, int count) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Eliminar pedidos'),
            content: Text(
              '¿Deseas eliminar $count pedido'
              '${count == 1 ? '' : 's'}? Esta acción no se puede deshacer.',
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
          ),
        ) ??
        false;
  }

  void _setupRealtime(ListViewTemplateController<Pedido> controller) {
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
          controller.reload();
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

  void _disposeRealtime() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  static bool _needsPago(Pedido pedido) {
    final String status = (pedido.estadoPago ?? '').toLowerCase();
    return status.isEmpty || status == 'pendiente' || status == 'parcial';
  }

  static bool _needsEntrega(Pedido pedido) {
    final String status = (pedido.estadoEntrega ?? '').toLowerCase();
    return status.isEmpty || status != 'terminado';
  }

  static String _formatDateTime(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $h:$min';
  }

  static String _formatState(String? value) {
    final String normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return 'Sin datos';
    }
    final String lower = normalized.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }

  List<TableColumnConfig<Pedido>> get _pedidoColumns {
    return <TableColumnConfig<Pedido>>[
      TableColumnConfig<Pedido>(
        label: 'Fecha',
        sortAccessor: (Pedido pedido) => pedido.fechapedido,
        cellBuilder: (Pedido pedido) => Text(_formatDateTime(
          pedido.fechapedido,
        )),
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
}
