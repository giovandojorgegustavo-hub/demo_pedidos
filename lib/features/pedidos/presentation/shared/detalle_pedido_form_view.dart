import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/detalle_pedido.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

const String _newProductValue = '__new_producto__';

class DetallePedidoFormResult {
  const DetallePedidoFormResult({
    required this.detalle,
    this.reloadProductos = false,
  });

  final DetallePedido detalle;
  final bool reloadProductos;
}

class DetallePedidoFormView extends StatefulWidget {
  const DetallePedidoFormView({
    super.key,
    this.detalle,
    required this.productos,
  });

  final DetallePedido? detalle;
  final List<Producto> productos;

  @override
  State<DetallePedidoFormView> createState() => _DetallePedidoFormViewState();
}

class _DetallePedidoFormViewState extends State<DetallePedidoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _cantidadController;
  late TextEditingController _precioController;
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
    _precioController = TextEditingController(
      text: widget.detalle?.precioventa.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
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
    final double? precio = double.tryParse(_precioController.text.trim());
    if (cantidad == null || precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cantidad y precio deben ser valores numéricos')),
      );
      return;
    }
    final DetallePedido detalle = DetallePedido(
      id: widget.detalle?.id,
      idproducto: productoId,
      cantidad: cantidad,
      precioventa: precio,
    );
    Navigator.pop(
      context,
      DetallePedidoFormResult(
        detalle: detalle,
        reloadProductos: _reloadProductosOnPop,
      ),
    );
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
    items.add(
      const DropdownMenuItem<String>(
        value: _newProductValue,
        child: Text('➕ Agregar nuevo producto'),
      ),
    );

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
              initialValue: _selectedProductoId,
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
            TextFormField(
              controller: _precioController,
              decoration: const InputDecoration(
                labelText: 'Precio unitario',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (String? value) {
                final double? parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed < 0) {
                  return 'Ingresa un precio válido';
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
