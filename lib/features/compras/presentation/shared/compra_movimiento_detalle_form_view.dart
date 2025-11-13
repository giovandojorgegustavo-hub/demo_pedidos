import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/compra_movimiento_detalle.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/services.dart';

class CompraMovimientoDetalleResult {
  const CompraMovimientoDetalleResult({
    required this.detalle,
    required this.reloadProductos,
  });

  final CompraMovimientoDetalle detalle;
  final bool reloadProductos;
}

class CompraMovimientoDetalleFormView extends StatefulWidget {
  const CompraMovimientoDetalleFormView({
    super.key,
    required this.productos,
    this.detalle,
    this.allowNewProduct = true,
    this.autoFillByProduct,
  });

  final List<Producto> productos;
  final CompraMovimientoDetalle? detalle;
  final bool allowNewProduct;
  final Map<String, double>? autoFillByProduct;

  @override
  State<CompraMovimientoDetalleFormView> createState() =>
      _CompraMovimientoDetalleFormViewState();
}

class _CompraMovimientoDetalleFormViewState
    extends State<CompraMovimientoDetalleFormView> {
  static const String _newProductValue = '__new__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<Producto> _productos = widget.productos;
  late String? _selectedProductoId = widget.detalle?.idproducto;
  late final TextEditingController _cantidadController =
      TextEditingController(
    text: widget.detalle?.cantidad.toString() ?? '',
  );
  bool _reloadProductos = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.detalle == null) {
      _applyAutoFill(_selectedProductoId, force: true);
    }
  }

  Future<void> _openNuevoProducto() async {
    if (!widget.allowNewProduct) {
      return;
    }
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ProductosFormView(),
      ),
    );
    if (newId == null) {
      return;
    }
    final List<Producto> productosActualizados = await Producto.getProductos();
    if (!mounted) {
      return;
    }
    setState(() {
      _productos = productosActualizados;
      _selectedProductoId = newId;
      _reloadProductos = true;
    });
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    if (_selectedProductoId == null ||
        _selectedProductoId == _newProductValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto.')),
      );
      return;
    }
    final double? cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida.')),
      );
      return;
    }
    final Producto? productoSeleccionado = _productos.firstWhereOrNull(
      (Producto producto) => producto.id == _selectedProductoId,
    );
    final CompraMovimientoDetalle detalle = CompraMovimientoDetalle(
      id: widget.detalle?.id,
      idmovimiento: widget.detalle?.idmovimiento ?? '',
      idproducto: _selectedProductoId!,
      cantidad: cantidad,
      productoNombre: productoSeleccionado?.nombre,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      CompraMovimientoDetalleResult(
        detalle: detalle,
        reloadProductos: _reloadProductos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = _productos
        .map(
          (Producto producto) => DropdownMenuItem<String>(
            value: producto.id,
            child: Text(producto.nombre),
          ),
        )
        .toList(growable: true);
    if (widget.allowNewProduct) {
      items.add(
        const DropdownMenuItem<String>(
          value: _newProductValue,
          child: Text('➕ Agregar nuevo producto'),
        ),
      );
    }

    final bool hasSelected = _selectedProductoId != null &&
        _productos.any((Producto producto) => producto.id == _selectedProductoId);

    return FormPageScaffold(
      title: widget.detalle == null
          ? 'Agregar producto a movimiento'
          : 'Editar producto del movimiento',
      onCancel: () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              initialValue: hasSelected ? _selectedProductoId : null,
              items: items,
              onChanged: (String? value) {
                if (value == _newProductValue) {
                  _openNuevoProducto();
                  return;
                }
                setState(() {
                  _selectedProductoId = value;
                });
                _applyAutoFill(value);
              },
              validator: (String? value) {
                if (value == null || value == _newProductValue) {
                  return 'Selecciona un producto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (String? value) {
                final double? parsed =
                    double.tryParse(value?.replaceAll(',', '.') ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Ingresa una cantidad válida';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyAutoFill(String? productoId, {bool force = false}) {
    if (productoId == null ||
        widget.autoFillByProduct == null ||
        (widget.detalle != null && !force)) {
      return;
    }
    final double? sugerida = widget.autoFillByProduct![productoId];
    if (sugerida == null) {
      return;
    }
    final double value = sugerida < 0 ? 0 : sugerida;
    if (value <= 0 && !force) {
      return;
    }
    final bool isInt = value == value.truncateToDouble();
    _cantidadController.text =
        isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }
}
