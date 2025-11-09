import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/compra.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

import '../detail/compras_detalle_view.dart';
import '../form/compras_form_view.dart';

class ComprasListView extends StatefulWidget {
  const ComprasListView({super.key});

  @override
  State<ComprasListView> createState() => _ComprasListViewState();
}

class _ComprasListViewState extends State<ComprasListView> {
  late Future<List<Compra>> _future;
  int _countPorPagar = 0;
  int _countPorRecibir = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadCompras();
  }

  Future<List<Compra>> _loadCompras() async {
    final List<Compra> compras = await Compra.fetchAll();
    if (!mounted) {
      return compras;
    }
    setState(() {
      _countPorPagar = compras.where(_needsPago).length;
      _countPorRecibir = compras.where(_needsRecepcion).length;
    });
    return compras;
  }

  bool _needsPago(Compra compra) {
    final String status = (compra.estadoPago ?? '').toLowerCase();
    return status.isEmpty || status == 'pendiente' || status == 'parcial';
  }

  bool _needsRecepcion(Compra compra) {
    final String status = (compra.estadoEntrega ?? '').toLowerCase();
    if (status.isEmpty) {
      return true;
    }
    return status != 'completo' && status != 'terminado';
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadCompras();
    });
    await _future;
  }

  Future<void> _openCreate() async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const ComprasFormView(),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openDetalle(Compra compra) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ComprasDetalleView(compraId: compra.id),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  String _formatCurrency(double? value) {
    final double number = value ?? 0;
    return 'S/ ${number.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildTable(List<Compra> items, String emptyMessage,
      {bool showCreateShortcut = false}) {
    return TableSection<Compra>(
      items: items,
      columns: <TableColumnConfig<Compra>>[
        TableColumnConfig<Compra>(
          label: 'Fecha',
          sortAccessor: (Compra c) => c.registradoAt ?? DateTime(2000),
          cellBuilder: (Compra c) => Text(_formatDate(c.registradoAt)),
        ),
        TableColumnConfig<Compra>(
          label: 'Proveedor',
          sortAccessor: (Compra c) => c.proveedorNombre ?? '',
          cellBuilder: (Compra c) => Text(c.proveedorNombre ?? '-'),
        ),
        TableColumnConfig<Compra>(
          label: 'Base',
          sortAccessor: (Compra c) => c.baseNombre ?? '',
          cellBuilder: (Compra c) => Text(c.baseNombre ?? '-'),
        ),
        TableColumnConfig<Compra>(
          label: 'Total',
          isNumeric: true,
          sortAccessor: (Compra c) => c.totalDetalle ?? 0,
          cellBuilder: (Compra c) => Text(_formatCurrency(c.totalDetalle)),
        ),
        TableColumnConfig<Compra>(
          label: 'Pagado',
          isNumeric: true,
          sortAccessor: (Compra c) => c.totalPagado ?? 0,
          cellBuilder: (Compra c) => Text(_formatCurrency(c.totalPagado)),
        ),
        TableColumnConfig<Compra>(
          label: 'Saldo',
          isNumeric: true,
          sortAccessor: (Compra c) => c.saldo ?? 0,
          cellBuilder: (Compra c) => Text(_formatCurrency(c.saldo)),
        ),
      ],
      onRowTap: _openDetalle,
      onRefresh: _reload,
      filters: <TableFilterConfig<Compra>>[
        TableFilterConfig<Compra>(
          label: 'Estado de pago',
          options: <TableFilterOption<Compra>>[
            const TableFilterOption<Compra>(label: 'Todos', isDefault: true),
            TableFilterOption<Compra>(
              label: 'Pendiente',
              predicate: (Compra c) =>
                  (c.estadoPago ?? '').toLowerCase() == 'pendiente',
            ),
            TableFilterOption<Compra>(
              label: 'Parcial',
              predicate: (Compra c) =>
                  (c.estadoPago ?? '').toLowerCase() == 'parcial',
            ),
            TableFilterOption<Compra>(
              label: 'Pagado',
              predicate: (Compra c) =>
                  (c.estadoPago ?? '').toLowerCase() == 'cancelada',
            ),
          ],
        ),
      ],
      searchTextBuilder: (Compra c) =>
          '${c.proveedorNombre ?? ''} ${c.baseNombre ?? ''} ${c.observacion ?? ''}',
      searchPlaceholder: 'Buscar por proveedor o base',
      emptyMessage: emptyMessage,
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
                      child: const Text('Crear primera compra'),
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
        title: 'Compras',
        currentSection: AppSection.operacionesCompras,
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _openCreate,
            tooltip: 'Nueva compra',
            icon: const Icon(Icons.add_shopping_cart_outlined),
          ),
        ],
        bottom: TabBar(
          tabs: <Widget>[
            const Tab(text: 'Todas'),
            Tab(text: 'Por pagar (${_countPorPagar})'),
            Tab(text: 'Por recibir (${_countPorRecibir})'),
          ],
        ),
        body: FutureBuilder<List<Compra>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Compra>> snap) {
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
                      const Text('No se pudo cargar la lista de compras.'),
                      const SizedBox(height: 8),
                      Text('${snap.error}'),
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
            final List<Compra> items = snap.data ?? <Compra>[];
            final List<Compra> porPagar =
                items.where(_needsPago).toList(growable: false);
            final List<Compra> porRecibir =
                items.where(_needsRecepcion).toList(growable: false);

            return TabBarView(
              children: <Widget>[
                _buildTable(
                  items,
                  'Sin compras registradas',
                  showCreateShortcut: true,
                ),
                _buildTable(
                  porPagar,
                  'Todas las compras están pagadas.',
                ),
                _buildTable(
                  porRecibir,
                  'No hay compras pendientes de recibir.',
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openCreate,
          tooltip: 'Registrar compra',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
