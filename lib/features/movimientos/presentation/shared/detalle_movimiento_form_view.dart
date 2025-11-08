import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

const String _newProductValue = '__new_producto__';

class DetalleMovimientoFormResult {
  const DetalleMovimientoFormResult({
    required this.detalle,
    this.reloadProductos = false,
  });

  final DetalleMovimiento detalle;
  final bool reloadProductos;
}

class DetalleMovimientoFormView extends StatefulWidget {
  const DetalleMovimientoFormView({
    super.key,
    this.detalle,
    required this.productos,
    this.allowNewProduct = true,
    this.autoFillByProduct,
  });

  final DetalleMovimiento? detalle;
  final List<Producto> productos;
  final bool allowNewProduct;
  final Map<String, double>? autoFillByProduct;

  @override
  State<DetalleMovimientoFormView> createState() =>
      _DetalleMovimientoFormViewState();
}

class _DetalleMovimientoFormViewState extends State<DetalleMovimientoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _cantidadController;
  late List<Producto> _productos;
  String? _selectedProductoId;
  bool _isLoadingProductos = false;
  bool _reloadProductosOnPop = false;

  @override
  void initState() {
    super.initState();
    _productos = List<Producto>.from(widget.productos);
    _selectedProductoId = widget.detalle?.idproducto ??
        (_productos.isNotEmpty ? _productos.first.id : null);
    _cantidadController = TextEditingController(
      text: widget.detalle?.cantidad.toString() ?? '',
    );
    if (widget.detalle == null) {
      _applyAutoFill(_selectedProductoId, force: true);
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos({String? selectId}) async {
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
        if (selectId != null &&
            productos.any((Producto producto) => producto.id == selectId)) {
          _selectedProductoId = selectId;
        } else if (_selectedProductoId != null &&
            productos.any(
                (Producto producto) => producto.id == _selectedProductoId)) {
          // Keep current selection.
        } else {
          _selectedProductoId =
              productos.isNotEmpty ? productos.first.id : null;
        }
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

  Future<void> _handleNewProducto() async {
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
    setState(() {
      _reloadProductosOnPop = true;
    });
    await _loadProductos(selectId: newId);
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final String? productoId = _selectedProductoId;
    if (productoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }
    final double? cantidad = double.tryParse(_cantidadController.text.trim());
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == productoId,
      orElse: () => Producto(
        id: productoId,
        nombre: widget.detalle?.productoNombre ?? 'Producto',
        precio: 0,
      ),
    );
    final DetalleMovimiento detalle = DetalleMovimiento(
      id: widget.detalle?.id,
      idmovimiento: widget.detalle?.idmovimiento,
      idproducto: productoId,
      cantidad: cantidad,
      productoNombre: producto?.nombre ?? widget.detalle?.productoNombre,
    );
    Navigator.pop(
      context,
      DetalleMovimientoFormResult(
        detalle: detalle,
        reloadProductos: _reloadProductosOnPop,
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

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items =
        _productos.map((Producto producto) {
      return DropdownMenuItem<String>(
        value: producto.id,
        child: Text(producto.nombre),
      );
    }).toList();
    if (widget.allowNewProduct) {
      items.add(
        const DropdownMenuItem<String>(
          value: _newProductValue,
          child: Text('➕ Agregar nuevo producto'),
        ),
      );
    }

    return FormPageScaffold(
      title: widget.detalle == null ? 'Agregar producto' : 'Editar producto',
      onCancel: () => Navigator.pop(context),
      onSave: _handleSubmit,
      contentPadding: EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_isLoadingProductos)
              const LinearProgressIndicator(minHeight: 2),
            DropdownButtonFormField<String>(
              value: _selectedProductoId,
              items: items,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              onChanged: (String? value) async {
                if (value == _newProductValue) {
                  await _handleNewProducto();
                  return;
                }
                setState(() {
                  _selectedProductoId = value;
                });
                _applyAutoFill(value);
              },
              validator: (String? value) {
                if (value == null || value == _newProductValue) {
                  return 'Selecciona un producto válido';
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
              validator: (String? value) {
                final double? parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Ingresa una cantidad válida';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
