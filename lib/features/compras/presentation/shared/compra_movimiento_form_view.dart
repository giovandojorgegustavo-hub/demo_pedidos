import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/bases/presentation/form/bases_form_view.dart';
import 'package:demo_pedidos/features/compras/presentation/shared/compra_movimiento_detalle_form_view.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/compra_movimiento.dart';
import 'package:demo_pedidos/models/compra_movimiento_detalle.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

class CompraMovimientoFormResult {
  const CompraMovimientoFormResult({
    required this.changed,
    this.reloadProductos = false,
  });

  final bool changed;
  final bool reloadProductos;
}

class CompraMovimientoFormView extends StatefulWidget {
  const CompraMovimientoFormView({
    super.key,
    required this.compraId,
    required this.productos,
    this.movimiento,
    this.compraDetallesDraft,
    this.compraDraftMovimientoConsumos,
  });

  final String compraId;
  final List<Producto> productos;
  final CompraMovimiento? movimiento;
  final List<CompraDetalle>? compraDetallesDraft;
  final Map<String, double>? compraDraftMovimientoConsumos;

  @override
  State<CompraMovimientoFormView> createState() =>
      _CompraMovimientoFormViewState();
}

class _CompraMovimientoFormViewState extends State<CompraMovimientoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<CompraMovimientoDetalle> _detalles = <CompraMovimientoDetalle>[];
  Map<String, _ProductoCompraInfo> _productosCompra =
      <String, _ProductoCompraInfo>{};
  Map<String, double>? _draftConsumos;

  bool _isLoadingBases = true;
  bool _isLoadingDetalles = false;
  bool _isLoadingPendientes = false;
  bool _isCompletingMovimiento = false;
  bool _isSaving = false;
  bool _shouldReloadProductos = false;
  String? _selectedBaseId;

  @override
  void initState() {
    super.initState();
    _productos = widget.productos;
    _selectedBaseId = widget.movimiento?.idbase;
    _observacionController.text = widget.movimiento?.observacion ?? '';
    _draftConsumos = widget.compraDraftMovimientoConsumos;
    _loadBases(selectId: _selectedBaseId);
    _loadCompraProductos();
    if (widget.movimiento != null) {
      _loadDetalles();
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _loadBases({String? selectId}) async {
    setState(() => _isLoadingBases = true);
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
      setState(() => _isLoadingBases = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
      );
    }
  }

  Future<void> _loadDetalles() async {
    final CompraMovimiento? movimiento = widget.movimiento;
    if (movimiento == null) {
      return;
    }
    setState(() => _isLoadingDetalles = true);
    try {
      final List<CompraMovimientoDetalle> detalles =
          await CompraMovimientoDetalle.fetchByMovimiento(movimiento.id);
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
      setState(() => _isLoadingDetalles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el movimiento: $error')),
      );
    }
  }

  Future<void> _loadCompraProductos() async {
    setState(() => _isLoadingPendientes = true);
    try {
      final Map<String, _ProductoCompraInfo> productos =
          await _fetchCompraProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productosCompra = productos;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No se pudieron calcular los pendientes: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingPendientes = false);
      }
    }
  }

  Future<Map<String, _ProductoCompraInfo>> _fetchCompraProductos() async {
    final List<dynamic> comprados = await _supabase
        .from('compras_detalle')
        .select('idproducto,cantidad,productos(nombre)')
        .eq('idcompra', widget.compraId);
    final Map<String, double> cantidades = <String, double>{};
    final Map<String, String> nombres = <String, String>{};
    for (final dynamic item in comprados) {
      final Map<String, dynamic> row = item as Map<String, dynamic>;
      final String productoId = row['idproducto'] as String;
      cantidades[productoId] =
          (cantidades[productoId] ?? 0) + _parseCantidad(row['cantidad']);
      final Map<String, dynamic>? producto =
          row['productos'] as Map<String, dynamic>?;
      if (producto != null && producto['nombre'] != null) {
        nombres[productoId] = producto['nombre'] as String;
      }
    }

    Map<String, _ProductoCompraInfo> base;
    if (cantidades.isEmpty) {
      base = _buildSnapshotProductos();
    } else {
      base = <String, _ProductoCompraInfo>{
        for (final MapEntry<String, double> entry in cantidades.entries)
          entry.key: _ProductoCompraInfo(
            idProducto: entry.key,
            nombre: nombres[entry.key] ??
                _productos
                    .firstWhere(
                      (Producto p) => p.id == entry.key,
                      orElse: () => Producto(
                        id: entry.key,
                        nombre: 'Producto',
                      ),
                    )
                    .nombre,
            comprado: entry.value,
            recibido: 0,
          ),
      };
    }

    final List<dynamic> enviados = await _supabase
        .from('compras_movimiento_detalle')
        .select('idproducto,cantidad,compras_movimientos!inner(idcompra)')
        .eq('compras_movimientos.idcompra', widget.compraId);
    if (enviados.isNotEmpty) {
      for (final dynamic item in enviados) {
        final Map<String, dynamic> row = item as Map<String, dynamic>;
        final String productoId = row['idproducto'] as String;
        final double cantidad = _parseCantidad(row['cantidad']);
        final _ProductoCompraInfo? info = base[productoId];
        if (info != null) {
          base[productoId] = info.copyWith(
            recibido: info.recibido + cantidad,
          );
        } else {
          base[productoId] = _ProductoCompraInfo(
            idProducto: productoId,
            nombre: _productos
                .firstWhere(
                  (Producto p) => p.id == productoId,
                  orElse: () => Producto(
                    id: productoId,
                    nombre: 'Producto',
                  ),
                )
                .nombre,
            comprado: 0,
            recibido: cantidad,
          );
        }
      }
    }

    if (base.isEmpty) {
      return <String, _ProductoCompraInfo>{};
    }
    return _applyDraftConsumos(base);
  }

  Map<String, _ProductoCompraInfo> _buildSnapshotProductos() {
    final List<CompraDetalle>? snapshot = widget.compraDetallesDraft;
    if (snapshot == null || snapshot.isEmpty) {
      return <String, _ProductoCompraInfo>{};
    }
    final Map<String, double> cantidades = <String, double>{};
    final Map<String, String?> nombres = <String, String?>{};
    for (final CompraDetalle detalle in snapshot) {
      final String productoId = detalle.idproducto;
      cantidades[productoId] = (cantidades[productoId] ?? 0) + detalle.cantidad;
      nombres[productoId] = detalle.productoNombre ?? nombres[productoId];
    }
    final Map<String, _ProductoCompraInfo> result =
        <String, _ProductoCompraInfo>{};
    cantidades.forEach((String productoId, double cantidad) {
      if (cantidad <= 0) {
        return;
      }
      result[productoId] = _ProductoCompraInfo(
        idProducto: productoId,
        nombre: nombres[productoId] ??
            _productos
                .firstWhere(
                  (Producto producto) => producto.id == productoId,
                  orElse: () => Producto(id: productoId, nombre: 'Producto'),
                )
                .nombre,
        comprado: cantidad,
        recibido: 0,
      );
    });
    return result;
  }

  double _parseCantidad(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
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

  Future<void> _openDetalleForm({CompraMovimientoDetalle? detalle}) async {
    List<Producto> productosDisponibles = _productos;
    bool allowNewProduct = true;
    Map<String, double>? autoFill;

    if (_productosCompra.isNotEmpty) {
      final Map<String, double> restantes =
          _buildRestantesPorProducto(excluir: detalle);
      if (restantes.isEmpty && detalle == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La compra ya está completa.')),
        );
        return;
      }
      productosDisponibles = restantes.entries
          .map(
            (MapEntry<String, double> entry) => Producto(
              id: entry.key,
              nombre: _productosCompra[entry.key]?.nombre ?? 'Producto',
            ),
          )
          .toList()
        ..sort((Producto a, Producto b) => a.nombre.compareTo(b.nombre));
      allowNewProduct = false;
      autoFill = restantes;
    }

    final CompraMovimientoDetalleResult? result =
        await Navigator.push<CompraMovimientoDetalleResult>(
      context,
      MaterialPageRoute<CompraMovimientoDetalleResult>(
        builder: (_) => CompraMovimientoDetalleFormView(
          productos: productosDisponibles,
          detalle: detalle,
          allowNewProduct: allowNewProduct,
          autoFillByProduct: autoFill,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      final List<Producto> productosActualizados =
          await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productosActualizados;
      });
      _shouldReloadProductos = true;
    }
    setState(() {
      if (detalle == null) {
        _detalles = <CompraMovimientoDetalle>[..._detalles, result.detalle];
      } else {
        _detalles = _detalles.map((CompraMovimientoDetalle item) {
          if (item == detalle) {
            return result.detalle;
          }
          return item;
        }).toList();
      }
    });
  }

  Future<void> _removeDetalle(CompraMovimientoDetalle detalle) async {
    setState(() {
      _detalles = _detalles.where((CompraMovimientoDetalle item) {
        return item != detalle;
      }).toList();
    });
  }

  double _totalCantidad() {
    return _detalles.fold<double>(
      0,
      (double sum, CompraMovimientoDetalle detalle) => sum + detalle.cantidad,
    );
  }

  Map<String, double> _buildRestantesPorProducto(
      {CompraMovimientoDetalle? excluir}) {
    if (_productosCompra.isEmpty) {
      return <String, double>{};
    }
    final Map<String, double> restantes = <String, double>{
      for (final MapEntry<String, _ProductoCompraInfo> entry
          in _productosCompra.entries)
        entry.key: entry.value.faltante,
    };
    for (final CompraMovimientoDetalle detalle in _detalles) {
      if (excluir != null && detalle == excluir) {
        continue;
      }
      final String productoId = detalle.idproducto;
      if (!restantes.containsKey(productoId)) {
        continue;
      }
      final double nuevoValor = (restantes[productoId]! - detalle.cantidad)
          .clamp(0, double.infinity) as double;
      restantes[productoId] = nuevoValor;
    }
    final String? productoEditado = excluir?.idproducto;
    restantes.removeWhere((String key, double value) {
      if (value > 0.0001) {
        return false;
      }
      if (productoEditado != null && key == productoEditado) {
        return false;
      }
      return true;
    });
    return restantes;
  }

  Map<String, _ProductoCompraInfo> _applyDraftConsumos(
    Map<String, _ProductoCompraInfo> base,
  ) {
    final Map<String, double>? borradores = _draftConsumos;
    if (base.isEmpty || borradores == null || borradores.isEmpty) {
      return base;
    }
    final Map<String, _ProductoCompraInfo> ajustados =
        <String, _ProductoCompraInfo>{};
    base.forEach((String productoId, _ProductoCompraInfo info) {
      final double extra = borradores[productoId] ?? 0;
      if (extra <= 0.0001) {
        ajustados[productoId] = info;
        return;
      }
      ajustados[productoId] = info.copyWith(
        recibido: info.recibido + extra,
      );
    });
    return ajustados;
  }

  bool get _shouldShowCompletarMovimientoButton {
    if (_isLoadingPendientes || _productosCompra.isEmpty) {
      return false;
    }
    final Map<String, double> restantes = _buildRestantesPorProducto();
    return restantes.values.any((double value) => value > 0.0001);
  }

  Future<void> _completarMovimientoAutomaticamente() async {
    if (_isCompletingMovimiento || _productosCompra.isEmpty) {
      return;
    }
    setState(() => _isCompletingMovimiento = true);
    try {
      final List<CompraMovimientoDetalle> updated =
          List<CompraMovimientoDetalle>.from(_detalles);
      bool added = false;
      for (final MapEntry<String, _ProductoCompraInfo> entry
          in _productosCompra.entries) {
        final _ProductoCompraInfo info = entry.value;
        final double cantidadActual = updated
            .where(
                (CompraMovimientoDetalle d) => d.idproducto == info.idProducto)
            .fold<double>(
              0,
              (double sum, CompraMovimientoDetalle d) => sum + d.cantidad,
            );
        final double restante = info.faltante - cantidadActual;
        if (restante <= 0.0001) {
          continue;
        }
        final int existingIndex = updated.indexWhere(
          (CompraMovimientoDetalle d) => d.idproducto == info.idProducto,
        );
        if (existingIndex >= 0) {
          final CompraMovimientoDetalle existente = updated[existingIndex];
          updated[existingIndex] = CompraMovimientoDetalle(
            id: existente.id,
            idmovimiento: existente.idmovimiento,
            idproducto: existente.idproducto,
            cantidad: existente.cantidad + restante,
            productoNombre: existente.productoNombre ?? info.nombre,
          );
        } else {
          updated.add(
            CompraMovimientoDetalle(
              id: null,
              idmovimiento: '',
              idproducto: info.idProducto,
              cantidad: restante,
              productoNombre: info.nombre,
            ),
          );
        }
        added = true;
      }
      if (!added) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No quedan productos pendientes.')),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _detalles = updated;
      });
    } finally {
      if (mounted) {
        setState(() => _isCompletingMovimiento = false);
      }
    }
  }

  Widget _buildMovimientoActionsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: _isSaving ? null : () => _openDetalleForm(),
          icon: const Icon(Icons.add),
          label: const Text('Agregar'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _isCompletingMovimiento ||
                  _isLoadingPendientes ||
                  !_shouldShowCompletarMovimientoButton
              ? null
              : _completarMovimientoAutomaticamente,
          icon: _isCompletingMovimiento
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.playlist_add_check),
          label: Text(_completarButtonLabel),
        ),
      ],
    );
  }

  String get _completarButtonLabel {
    if (_isCompletingMovimiento) {
      return 'Completando...';
    }
    if (_isLoadingPendientes) {
      return 'Calculando...';
    }
    if (_productosCompra.isEmpty) {
      return 'Sin productos';
    }
    return _shouldShowCompletarMovimientoButton
        ? 'Completar faltantes'
        : 'Sin pendientes';
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_selectedBaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una base.')),
      );
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un producto al movimiento.'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    final CompraMovimiento payload = CompraMovimiento(
      id: widget.movimiento?.id ?? '',
      idcompra: widget.compraId,
      idbase: _selectedBaseId!,
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
      baseNombre: widget.movimiento?.baseNombre,
      registradoAt: widget.movimiento?.registradoAt,
      editadoAt: widget.movimiento?.editadoAt,
    );
    try {
      String movimientoId = widget.movimiento?.id ?? '';
      if (widget.movimiento == null) {
        movimientoId = await CompraMovimiento.insert(payload);
      } else {
        await CompraMovimiento.update(payload.copyWith(id: movimientoId));
      }
      await CompraMovimientoDetalle.replaceForMovimiento(
        movimientoId,
        _detalles.map((CompraMovimientoDetalle detalle) {
          return CompraMovimientoDetalle(
            id: detalle.id,
            idmovimiento: movimientoId,
            idproducto: detalle.idproducto,
            cantidad: detalle.cantidad,
            productoNombre: detalle.productoNombre,
          );
        }).toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(
        context,
        CompraMovimientoFormResult(
          changed: true,
          reloadProductos: _shouldReloadProductos,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el movimiento: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title:
          widget.movimiento == null ? 'Nuevo movimiento' : 'Editar movimiento',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_isLoadingBases)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Base logística',
                  border: OutlineInputBorder(),
                ),
                initialValue: _bases
                        .any((LogisticaBase base) => base.id == _selectedBaseId)
                    ? _selectedBaseId
                    : null,
                items: <DropdownMenuItem<String>>[
                  ..._bases.map(
                    (LogisticaBase base) => DropdownMenuItem<String>(
                      value: base.id,
                      child: Text(base.nombre),
                    ),
                  ),
                  const DropdownMenuItem<String>(
                    value: '__new_base__',
                    child: Text('➕ Crear nueva base'),
                  ),
                ],
                onChanged: (String? value) {
                  if (value == '__new_base__') {
                    _openNuevaBase();
                    return;
                  }
                  setState(() {
                    _selectedBaseId = value;
                  });
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una base';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacionController,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildMovimientoActionsBar(),
            const SizedBox(height: 12),
            if (_isLoadingDetalles)
              const Center(child: CircularProgressIndicator())
            else ...<Widget>[
              InlineFormTable<CompraMovimientoDetalle>(
                title: 'Detalle de movimiento',
                items: _detalles,
                columns: _detalleColumns(),
                emptyMessage: 'Sin productos registrados.',
                helperText:
                    'Los productos registrados en este movimiento ingresarán a la base seleccionada.',
                onAdd: null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total unidades: ${_totalCantidad().toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<TableColumnConfig<CompraMovimientoDetalle>> _detalleColumns() {
    return <TableColumnConfig<CompraMovimientoDetalle>>[
      TableColumnConfig<CompraMovimientoDetalle>(
        label: 'Producto',
        sortAccessor: (CompraMovimientoDetalle d) => d.productoNombre ?? '',
        cellBuilder: (CompraMovimientoDetalle d) =>
            Text(d.productoNombre ?? '-'),
      ),
      TableColumnConfig<CompraMovimientoDetalle>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (CompraMovimientoDetalle d) => d.cantidad,
        cellBuilder: (CompraMovimientoDetalle d) =>
            Text(d.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<CompraMovimientoDetalle>(
        label: 'Acciones',
        cellBuilder: (CompraMovimientoDetalle d) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openDetalleForm(detalle: d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeDetalle(d),
            ),
          ],
        ),
      ),
    ];
  }
}

class _ProductoCompraInfo {
  const _ProductoCompraInfo({
    required this.idProducto,
    required this.nombre,
    required this.comprado,
    required this.recibido,
  });

  final String idProducto;
  final String nombre;
  final double comprado;
  final double recibido;

  double get faltante {
    final double value = comprado - recibido;
    return value < 0 ? 0 : value;
  }

  _ProductoCompraInfo copyWith({
    String? idProducto,
    String? nombre,
    double? comprado,
    double? recibido,
  }) {
    return _ProductoCompraInfo(
      idProducto: idProducto ?? this.idProducto,
      nombre: nombre ?? this.nombre,
      comprado: comprado ?? this.comprado,
      recibido: recibido ?? this.recibido,
    );
  }
}
