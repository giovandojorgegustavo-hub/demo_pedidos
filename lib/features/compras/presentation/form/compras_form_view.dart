import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/bases/presentation/form/bases_form_view.dart';
import 'package:demo_pedidos/features/proveedores/presentation/form/proveedores_form_view.dart';
import 'package:demo_pedidos/models/compra.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/compra_gasto.dart';
import 'package:demo_pedidos/models/compra_pago.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/models/proveedor.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

import '../shared/compra_gasto_form_view.dart';
import '../shared/compra_pago_form_view.dart';
import '../shared/detalle_compra_form_view.dart';

class ComprasFormView extends StatefulWidget {
  const ComprasFormView({super.key, this.compra});

  final Compra? compra;

  @override
  State<ComprasFormView> createState() => _ComprasFormViewState();
}

class _ComprasFormViewState extends State<ComprasFormView> {
  static const String _newBaseValue = '__new_base__';

  final SupabaseClient _supabase = Supabase.instance.client;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  List<Proveedor> _proveedores = <Proveedor>[];
  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<CompraDetalle> _detalles = <CompraDetalle>[];
  List<CompraPago> _pagos = <CompraPago>[];
  List<CompraGasto> _gastos = <CompraGasto>[];

  bool _isLoadingProveedores = true;
  bool _isLoadingBases = true;
  bool _isLoadingProductos = true;
  bool _isLoadingDetalles = false;
  bool _isLoadingPagos = false;
  bool _isLoadingGastos = false;
  bool _isSaving = false;
  bool _isPersistingDraft = false;
  bool _draftCreatedInSession = false;

  String? _selectedProveedorId;
  String? _selectedBaseId;
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
  ];

  bool get _isEditing => widget.compra != null;

  @override
  void initState() {
    super.initState();
    final Compra? compra = widget.compra;
    if (compra != null) {
      _compraId = compra.id;
      _selectedProveedorId = compra.idproveedor;
      _selectedBaseId = compra.idbase;
      _registradoAt = compra.registradoAt;
      _observacionController.text = compra.observacion ?? '';
    }
    _loadInitialData();
  }

  Future<void> _syncCompraMovimiento(String compraId) async {
    final String? baseId = _selectedBaseId;
    if (baseId == null) {
      return;
    }
    await _supabase
        .from('compras_movimientos')
        .delete()
        .eq('idcompra', compraId);
    final Map<String, dynamic> movimiento = await _supabase
        .from('compras_movimientos')
        .insert(<String, dynamic>{
          'idcompra': compraId,
          'idbase': baseId,
        })
        .select('id')
        .single();
    if (_detalles.isEmpty) {
      return;
    }
    final String movimientoId = movimiento['id'] as String;
    final List<Map<String, dynamic>> movimientoDetalle =
        _detalles.map((CompraDetalle detalle) {
      return <String, dynamic>{
        'idmovimiento': movimientoId,
        'idproducto': detalle.idproducto,
        'cantidad': detalle.cantidad,
      };
    }).toList(growable: false);
    if (movimientoDetalle.isNotEmpty) {
      await _supabase
          .from('compras_movimiento_detalle')
          .insert(movimientoDetalle);
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>(<Future<void>>[
      _loadProveedores(selectId: _selectedProveedorId),
      _loadBases(selectId: _selectedBaseId),
      _loadProductos(),
    ]);
    if (_isEditing) {
      await Future.wait<void>(<Future<void>>[
        _loadDetalles(),
        _loadPagos(),
        _loadGastos(),
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

  Future<void> _loadBases({String? selectId}) async {
    setState(() {
      _isLoadingBases = true;
    });
    try {
      final List<LogisticaBase> bases = await LogisticaBase.getBases();
      if (!mounted) {
        return;
      }
      setState(() {
        _bases = bases;
        _isLoadingBases = false;
        if (selectId != null &&
            bases.any((LogisticaBase base) => base.id == selectId)) {
          _selectedBaseId = selectId;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBases = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
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

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _openNuevoProveedor() async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(builder: (_) => const ProveedoresFormView()),
    );
    if (changed == true) {
      await _loadProveedores();
    }
  }

  Future<void> _openNuevaBase() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const BasesFormView(),
      ),
    );
    if (newId != null) {
      await _loadBases(selectId: newId);
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
    if (_selectedBaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la base donde ingresará la compra.'),
        ),
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
      await _syncCompraMovimiento(compraId);

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

  Widget _buildBaseField() {
    if (_isLoadingBases) {
      return const Center(child: CircularProgressIndicator());
    }
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Selecciona una base'),
      ),
      ..._bases.map(
        (LogisticaBase base) => DropdownMenuItem<String?>(
          value: base.id,
          child: Text(base.nombre),
        ),
      ),
      DropdownMenuItem<String?>(
        value: _newBaseValue,
        child: Row(
          children: const <Widget>[
            Icon(Icons.add, size: 16),
            SizedBox(width: 6),
            Text('Crear base'),
          ],
        ),
      ),
    ];

    final bool hasSelected = _bases.any(
      (LogisticaBase base) => base.id == _selectedBaseId,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Movimiento de ingreso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Base logística',
                border: OutlineInputBorder(),
              ),
              value: hasSelected ? _selectedBaseId : null,
              items: items,
              onChanged: (String? value) {
                if (value == _newBaseValue) {
                  _openNuevaBase();
                  return;
                }
                setState(() {
                  _selectedBaseId = value;
                });
              },
              validator: (String? value) {
                if (value == null || value == _newBaseValue) {
                  return 'Selecciona la base donde ingresará la compra';
                }
                return null;
              },
            ),
            const SizedBox(height: 6),
            const Text(
              'Se creará un movimiento con los productos registrados para la base seleccionada.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
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
          const SizedBox(height: 12),
          _buildBaseField(),
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
