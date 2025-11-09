import 'package:demo_pedidos/features/movimientos/presentation/detail/movimiento_detalle_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/form/movimiento_form_view.dart';
import 'package:demo_pedidos/models/movimiento_pedido.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MovimientosListView extends StatefulWidget {
  const MovimientosListView({
    super.key,
    this.pedidoId,
    this.includeDrawer = true,
    this.returnResult = false,
  });

  final String? pedidoId;
  final bool includeDrawer;
  final bool returnResult;

  @override
  State<MovimientosListView> createState() => _MovimientosListViewState();
}

class _MovimientosListViewState extends State<MovimientosListView> {
  Future<List<MovimientoResumen>>? _generalFuture;
  Map<int, int> _estadoCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0};

  bool get _isGeneralView => widget.pedidoId == null;

  @override
  void initState() {
    super.initState();
    if (_isGeneralView) {
      _generalFuture = _loadGeneralMovimientos();
    }
  }

  Future<List<MovimientoResumen>> _loadGeneralMovimientos() async {
    final List<MovimientoResumen> data = await MovimientoResumen.fetchAll();
    _scheduleCountsUpdate(data);
    return data;
  }

  void _scheduleCountsUpdate(List<MovimientoResumen> items) {
    final Map<int, int> updated = <int, int>{
      1: items.where((MovimientoResumen m) => m.estadoCodigo == 1).length,
      2: items.where((MovimientoResumen m) => m.estadoCodigo == 2).length,
      3: items.where((MovimientoResumen m) => m.estadoCodigo == 3).length,
      4: items.where((MovimientoResumen m) => m.estadoCodigo == 4).length,
    };
    if (mapEquals(updated, _estadoCounts)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _estadoCounts = updated;
      });
    });
  }

  void _reloadGeneral() {
    setState(() {
      _generalFuture = _loadGeneralMovimientos();
    });
  }

  Future<bool?> _openDetalle(BuildContext context, MovimientoResumen item) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoDetalleView(movimientoId: item.id),
      ),
    );
  }

  Future<bool?> _createMovimiento(BuildContext context) {
    final String? pedidoId = widget.pedidoId;
    if (pedidoId == null) {
      return Future<bool?>.value(false);
    }
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoFormView(
          pedidoId: pedidoId,
          clienteId: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isGeneralView) {
      return _buildPedidoMovimientosPage();
    }
    return _buildGeneralMovimientosPage();
  }

  Widget _buildGeneralMovimientosPage() {
    return DefaultTabController(
      length: 5,
      child: PageScaffold(
        title: 'Movimientos logísticos',
        currentSection: AppSection.movimientos,
        includeDrawer: widget.includeDrawer,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _reloadGeneral,
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          tabs: <Tab>[
            const Tab(text: 'Todos'),
            Tab(text: 'Pendiente (${_estadoCounts[1] ?? 0})'),
            Tab(text: 'Asignado (${_estadoCounts[2] ?? 0})'),
            Tab(text: 'Enviado (${_estadoCounts[3] ?? 0})'),
            const Tab(text: 'Llegado'),
          ],
        ),
        body: FutureBuilder<List<MovimientoResumen>>(
          future: _generalFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<MovimientoResumen>> snapshot,
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
                      const Text('No se pudo cargar la lista.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _reloadGeneral,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final List<MovimientoResumen> items =
                snapshot.data ?? <MovimientoResumen>[];
            final List<MovimientoResumen> pendientes = items
                .where((MovimientoResumen m) => m.estadoCodigo == 1)
                .toList(growable: false);
            final List<MovimientoResumen> asignados = items
                .where((MovimientoResumen m) => m.estadoCodigo == 2)
                .toList(growable: false);
            final List<MovimientoResumen> enviados = items
                .where((MovimientoResumen m) => m.estadoCodigo == 3)
                .toList(growable: false);
            final List<MovimientoResumen> llegados = items
                .where((MovimientoResumen m) => m.estadoCodigo == 4)
                .toList(growable: false);

            return TabBarView(
              children: <Widget>[
                _buildTableSection(
                  context,
                  items,
                  emptyMessage: 'Sin movimientos registrados.',
                ),
                _buildTableSection(
                  context,
                  pendientes,
                  emptyMessage: 'No hay movimientos pendientes.',
                ),
                _buildTableSection(
                  context,
                  asignados,
                  emptyMessage: 'No hay movimientos asignados.',
                ),
                _buildTableSection(
                  context,
                  enviados,
                  emptyMessage: 'No hay movimientos enviados.',
                ),
                _buildTableSection(
                  context,
                  llegados,
                  emptyMessage: 'No hay movimientos completados.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableSection(
    BuildContext context,
    List<MovimientoResumen> items, {
    required String emptyMessage,
  }) {
    return TableSection<MovimientoResumen>(
      items: items,
      columns: _columns,
      onRowTap: (MovimientoResumen item) async {
        final bool? changed = await _openDetalle(context, item);
        if (changed == true) {
          _reloadGeneral();
        }
      },
      onRefresh: () async {
        _reloadGeneral();
      },
      filters: _filters,
      searchTextBuilder: (MovimientoResumen m) =>
          '${m.clienteNombre} ${m.clienteNumero ?? ''} ${m.contactoNumero ?? ''} '
          '${m.baseNombre ?? ''} ${m.observacion ?? ''}',
      searchPlaceholder: 'Buscar cliente, número, base u observación',
      emptyMessage: emptyMessage,
      minTableWidth: 720,
    );
  }

  Widget _buildPedidoMovimientosPage() {
    final String pedidoId = widget.pedidoId!;
    return EntityTablePage<MovimientoResumen>(
      title: 'Movimientos del pedido',
      includeDrawer: false,
      returnResult: widget.returnResult,
      currentSection: widget.includeDrawer ? AppSection.movimientos : null,
      loadItems: () => MovimientoResumen.fetchByPedido(pedidoId),
      columns: _columns,
      onRowTap: (BuildContext context, MovimientoResumen item) async {
        final bool? changed = await _openDetalle(context, item);
        return changed ?? false;
      },
      onCreate: (BuildContext context) => _createMovimiento(context),
      searchTextBuilder: (MovimientoResumen m) =>
          '${m.clienteNombre} ${m.clienteNumero ?? ''} '
          '${m.contactoNumero ?? ''} ${m.baseNombre ?? ''} '
          '${m.esProvincia ? (m.provinciaDestino ?? '') : (m.direccion ?? '')} '
          '${m.observacion ?? ''}',
      searchPlaceholder: 'Buscar cliente, número, base u observación',
      filters: _filters,
      minTableWidth: 640,
      onDeleteSelected:
          (BuildContext context, List<MovimientoResumen> selected) async {
        for (final MovimientoResumen resumen in selected) {
          await MovimientoPedido.deleteById(resumen.id);
        }
      },
    );
  }

  List<TableColumnConfig<MovimientoResumen>> get _columns {
    return <TableColumnConfig<MovimientoResumen>>[
      TableColumnConfig<MovimientoResumen>(
        label: 'Fecha',
        sortAccessor: (MovimientoResumen m) => m.fecha,
        cellBuilder: (MovimientoResumen m) => Text(_formatDateTime(m.fecha)),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Cliente',
        sortAccessor: (MovimientoResumen m) => m.clienteNombre,
        cellBuilder: (MovimientoResumen m) => Text(m.clienteNombre),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Contacto',
        sortAccessor: (MovimientoResumen m) =>
            m.contactoNumero ?? m.clienteNumero ?? '',
        cellBuilder: (MovimientoResumen m) =>
            Text(m.contactoNumero ?? m.clienteNumero ?? '-'),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Dirección / Destino',
        sortAccessor: (MovimientoResumen m) =>
            m.esProvincia ? (m.provinciaDestino ?? '') : (m.direccion ?? ''),
        cellBuilder: (MovimientoResumen m) => Text(
          m.esProvincia
              ? (m.provinciaDestino ?? '-')
              : (m.direccion ?? 'Sin dirección'),
        ),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Observación',
        sortAccessor: (MovimientoResumen m) => m.observacion ?? '',
        cellBuilder: (MovimientoResumen m) => Text(
            (m.observacion?.trim().isNotEmpty ?? false)
                ? m.observacion!.trim()
                : '-'),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Provincia',
        sortAccessor: (MovimientoResumen m) => m.esProvincia ? '1' : '0',
        cellBuilder: (MovimientoResumen m) => Text(m.esProvincia ? 'Sí' : 'No'),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Base',
        sortAccessor: (MovimientoResumen m) => m.baseNombre ?? '',
        cellBuilder: (MovimientoResumen m) => Text(m.baseNombre ?? '-'),
      ),
      TableColumnConfig<MovimientoResumen>(
        label: 'Estado',
        sortAccessor: (MovimientoResumen m) => m.estadoCodigo,
        cellBuilder: (MovimientoResumen m) => _estadoChip(m),
      ),
    ];
  }

  List<TableFilterConfig<MovimientoResumen>> get _filters {
    return <TableFilterConfig<MovimientoResumen>>[
      TableFilterConfig<MovimientoResumen>(
        label: 'Provincia',
        options: <TableFilterOption<MovimientoResumen>>[
          const TableFilterOption<MovimientoResumen>(
            label: 'Todas',
            isDefault: true,
          ),
          TableFilterOption<MovimientoResumen>(
            label: 'Lima',
            predicate: (MovimientoResumen m) => !m.esProvincia,
          ),
          TableFilterOption<MovimientoResumen>(
            label: 'Provincia',
            predicate: (MovimientoResumen m) => m.esProvincia,
          ),
        ],
      ),
    ];
  }

  Widget _estadoChip(MovimientoResumen movimiento) {
    final Color color = _estadoColor(movimiento.estadoCodigo);
    return Chip(
      label: Text(_estadoLabel(movimiento.estadoTexto)),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }

  String _estadoLabel(String raw) {
    if (raw.isEmpty) {
      return 'Sin estado';
    }
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Color _estadoColor(int code) {
    switch (code) {
      case 1:
        return Colors.blueGrey;
      case 2:
        return Colors.orange.shade700;
      case 3:
        return Colors.blue.shade600;
      case 4:
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }
}
