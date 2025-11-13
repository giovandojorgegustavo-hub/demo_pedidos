import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/proveedores/presentation/form/proveedores_form_view.dart';
import 'package:demo_pedidos/models/compra.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/compra_gasto.dart';
import 'package:demo_pedidos/models/compra_pago.dart';
import 'package:demo_pedidos/models/compra_movimiento.dart';
import 'package:demo_pedidos/models/compra_movimiento_detalle.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/models/proveedor.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

import '../shared/compra_gasto_form_view.dart';
import '../shared/compra_movimiento_form_view.dart';
import '../shared/compra_pago_form_view.dart';
import '../shared/detalle_compra_form_view.dart';

class ComprasFormView extends StatefulWidget {
  const ComprasFormView({super.key, this.compra});

  final Compra? compra;

  @override
  State<ComprasFormView> createState() => _ComprasFormViewState();
}

class _ComprasFormViewState extends State<ComprasFormView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  List<Proveedor> _proveedores = <Proveedor>[];
  List<Producto> _productos = <Producto>[];
  List<CompraDetalle> _detalles = <CompraDetalle>[];
  List<CompraPago> _pagos = <CompraPago>[];
  List<CompraGasto> _gastos = <CompraGasto>[];
  List<_CompraMovimientoRow> _movimientos = <_CompraMovimientoRow>[];
  Map<String, double> _draftMovimientoTotals = <String, double>{};

  bool _isLoadingProveedores = true;
  bool _isLoadingProductos = true;
  bool _isLoadingDetalles = false;
  bool _isLoadingPagos = false;
  bool _isLoadingGastos = false;
  bool _isLoadingMovimientos = false;
  bool _isSaving = false;
  bool _isPersistingDraft = false;
  String? _deletingMovimientoId;
  bool _draftCreatedInSession = false;

  String? _selectedProveedorId;
  String? _compraId;
  DateTime? _registradoAt;

  late final List<_InlineSectionConfigBase> _inlineSections =
      <_InlineSectionConfigBase>[
    _InlineSectionConfig<CompraDetalle>(
      key: 'detalle',
      title: 'Detalle de compra',
      helperText: 'Productos o insumos incluidos en esta compra.',
      emptyMessage: 'Sin productos registrados.',
      minTableWidth: 600,
      itemsSelector: ( _ComprasFormViewState state) => state._detalles,
      isLoadingSelector: ( _ComprasFormViewState state) =>
          state._isLoadingDetalles,
      columnsBuilder: ( _ComprasFormViewState state) =>
          state._detalleColumns(),
      onAdd: ( _ComprasFormViewState state) => state._openDetalleForm(),
      onEdit: ( _ComprasFormViewState state, CompraDetalle detalle) =>
          state._openDetalleForm(detalle: detalle),
      loadDataCallback: ( _ComprasFormViewState state) => state._loadDetalles(),
      loadOnInitWhenEditing: true,
    ),
    _InlineSectionConfig<CompraPago>(
      key: 'pagos',
      title: 'Pagos',
      helperText: 'Registra desembolsos realizados al proveedor.',
      emptyMessage: 'Sin pagos registrados.',
      minTableWidth: 420,
      itemsSelector: ( _ComprasFormViewState state) => state._pagos,
      isLoadingSelector: ( _ComprasFormViewState state) =>
          state._isLoadingPagos,
      columnsBuilder: ( _ComprasFormViewState state) =>
          state._pagoColumns(),
      onAdd: ( _ComprasFormViewState state) => state._openPagoForm(),
      onEdit: ( _ComprasFormViewState state, CompraPago pago) =>
          state._openPagoForm(pago: pago),
      loadDataCallback: ( _ComprasFormViewState state) => state._loadPagos(),
      loadOnInitWhenEditing: true,
    ),
    _InlineSectionConfig<CompraGasto>(
      key: 'gastos',
      title: 'Gastos',
      helperText: 'Gastos asociados a la compra (fletes, servicios, etc.).',
      emptyMessage: 'Sin gastos registrados.',
      minTableWidth: 520,
      itemsSelector: ( _ComprasFormViewState state) => state._gastos,
      isLoadingSelector: ( _ComprasFormViewState state) =>
          state._isLoadingGastos,
      columnsBuilder: ( _ComprasFormViewState state) =>
          state._gastoColumns(),
      onAdd: ( _ComprasFormViewState state) => state._openGastoForm(),
      onEdit: ( _ComprasFormViewState state, CompraGasto gasto) =>
          state._openGastoForm(gasto: gasto),
      loadDataCallback: ( _ComprasFormViewState state) => state._loadGastos(),
      loadOnInitWhenEditing: true,
    ),
    _InlineSectionConfig<_CompraMovimientoRow>(
      key: 'movimientos',
      title: 'Movimientos',
      helperText:
          'Registra cómo ingresa esta compra a tus bases logísticas.',
      emptyMessage: 'Sin movimientos registrados.',
      minTableWidth: 560,
      itemsSelector: ( _ComprasFormViewState state) => state._movimientos,
      isLoadingSelector: ( _ComprasFormViewState state) =>
          state._isLoadingMovimientos,
      columnsBuilder: ( _ComprasFormViewState state) =>
          state._movimientoColumns(),
      onAdd: ( _ComprasFormViewState state) => state._openMovimientoForm(),
      onEdit:
          ( _ComprasFormViewState state, _CompraMovimientoRow row) =>
              state._openMovimientoForm(row: row),
      loadDataCallback: ( _ComprasFormViewState state) =>
          state._loadMovimientos(),
      loadOnInitWhenEditing: true,
    ),
  ];

  bool get _isEditing => widget.compra != null;
  bool get _isDraftContext => !_isEditing;

  @override
  void initState() {
    super.initState();
    final Compra? compra = widget.compra;
    if (compra != null) {
      _compraId = compra.id;
      _selectedProveedorId = compra.idproveedor;
      _registradoAt = compra.registradoAt;
      _observacionController.text = compra.observacion ?? '';
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>(<Future<void>>[
      _loadProveedores(selectId: _selectedProveedorId),
      _loadProductos(),
    ]);
    if (_isEditing) {
      await Future.wait<void>(<Future<void>>[
        _loadDetalles(),
        _loadPagos(),
        _loadGastos(),
        _loadMovimientos(),
      ]);
    }
  }

  Future<void> _loadProveedores({String? selectId}) async {
    setState(() {
      _isLoadingProveedores = true;
    });
    try {
      final List<Proveedor> proveedores = await Proveedor.fetchAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _proveedores = proveedores;
        _isLoadingProveedores = false;
        if (selectId != null &&
            proveedores.any((Proveedor p) => p.id == selectId)) {
          _selectedProveedorId = selectId;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProveedores = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar proveedores: $error')),
      );
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoadingProductos = true;
    });
    try {
      final List<Producto> productos = await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productos;
        _isLoadingProductos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProductos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<void> _loadDetalles() async {
    final String? compraId = _compraId;
    if (compraId == null) {
      return;
    }
    setState(() {
      _isLoadingDetalles = true;
    });
    try {
      final List<CompraDetalle> detalles =
          await CompraDetalle.fetchByCompra(compraId);
      if (!mounted) {
        return;
      }
      setState(() {
        _detalles = detalles;
        _isLoadingDetalles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDetalles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los detalles: $error')),
      );
    }
  }

  Future<void> _loadPagos() async {
    final String? compraId = _compraId;
    if (compraId == null) {
      return;
    }
    setState(() {
      _isLoadingPagos = true;
    });
    try {
      final List<CompraPago> pagos = await CompraPago.fetchByCompra(compraId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pagos = pagos;
        _isLoadingPagos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPagos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los pagos: $error')),
      );
    }
  }

  Future<void> _loadGastos() async {
    final String? compraId = _compraId;
    if (compraId == null) {
      return;
    }
    setState(() {
      _isLoadingGastos = true;
    });
    try {
      final List<CompraGasto> gastos =
          await CompraGasto.fetchByCompra(compraId);
      if (!mounted) {
        return;
      }
      setState(() {
        _gastos = gastos;
        _isLoadingGastos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingGastos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los gastos: $error')),
      );
    }
  }

  Future<void> _loadMovimientos() async {
    final String? compraId = _compraId;
    if (compraId == null) {
      return;
    }
    setState(() {
      _isLoadingMovimientos = true;
    });
    try {
      final List<CompraMovimiento> movimientos =
          await CompraMovimiento.fetchByCompra(compraId);
      final List<List<CompraMovimientoDetalle>> detallesList =
          movimientos.isEmpty
              ? <List<CompraMovimientoDetalle>>[]
              : await Future.wait<List<CompraMovimientoDetalle>>(
                  movimientos.map(
                    (CompraMovimiento movimiento) =>
                        CompraMovimientoDetalle.fetchByMovimiento(
                      movimiento.id,
                    ),
                  ),
                );
      if (!mounted) {
        return;
      }
      setState(() {
        _movimientos = <_CompraMovimientoRow>[
          for (int i = 0; i < movimientos.length; i++)
            _CompraMovimientoRow(
              movimiento: movimientos[i],
              detalles: detallesList.length > i
                  ? detallesList[i]
                  : <CompraMovimientoDetalle>[],
            ),
        ];
        _isLoadingMovimientos = false;
        _draftMovimientoTotals = _isDraftContext
            ? _buildDraftMovimientoTotals(_movimientos)
            : <String, double>{};
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMovimientos = false;
        _draftMovimientoTotals = _isDraftContext
            ? _buildDraftMovimientoTotals(_movimientos)
            : <String, double>{};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los movimientos: $error')),
      );
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _openNuevoProveedor() async {
    final ProveedorFormResult? result = await Navigator.push<ProveedorFormResult>(
      context,
      MaterialPageRoute<ProveedorFormResult>(
        builder: (_) => const ProveedoresFormView(),
      ),
    );
    if (result?.changed == true) {
      await _loadProveedores(selectId: result?.proveedorId);
    }
  }

  Future<void> _openDetalleForm({CompraDetalle? detalle}) async {
    if (_isLoadingProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    final DetalleCompraFormResult? result =
        await Navigator.push<DetalleCompraFormResult>(
      context,
      MaterialPageRoute<DetalleCompraFormResult>(
        builder: (_) => DetalleCompraFormView(
          compraId: _compraId ?? 'temp',
          productos: _productos,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _loadProductos();
    }
    setState(() {
      if (detalle == null) {
        _detalles = <CompraDetalle>[..._detalles, result.detalle];
      } else {
        _detalles = _detalles.map((CompraDetalle item) {
          if (item == detalle) {
            return result.detalle;
          }
          return item;
        }).toList();
      }
    });
  }

  Future<void> _openPagoForm({CompraPago? pago}) async {
    if (!await _ensureCompraPersisted()) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CompraPagoFormView(
          compraId: _compraId!,
          pago: pago,
        ),
      ),
    );
    if (changed == true) {
      await _loadPagos();
    }
  }

  Future<void> _openGastoForm({CompraGasto? gasto}) async {
    if (!await _ensureCompraPersisted()) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CompraGastoFormView(
          compraId: _compraId!,
          gasto: gasto,
        ),
      ),
    );
    if (changed == true) {
      await _loadGastos();
    }
  }

  Future<void> _openMovimientoForm({_CompraMovimientoRow? row}) async {
    if (!await _ensureCompraPersisted()) {
      return;
    }
    if (_isLoadingProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    final Map<String, double>? draftBuffer =
        _draftBufferForMovimiento(row: row);
    final CompraMovimientoFormResult? result =
        await Navigator.push<CompraMovimientoFormResult>(
      context,
      MaterialPageRoute<CompraMovimientoFormResult>(
        builder: (_) => CompraMovimientoFormView(
          compraId: _compraId!,
          productos: _productos,
          movimiento: row?.movimiento,
          compraDetallesDraft: _detalles.isEmpty ? null : _detalles,
          compraDraftMovimientoConsumos: draftBuffer,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _loadProductos();
      if (!mounted) {
        return;
      }
    }
    if (result.changed) {
      await _loadMovimientos();
    }
  }

  Future<void> _deleteMovimiento(String movimientoId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: const Text(
          'Esta acción eliminará el movimiento y su detalle. ¿Deseas continuar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _deletingMovimientoId = movimientoId;
    });
    try {
      await CompraMovimiento.deleteById(movimientoId);
      await _loadMovimientos();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el movimiento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingMovimientoId = null;
        });
      }
    }
  }

  Future<bool> _ensureCompraPersisted() async {
    if (_compraId != null) {
      return true;
    }
    if (_selectedProveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor primero.')),
      );
      return false;
    }
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión.')),
      );
      return false;
    }
    setState(() {
      _isPersistingDraft = true;
    });
    try {
      final Compra draft = Compra(
        id: '',
        idproveedor: _selectedProveedorId!,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        registradoAt: DateTime.now(),
        editadoAt: null,
      );
      final String newId = await Compra.insert(draft);
      if (!mounted) {
        return false;
      }
      setState(() {
        _compraId = newId;
        _registradoAt = draft.registradoAt;
        _draftCreatedInSession = true;
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear la compra: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isPersistingDraft = false;
        });
      }
    }
  }

  Future<void> _handleCancel() async {
    if (_isSaving || _isPersistingDraft) {
      return;
    }
    if (widget.compra == null && _draftCreatedInSession && _compraId != null) {
      try {
        await Compra.deleteById(_compraId!);
      } catch (_) {
        // ignore cleanup errors
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context, false);
  }

  Future<void> _onSave() async {
    if (_isSaving || _formKey.currentState?.validate() != true) {
      return;
    }
    if (_selectedProveedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un proveedor.')),
      );
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final DateTime now = DateTime.now();
    final Compra payload = Compra(
      id: _compraId ?? '',
      idproveedor: _selectedProveedorId!,
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
      registradoAt: _registradoAt ?? now,
      editadoAt: now,
    );

    try {
      String compraId = _compraId ?? '';
      if (_compraId == null) {
        compraId = await Compra.insert(payload);
      } else {
        await Compra.update(payload.copyWith(id: compraId));
        await _supabase.from('compras_detalle').delete().eq('idcompra', compraId);
      }

      final List<Map<String, dynamic>> detalleMaps =
          _detalles.map((CompraDetalle detalle) {
        final Map<String, dynamic> map = detalle.toJson();
        map['idcompra'] = compraId;
        map.remove('id');
        return map;
      }).toList(growable: false);
      if (detalleMaps.isNotEmpty) {
        await _supabase.from('compras_detalle').insert(detalleMaps);
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _compraId = compraId;
        _registradoAt = payload.registradoAt;
        _draftCreatedInSession = false;
      });
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la compra: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  List<TableColumnConfig<CompraDetalle>> _detalleColumns() {
    return <TableColumnConfig<CompraDetalle>>[
      TableColumnConfig<CompraDetalle>(
        label: 'Producto',
        sortAccessor: (CompraDetalle d) => d.productoNombre ?? '',
        cellBuilder: (CompraDetalle d) => Text(
          d.productoNombre ?? 'Producto',
        ),
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
        cellBuilder: (CompraDetalle d) =>
            Text('S/ ${d.costoTotal.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<CompraDetalle>(
        label: 'Acciones',
        cellBuilder: (CompraDetalle d) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openDetalleForm(detalle: d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _detalles.remove(d);
                });
              },
            ),
          ],
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
        cellBuilder: (CompraPago p) => Text('S/ ${p.monto.toStringAsFixed(2)}'),
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
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (CompraGasto g) => g.monto,
        cellBuilder: (CompraGasto g) =>
            Text('S/ ${g.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<CompraGasto>(
        label: 'Observación',
        sortAccessor: (CompraGasto g) => g.observacion ?? '',
        cellBuilder: (CompraGasto g) => Text(g.observacion ?? '-'),
      ),
    ];
  }

  List<TableColumnConfig<_CompraMovimientoRow>> _movimientoColumns() {
    return <TableColumnConfig<_CompraMovimientoRow>>[
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Registro',
        sortAccessor: (_CompraMovimientoRow row) =>
            row.movimiento.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (_CompraMovimientoRow row) =>
            Text(_formatDateTime(row.movimiento.registradoAt)),
      ),
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Base',
        sortAccessor: (_CompraMovimientoRow row) =>
            row.movimiento.baseNombre ?? '',
        cellBuilder: (_CompraMovimientoRow row) =>
            Text(row.movimiento.baseNombre ?? '-'),
      ),
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Productos',
        isNumeric: true,
        sortAccessor: (_CompraMovimientoRow row) => row.detalles.length,
        cellBuilder: (_CompraMovimientoRow row) =>
            Text('${row.detalles.length}'),
      ),
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Unidades',
        isNumeric: true,
        sortAccessor: (_CompraMovimientoRow row) =>
            _movimientoCantidadTotal(row),
        cellBuilder: (_CompraMovimientoRow row) =>
            Text(_movimientoCantidadTotal(row).toStringAsFixed(2)),
      ),
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Observación',
        sortAccessor: (_CompraMovimientoRow row) =>
            row.movimiento.observacion ?? '',
        cellBuilder: (_CompraMovimientoRow row) =>
            Text(row.movimiento.observacion ?? '-'),
      ),
      TableColumnConfig<_CompraMovimientoRow>(
        label: 'Acciones',
        cellBuilder: (_CompraMovimientoRow row) {
          final bool isDeleting =
              _deletingMovimientoId == row.movimiento.id;
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                tooltip: 'Editar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openMovimientoForm(row: row),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteMovimiento(row.movimiento.id),
                ),
            ],
          );
        },
      ),
    ];
  }

  double _movimientoCantidadTotal(_CompraMovimientoRow row) {
    return row.detalles.fold<double>(
      0,
      (double sum, CompraMovimientoDetalle detalle) => sum + detalle.cantidad,
    );
  }

  Map<String, double> _buildDraftMovimientoTotals(
    List<_CompraMovimientoRow> movimientos,
  ) {
    if (movimientos.isEmpty) {
      return <String, double>{};
    }
    final Map<String, double> totals = <String, double>{};
    for (final _CompraMovimientoRow row in movimientos) {
      for (final CompraMovimientoDetalle detalle in row.detalles) {
        totals[detalle.idproducto] =
            (totals[detalle.idproducto] ?? 0) + detalle.cantidad;
      }
    }
    totals.removeWhere((String _, double value) => value <= 0);
    return totals;
  }

  Map<String, double>? _draftBufferForMovimiento({_CompraMovimientoRow? row}) {
    if (!_isDraftContext || _draftMovimientoTotals.isEmpty || row == null) {
      return null;
    }
    final Map<String, double> buffer =
        Map<String, double>.from(_draftMovimientoTotals);
    for (final CompraMovimientoDetalle detalle in row.detalles) {
      final String productoId = detalle.idproducto;
      final double updated =
          (buffer[productoId] ?? 0) - detalle.cantidad;
      if (updated <= 0.0001) {
        buffer.remove(productoId);
      } else {
        buffer[productoId] = updated;
      }
    }
    buffer.removeWhere((String _, double value) => value <= 0.0001);
    return buffer.isEmpty ? null : buffer;
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

  Widget _buildProveedorField() {
    if (_isLoadingProveedores) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<DropdownMenuItem<String>> items = _proveedores
        .map(
          (Proveedor proveedor) => DropdownMenuItem<String>(
            value: proveedor.id,
            child: Text(proveedor.nombre),
          ),
        )
        .toList(growable: true)
      ..add(
        DropdownMenuItem<String>(
          value: '__new__',
          child: Row(
            children: const <Widget>[
              Icon(Icons.add, size: 16),
              SizedBox(width: 6),
              Text('Agregar proveedor'),
            ],
          ),
        ),
      );

    final bool hasSelected = _selectedProveedorId != null &&
        _proveedores.any((Proveedor p) => p.id == _selectedProveedorId);

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Proveedor',
        border: OutlineInputBorder(),
      ),
      initialValue: hasSelected ? _selectedProveedorId : null,
      items: items,
      onChanged: (String? value) {
        if (value == '__new__') {
          _openNuevoProveedor();
          return;
        }
        setState(() {
          _selectedProveedorId = value;
        });
      },
      validator: (String? value) {
        if (value == null || value == '__new__') {
          return 'Selecciona un proveedor';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget formBody = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildProveedorField(),
          if (_isEditing && _registradoAt != null) ...<Widget>[
            const SizedBox(height: 12),
            Text('Registrado el: ${_registradoAt}'),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _observacionController,
            decoration: const InputDecoration(
              labelText: 'Observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ..._inlineSections
              .where(( _InlineSectionConfigBase section) =>
                  section.shouldDisplay(this))
              .map(( _InlineSectionConfigBase section) =>
                  section.buildSection(this)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.compra == null ? 'Nueva compra' : 'Editar compra'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: formBody,
              ),
            ),
          ),
          _FormFooter(
            isSaving: _isSaving,
            onCancel: _handleCancel,
            onSave: _onSave,
          ),
        ],
      ),
    );
  }
}

class _CompraMovimientoRow {
  const _CompraMovimientoRow({
    required this.movimiento,
    required this.detalles,
  });

  final CompraMovimiento movimiento;
  final List<CompraMovimientoDetalle> detalles;
}

abstract class _InlineSectionConfigBase {
  const _InlineSectionConfigBase();

  bool get loadOnInitWhenEditing;
  Future<void> loadData(_ComprasFormViewState state);
  bool shouldDisplay(_ComprasFormViewState state);
  Widget buildSection(_ComprasFormViewState state);
}

class _InlineSectionConfig<T> extends _InlineSectionConfigBase {
  const _InlineSectionConfig({
    required this.key,
    required this.title,
    required this.helperText,
    required this.emptyMessage,
    required this.minTableWidth,
    required this.itemsSelector,
    required this.isLoadingSelector,
    required this.columnsBuilder,
    this.onAdd,
    this.onEdit,
    this.loadDataCallback,
    this.visiblePredicate,
    this.loadOnInitWhenEditing = false,
  }) : super();

  final String key;
  final String title;
  final String helperText;
  final String emptyMessage;
  final double minTableWidth;
  final List<T> Function(_ComprasFormViewState state) itemsSelector;
  final bool Function(_ComprasFormViewState state) isLoadingSelector;
  final List<TableColumnConfig<T>> Function(_ComprasFormViewState state)
      columnsBuilder;
  final Future<void> Function(_ComprasFormViewState state)? onAdd;
  final Future<void> Function(_ComprasFormViewState state, T item)? onEdit;
  final Future<void> Function(_ComprasFormViewState state)? loadDataCallback;
  final bool Function(_ComprasFormViewState state)? visiblePredicate;
  @override
  final bool loadOnInitWhenEditing;

  @override
  Future<void> loadData(_ComprasFormViewState state) {
    if (loadDataCallback == null) {
      return Future<void>.value();
    }
    return loadDataCallback!(state);
  }

  @override
  bool shouldDisplay(_ComprasFormViewState state) =>
      visiblePredicate?.call(state) ?? true;

  @override
  Widget buildSection(_ComprasFormViewState state) {
    if (isLoadingSelector(state)) {
      return const Card(
        margin: EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final List<T> items = itemsSelector(state);
    return InlineFormTable<T>(
      title: title,
      helperText: helperText,
      items: items,
      columns: columnsBuilder(state),
      minTableWidth: minTableWidth,
      emptyMessage: emptyMessage,
      onAdd: onAdd == null ? null : () => onAdd!(state),
      onRowTap: onEdit == null ? null : (T item) => onEdit!(state, item),
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onSave,
              child: Text(isSaving ? 'Guardando...' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
