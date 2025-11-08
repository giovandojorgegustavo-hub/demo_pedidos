import 'package:demo_pedidos/features/movimientos/presentation/shared/detalle_movimiento_form_view.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class DetalleMovimientoListView extends StatefulWidget {
  const DetalleMovimientoListView({
    super.key,
    required this.movimientoId,
    this.includeDrawer = false,
    this.returnResult = false,
  });

  final String movimientoId;
  final bool includeDrawer;
  final bool returnResult;

  @override
  State<DetalleMovimientoListView> createState() =>
      _DetalleMovimientoListViewState();
}

class _DetalleMovimientoListViewState
    extends State<DetalleMovimientoListView> {
  late Future<void> _future;
  List<DetalleMovimiento> _detalles = <DetalleMovimiento>[];
  List<Producto> _productos = <Producto>[];
  bool _hasChanges = false;
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() async {
    final List<DetalleMovimiento> detalles =
        await DetalleMovimiento.getByMovimiento(widget.movimientoId);
    final List<Producto> productos = await Producto.getProductos();
    if (!mounted) {
      return;
    }
    setState(() {
      _detalles = detalles;
      _productos = productos;
    });
  }

  Future<void> _refresh() {
    final Future<void> future = _loadData();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _reloadProductos() async {
    try {
      final List<Producto> productos = await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productos;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar los productos: $error'),
        ),
      );
    }
  }

  Future<void> _openForm({DetalleMovimiento? detalle}) async {
    List<Producto> productos = _productos;
    if (productos.isEmpty) {
      await _reloadProductos();
      if (!mounted) {
        return;
      }
      productos = _productos;
    }
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles.')),
      );
      return;
    }

    final DetalleMovimientoFormResult? result =
        await Navigator.push<DetalleMovimientoFormResult>(
      context,
      MaterialPageRoute<DetalleMovimientoFormResult>(
        builder: (_) => DetalleMovimientoFormView(
          detalle: detalle,
          productos: productos,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _reloadProductos();
      if (!mounted) {
        return;
      }
    }

    try {
      if (detalle?.id != null) {
        await DetalleMovimiento.update(
          DetalleMovimiento(
            id: detalle!.id,
            idmovimiento: widget.movimientoId,
            idproducto: result.detalle.idproducto,
            cantidad: result.detalle.cantidad,
            productoNombre: result.detalle.productoNombre,
          ),
        );
      } else {
        await DetalleMovimiento.insert(
          widget.movimientoId,
          DetalleMovimiento(
            idproducto: result.detalle.idproducto,
            cantidad: result.detalle.cantidad,
            productoNombre: result.detalle.productoNombre,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      _hasChanges = true;
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el producto: $error')),
      );
    }
  }

  Future<void> _delete(DetalleMovimiento detalle) async {
    final String? id = detalle.id;
    if (id == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: const Text(
            '¿Deseas eliminar este producto del movimiento? Esta acción no se puede deshacer.',
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

    setState(() {
      _deletingId = id;
    });
    try {
      await DetalleMovimiento.delete(id);
      if (!mounted) {
        return;
      }
      _hasChanges = true;
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingId = null;
      });
    }
  }

  List<TableColumnConfig<DetalleMovimiento>> _columns() {
    return <TableColumnConfig<DetalleMovimiento>>[
      TableColumnConfig<DetalleMovimiento>(
        label: 'Producto',
        sortAccessor: (DetalleMovimiento item) => item.productoNombre ?? '',
        cellBuilder: (DetalleMovimiento item) =>
            Text(item.productoNombre ?? 'Producto'),
      ),
      TableColumnConfig<DetalleMovimiento>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (DetalleMovimiento item) => item.cantidad,
        cellBuilder: (DetalleMovimiento item) =>
            Text(item.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<DetalleMovimiento>(
        label: 'Acciones',
        cellBuilder: (DetalleMovimiento item) => DetailRowActions(
          onEdit: () => _openForm(detalle: item),
          onDelete: item.id == null || _deletingId == item.id
              ? null
              : () => _delete(item),
          isDeleting: _deletingId == item.id,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = PageScaffold(
      title: 'Productos del movimiento',
      currentSection: AppSection.movimientos,
      includeDrawer: widget.includeDrawer,
      actions: <Widget>[
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: FutureBuilder<void>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
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
                    const Text('No se pudo cargar el detalle del movimiento.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return TableSection<DetalleMovimiento>(
            items: _detalles,
            columns: _columns(),
            onRowTap: (DetalleMovimiento item) => _openForm(detalle: item),
            onRefresh: _refresh,
            emptyMessage: 'Sin productos registrados.',
            minTableWidth: 640,
            searchTextBuilder: (DetalleMovimiento item) =>
                '${item.productoNombre ?? ''} ${item.cantidad}',
            searchPlaceholder: 'Buscar producto',
            filters: _filters,
          );
        },
      ),
    );

    if (!widget.returnResult) {
      return page;
    }

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, true);
      },
      child: page,
    );
  }

  List<TableFilterConfig<DetalleMovimiento>> get _filters {
    return <TableFilterConfig<DetalleMovimiento>>[
      TableFilterConfig<DetalleMovimiento>(
        label: 'Cantidad',
        options: <TableFilterOption<DetalleMovimiento>>[
          const TableFilterOption<DetalleMovimiento>(
            label: 'Todas',
            isDefault: true,
          ),
          TableFilterOption<DetalleMovimiento>(
            label: 'Sin cantidad',
            predicate: (DetalleMovimiento item) => item.cantidad <= 0,
          ),
          TableFilterOption<DetalleMovimiento>(
            label: 'Mayor a cero',
            predicate: (DetalleMovimiento item) => item.cantidad > 0,
          ),
        ],
      ),
    ];
  }
}
