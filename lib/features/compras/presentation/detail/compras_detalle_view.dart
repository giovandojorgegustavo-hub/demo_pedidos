import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/compras/presentation/shared/compra_gasto_form_view.dart';
import 'package:demo_pedidos/features/compras/presentation/shared/compra_movimiento_form_view.dart';
import 'package:demo_pedidos/features/compras/presentation/shared/compra_pago_form_view.dart';
import 'package:demo_pedidos/features/compras/presentation/shared/detalle_compra_form_view.dart';
import 'package:demo_pedidos/models/compra.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/compra_gasto.dart';
import 'package:demo_pedidos/models/compra_movimiento.dart';
import 'package:demo_pedidos/models/compra_movimiento_detalle.dart';
import 'package:demo_pedidos/models/compra_pago.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/detail_inline_section.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';

import '../form/compras_form_view.dart';

class ComprasDetalleView extends StatefulWidget {
  const ComprasDetalleView({super.key, required this.compraId});

  final String compraId;

  @override
  State<ComprasDetalleView> createState() => _ComprasDetalleViewState();
}

class _ComprasDetalleViewState extends State<ComprasDetalleView> {
  Compra? _compra;
  List<CompraDetalle> _detalles = <CompraDetalle>[];
  List<CompraPago> _pagos = <CompraPago>[];
  List<CompraGasto> _gastos = <CompraGasto>[];
  List<Producto> _productos = <Producto>[];
  List<_CompraMovimientoItem> _movimientos = <_CompraMovimientoItem>[];
  String? _deletingDetalleId;
  String? _deletingPagoId;
  String? _deletingGastoId;
  String? _deletingMovimientoId;
  bool _loading = true;
  bool _hasChanges = false;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
      });
    }
    try {
      final List<dynamic> results = await Future.wait<dynamic>(
        <Future<dynamic>>[
          Compra.getById(widget.compraId),
          CompraDetalle.fetchByCompra(widget.compraId),
          CompraPago.fetchByCompra(widget.compraId),
          CompraGasto.fetchByCompra(widget.compraId),
          Producto.getProductos(),
          CompraMovimiento.fetchByCompra(widget.compraId),
        ],
      );
      final Compra? compra = results[0] as Compra?;
      final List<CompraDetalle> detalles =
          results[1] as List<CompraDetalle>;
      final List<CompraPago> pagos = results[2] as List<CompraPago>;
      final List<CompraGasto> gastos = results[3] as List<CompraGasto>;
      final List<Producto> productos = results[4] as List<Producto>;
      final List<CompraMovimiento> movimientosBase =
          results[5] as List<CompraMovimiento>;
      final List<_CompraMovimientoItem> movimientos =
          await _buildMovimientoItems(movimientosBase);
      if (!mounted) {
        return;
      }
      setState(() {
        _compra = compra;
        _detalles = detalles;
        _pagos = pagos;
        _gastos = gastos;
        _productos = productos;
        _movimientos = movimientos;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar la compra: $error')),
      );
    }
  }

  Future<List<_CompraMovimientoItem>> _buildMovimientoItems(
    List<CompraMovimiento> movimientos,
  ) async {
    if (movimientos.isEmpty) {
      return <_CompraMovimientoItem>[];
    }
    final List<List<CompraMovimientoDetalle>> detalles =
        await Future.wait<List<CompraMovimientoDetalle>>(
      movimientos
          .map(
            (CompraMovimiento movimiento) =>
                CompraMovimientoDetalle.fetchByMovimiento(movimiento.id),
          )
          .toList(growable: false),
    );
    return <_CompraMovimientoItem>[
      for (int i = 0; i < movimientos.length; i++)
        _CompraMovimientoItem(
          movimiento: movimientos[i],
          detalles: detalles[i],
        ),
    ];
  }

  Future<void> _reloadAfterChange() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _hasChanges = true;
    });
    await _loadAll(showSpinner: false);
  }

  String _formatCurrency(double? value) {
    final double number = value ?? 0;
    return 'S/ ${number.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
  }

  double _resolveMinWidth(double viewport, double minWidth) {
    return viewport < minWidth ? minWidth : viewport;
  }

  Future<void> _openEdit() async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ComprasFormView(compra: compra),
      ),
    );
    if (changed == true) {
      setState(() {
        _hasChanges = true;
      });
      await _loadAll();
    }
  }

  Future<void> _openDetalleForm({CompraDetalle? detalle}) async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final DetalleCompraFormResult? result =
        await Navigator.push<DetalleCompraFormResult>(
      context,
      MaterialPageRoute<DetalleCompraFormResult>(
        builder: (_) => DetalleCompraFormView(
          compraId: compra.id,
          productos: _productos,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    try {
      final CompraDetalle payload = result.detalle;
      if (payload.id == null) {
        await CompraDetalle.insert(payload);
      } else {
        await CompraDetalle.update(payload);
      }
      if (!mounted) {
        return;
      }
      await _reloadAfterChange();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el detalle: $error')),
      );
    }
  }

  Future<void> _openPagoForm({CompraPago? pago}) async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CompraPagoFormView(
          compraId: compra.id,
          pago: pago,
        ),
      ),
    );
    if (changed == true) {
      await _reloadAfterChange();
    }
  }

  Future<void> _openGastoForm({CompraGasto? gasto}) async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CompraGastoFormView(
          compraId: compra.id,
          gasto: gasto,
        ),
      ),
    );
    if (changed == true) {
      await _reloadAfterChange();
    }
  }

  Future<void> _openMovimientoForm({CompraMovimiento? movimiento}) async {
    final Compra? compra = _compra;
    if (compra == null) {
      return;
    }
    final CompraMovimientoFormResult? result =
        await Navigator.push<CompraMovimientoFormResult>(
      context,
      MaterialPageRoute<CompraMovimientoFormResult>(
        builder: (_) => CompraMovimientoFormView(
          compraId: compra.id,
          productos: _productos,
          movimiento: movimiento,
        ),
      ),
    );
    if (result?.changed == true) {
      await _reloadAfterChange();
    }
  }

  Future<void> _deleteDetalle(String detalleId) async {
    setState(() {
      _deletingDetalleId = detalleId;
    });
    try {
      await CompraDetalle.deleteById(detalleId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingDetalleId = null;
      });
      await _reloadAfterChange();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingDetalleId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el detalle: $error')),
      );
    }
  }

  Future<void> _deletePago(String pagoId) async {
    setState(() {
      _deletingPagoId = pagoId;
    });
    try {
      await CompraPago.deleteById(pagoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPagoId = null;
      });
      await _reloadAfterChange();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPagoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el pago: $error')),
      );
    }
  }

  Future<void> _deleteGasto(String gastoId) async {
    setState(() {
      _deletingGastoId = gastoId;
    });
    try {
      await CompraGasto.deleteById(gastoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingGastoId = null;
      });
      await _reloadAfterChange();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingGastoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el gasto: $error')),
      );
    }
  }

  Future<void> _deleteMovimiento(String movimientoId) async {
    setState(() {
      _deletingMovimientoId = movimientoId;
    });
    try {
      await CompraMovimiento.deleteById(movimientoId);
      await CompraMovimientoDetalle.deleteByMovimiento(movimientoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingMovimientoId = null;
      });
      await _reloadAfterChange();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingMovimientoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el movimiento: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Compra? compra = _compra;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (_isPopping) {
          return;
        }
        _handleBack();
      },
      child: PageScaffold(
        title: 'Detalle de compra',
        currentSection: AppSection.operacionesCompras,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        actions: <Widget>[
          IconButton(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : compra == null
                ? const Center(
                    child: Text('La compra no existe o fue eliminada.'),
                  )
                : _buildBody(compra),
      ),
    );
  }

  void _handleBack() {
    if (_isPopping) {
      return;
    }
    _isPopping = true;
    Navigator.pop(context, _hasChanges);
  }

  Widget _buildBody(Compra compra) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double detalleWidth = _resolveMinWidth(viewportWidth, 600);
        final double pagosWidth = _resolveMinWidth(viewportWidth, 480);
        final double gastosWidth = _resolveMinWidth(viewportWidth, 560);
        final double movimientosWidth = _resolveMinWidth(viewportWidth, 640);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(compra),
              const SizedBox(height: 16),
              DetailInlineSection<CompraDetalle>(
                title: 'Productos',
                items: _detalles,
                columns: _detalleColumns(),
                minTableWidth: detalleWidth,
                onAdd: () => _openDetalleForm(),
                onRowTap: (CompraDetalle detalle) =>
                    _openDetalleForm(detalle: detalle),
                emptyMessage: 'Sin productos registrados.',
              ),
              const SizedBox(height: 8),
              DetailInlineSection<CompraPago>(
                title: 'Pagos',
                items: _pagos,
                columns: _pagoColumns(),
                minTableWidth: pagosWidth,
                onAdd: () => _openPagoForm(),
                emptyMessage: 'Sin pagos registrados.',
              ),
              const SizedBox(height: 8),
              DetailInlineSection<CompraGasto>(
                title: 'Gastos',
                items: _gastos,
                columns: _gastoColumns(),
                minTableWidth: gastosWidth,
                onAdd: () => _openGastoForm(),
                emptyMessage: 'Sin gastos registrados.',
              ),
              const SizedBox(height: 8),
              DetailInlineSection<_CompraMovimientoItem>(
                title: 'Movimientos logísticos',
                items: _movimientos,
                columns: _movimientoColumns(),
                minTableWidth: movimientosWidth,
                onAdd: () => _openMovimientoForm(),
                onRowTap: (_CompraMovimientoItem item) =>
                    _openMovimientoForm(movimiento: item.movimiento),
                emptyMessage: 'Sin movimientos registrados.',
                rowMaxHeightBuilder:
                    (List<_CompraMovimientoItem> items) =>
                        items.any(
                          (_CompraMovimientoItem item) =>
                              (item.movimiento.observacion ?? '').length > 40,
                        )
                            ? 88
                            : null,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(Compra compra) {
    final ThemeData theme = Theme.of(context);
    final List<_FieldRow> rows = <_FieldRow>[
      _FieldRow(label: 'Documento', value: compra.proveedorNumero ?? '-'),
      _FieldRow(
        label: 'Registrado',
        value: _formatDateTime(compra.registradoAt),
      ),
      _FieldRow(
        label: 'Editado',
        value: _formatDateTime(compra.editadoAt),
      ),
      if ((compra.observacion?.trim().isNotEmpty ?? false))
        _FieldRow(
          label: 'Observación',
          value: compra.observacion!,
          multiline: true,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              compra.proveedorNombre ?? 'Proveedor sin nombre',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 16),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  List<TableColumnConfig<CompraDetalle>> _detalleColumns() {
    return <TableColumnConfig<CompraDetalle>>[
      TableColumnConfig<CompraDetalle>(
        label: 'Producto',
        sortAccessor: (CompraDetalle d) => d.productoNombre ?? '',
        cellBuilder: (CompraDetalle d) => Text(d.productoNombre ?? '-'),
      ),
      TableColumnConfig<CompraDetalle>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (CompraDetalle d) => d.cantidad,
        cellBuilder: (CompraDetalle d) =>
            Text(d.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<CompraDetalle>(
        label: 'Costo total',
        isNumeric: true,
        sortAccessor: (CompraDetalle d) => d.costoTotal,
        cellBuilder: (CompraDetalle d) => Text(_formatCurrency(d.costoTotal)),
      ),
      TableColumnConfig<CompraDetalle>(
        label: 'Acciones',
        cellBuilder: (CompraDetalle d) => DetailRowActions(
          onEdit: () => _openDetalleForm(detalle: d),
          onDelete: d.id == null || _deletingDetalleId == d.id
              ? null
              : () => _deleteDetalle(d.id!),
          isDeleting: _deletingDetalleId == d.id,
        ),
      ),
    ];
  }

  List<TableColumnConfig<CompraPago>> _pagoColumns() {
    return <TableColumnConfig<CompraPago>>[
      TableColumnConfig<CompraPago>(
        label: 'Cuenta',
        sortAccessor: (CompraPago p) => p.cuentaNombre ?? '',
        cellBuilder: (CompraPago p) => Text(p.cuentaNombre ?? '-'),
      ),
      TableColumnConfig<CompraPago>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (CompraPago p) => p.monto,
        cellBuilder: (CompraPago p) => Text(_formatCurrency(p.monto)),
      ),
      TableColumnConfig<CompraPago>(
        label: 'Acciones',
        cellBuilder: (CompraPago p) => DetailRowActions(
          onEdit: () => _openPagoForm(pago: p),
          onDelete: _deletingPagoId == p.id ? null : () => _deletePago(p.id),
          isDeleting: _deletingPagoId == p.id,
        ),
      ),
    ];
  }

  List<TableColumnConfig<CompraGasto>> _gastoColumns() {
    return <TableColumnConfig<CompraGasto>>[
      TableColumnConfig<CompraGasto>(
        label: 'Cuenta contable',
        sortAccessor: (CompraGasto g) => g.cuentaContable ?? '',
        cellBuilder: (CompraGasto g) => Text(g.cuentaContable ?? '-'),
      ),
      TableColumnConfig<CompraGasto>(
        label: 'Cuenta bancaria',
        sortAccessor: (CompraGasto g) => g.cuentaNombre ?? '',
        cellBuilder: (CompraGasto g) => Text(g.cuentaNombre ?? '-'),
      ),
      TableColumnConfig<CompraGasto>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (CompraGasto g) => g.monto,
        cellBuilder: (CompraGasto g) => Text(_formatCurrency(g.monto)),
      ),
      TableColumnConfig<CompraGasto>(
        label: 'Observación',
        sortAccessor: (CompraGasto g) => g.observacion ?? '',
        cellBuilder: (CompraGasto g) => Text(g.observacion ?? '-'),
      ),
      TableColumnConfig<CompraGasto>(
        label: 'Acciones',
        cellBuilder: (CompraGasto g) => DetailRowActions(
          onEdit: () => _openGastoForm(gasto: g),
          onDelete:
              _deletingGastoId == g.id ? null : () => _deleteGasto(g.id),
          isDeleting: _deletingGastoId == g.id,
        ),
      ),
    ];
  }

  List<TableColumnConfig<_CompraMovimientoItem>> _movimientoColumns() {
    return <TableColumnConfig<_CompraMovimientoItem>>[
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Base',
        sortAccessor: (_CompraMovimientoItem item) =>
            item.movimiento.baseNombre ?? '',
        cellBuilder: (_CompraMovimientoItem item) =>
            Text(item.movimiento.baseNombre ?? '-'),
      ),
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Productos',
        isNumeric: true,
        sortAccessor: (_CompraMovimientoItem item) => item.productosCount,
        cellBuilder: (_CompraMovimientoItem item) =>
            Text('${item.productosCount}'),
      ),
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (_CompraMovimientoItem item) => item.totalCantidad,
        cellBuilder: (_CompraMovimientoItem item) =>
            Text(item.totalCantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Observación',
        cellBuilder: (_CompraMovimientoItem item) {
          final String text =
              (item.movimiento.observacion ?? '').trim();
          return Text(text.isEmpty ? '-' : text);
        },
      ),
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Registrado',
        sortAccessor: (_CompraMovimientoItem item) =>
            item.movimiento.registradoAt ?? DateTime(2000),
        cellBuilder: (_CompraMovimientoItem item) =>
            Text(_formatDateTime(item.movimiento.registradoAt)),
      ),
      TableColumnConfig<_CompraMovimientoItem>(
        label: 'Acciones',
        cellBuilder: (_CompraMovimientoItem item) => DetailRowActions(
          onEdit: () => _openMovimientoForm(movimiento: item.movimiento),
          onDelete: _deletingMovimientoId == item.movimiento.id
              ? null
              : () => _deleteMovimiento(item.movimiento.id),
          isDeleting: _deletingMovimientoId == item.movimiento.id,
        ),
      ),
    ];
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge,
          maxLines: multiline ? null : 1,
          overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _CompraMovimientoItem {
  const _CompraMovimientoItem({
    required this.movimiento,
    required this.detalles,
  });

  final CompraMovimiento movimiento;
  final List<CompraMovimientoDetalle> detalles;

  int get productosCount => detalles.length;

  double get totalCantidad => detalles.fold<double>(
        0,
        (double previousValue, CompraMovimientoDetalle detalle) =>
            previousValue + detalle.cantidad,
      );
}
