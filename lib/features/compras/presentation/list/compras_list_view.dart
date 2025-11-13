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
  final Set<String> _selectedCompraIds = <String>{};
  bool get _hasSelection => _selectedCompraIds.isNotEmpty;

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
      _selectedCompraIds.removeWhere(
        (String id) => compras.every((Compra compra) => compra.id != id),
      );
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

  void _toggleCompraSelection(Compra compra, bool selected) {
    setState(() {
      if (selected) {
        _selectedCompraIds.add(compra.id);
      } else {
        _selectedCompraIds.remove(compra.id);
      }
    });
  }

  Future<void> _deleteSelectedCompras() async {
    if (_selectedCompraIds.isEmpty) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar compras'),
          content: Text(
            '¿Deseas eliminar ${_selectedCompraIds.length} '
            'compra${_selectedCompraIds.length == 1 ? '' : 's'}? '
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
      for (final String id in _selectedCompraIds) {
        await Compra.deleteById(id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedCompraIds.clear();
      });
      await _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron eliminar las compras: $error')),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  String _estadoGeneral(Compra compra) {
    final String pago = (compra.estadoPago ?? '').toLowerCase();
    final String entrega = (compra.estadoEntrega ?? '').toLowerCase();
    if (pago == 'cancelada' &&
        (entrega == 'completo' || entrega == 'terminado')) {
      return 'terminado';
    }
    if (pago == 'pendiente' || entrega == 'pendiente') {
      return 'pendiente';
    }
    if (entrega == 'sin_productos' && pago != 'cancelada') {
      return 'pendiente';
    }
    if (pago == 'parcial' || entrega == 'parcial') {
      return 'parcial';
    }
    return 'parcial';
  }

  String _formatState(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }
    return value.replaceAll('_', ' ');
  }

  Widget _buildTable(
    List<Compra> items,
    String emptyMessage, {
    bool showCreateShortcut = false,
  }) {
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
          label: 'Pago',
          sortAccessor: (Compra c) => (c.estadoPago ?? '').toLowerCase(),
          cellBuilder: (Compra c) => Text(_formatState(c.estadoPago)),
        ),
        TableColumnConfig<Compra>(
          label: 'Entrega',
          sortAccessor: (Compra c) => (c.estadoEntrega ?? '').toLowerCase(),
          cellBuilder: (Compra c) => Text(_formatState(c.estadoEntrega)),
        ),
        TableColumnConfig<Compra>(
          label: 'General',
          sortAccessor: (Compra c) => _estadoGeneral(c),
          cellBuilder: (Compra c) => Text(_formatState(_estadoGeneral(c))),
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
          '${c.proveedorNombre ?? ''} ${c.observacion ?? ''} '
          '${c.estadoPago ?? ''} ${c.estadoEntrega ?? ''}',
      searchPlaceholder: 'Buscar por proveedor',
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
      selectionConfig: TableSelectionConfig<Compra>(
        isItemSelected: (Compra compra) =>
            _selectedCompraIds.contains(compra.id),
        onSelectionChange: (Compra compra, bool selected) =>
            _toggleCompraSelection(compra, selected),
        selectionMode: _hasSelection,
        showCheckboxColumn: true,
        onRequestSelectionStart: (Compra compra) {
          if (_selectedCompraIds.contains(compra.id)) {
            return;
          }
          setState(() {
            _selectedCompraIds.add(compra.id);
          });
        },
      ),
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
        floatingActionButton: _hasSelection
            ? FloatingActionButton.extended(
                onPressed: _deleteSelectedCompras,
                icon: const Icon(Icons.delete_outline),
                label: Text('Eliminar (${_selectedCompraIds.length})'),
              )
            : FloatingActionButton(
                onPressed: _openCreate,
                tooltip: 'Registrar compra',
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
