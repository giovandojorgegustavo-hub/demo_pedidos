import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/ajuste_detalle.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class AjusteDetalleResult {
  const AjusteDetalleResult({
    required this.detalle,
    required this.reloadProductos,
  });

  final AjusteDetalle detalle;
  final bool reloadProductos;
}

class AjusteDetalleFormView extends StatefulWidget {
  const AjusteDetalleFormView({
    super.key,
    required this.productos,
    this.detalle,
  });

  final List<Producto> productos;
  final AjusteDetalle? detalle;

  @override
  State<AjusteDetalleFormView> createState() => _AjusteDetalleFormViewState();
}

class _AjusteDetalleFormViewState extends State<AjusteDetalleFormView> {
  static const String _newProductValue = '__new__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<Producto> _productos = widget.productos;
  String? _selectedProductoId;
  late final TextEditingController _cantidadController = TextEditingController(
    text: widget.detalle?.cantidad.toString() ?? '',
  );
  bool _reloadProductos = false;

  @override
  void initState() {
    super.initState();
    _selectedProductoId = widget.detalle?.idproducto ??
        (_productos.isNotEmpty ? _productos.first.id : null);
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  Future<void> _openNuevoProducto() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ProductosFormView(),
      ),
    );
    if (newId == null) {
      return;
    }
    final List<Producto> updated = await Producto.getProductos();
    if (!mounted) {
      return;
    }
    setState(() {
      _productos = updated;
      _selectedProductoId = newId;
      _reloadProductos = true;
    });
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final String? productoId = _selectedProductoId;
    if (productoId == null || productoId == _newProductValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto.')),
      );
      return;
    }
    final double? cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    if (cantidad == null || cantidad == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad distinta de 0.')),
      );
      return;
    }
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == productoId,
      orElse: () => Producto(id: productoId, nombre: 'Producto'),
    );
    final AjusteDetalle detalle = AjusteDetalle(
      id: widget.detalle?.id,
      idajuste: widget.detalle?.idajuste ?? '',
      idproducto: productoId,
      cantidad: cantidad,
      productoNombre: producto?.nombre,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      AjusteDetalleResult(
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
        .toList(growable: true)
      ..add(
        const DropdownMenuItem<String>(
          value: _newProductValue,
          child: Text('➕ Nuevo producto'),
        ),
      );

    final bool hasSelected = _selectedProductoId != null &&
        _productos.any((Producto p) => p.id == _selectedProductoId);

    return FormPageScaffold(
      title: widget.detalle == null ? 'Agregar producto' : 'Editar producto',
      onSave: () => _onSave(),
      onCancel: () => Navigator.pop(context),
      isSaving: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: hasSelected ? _selectedProductoId : null,
              decoration: const InputDecoration(
                labelText: 'Producto',
                border: OutlineInputBorder(),
              ),
              items: items,
              onChanged: (String? value) async {
                if (value == _newProductValue) {
                  await _openNuevoProducto();
                  return;
                }
                setState(() {
                  _selectedProductoId = value;
                });
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
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
              validator: (String? value) {
                final double? parsed =
                    double.tryParse(value?.replaceAll(',', '.') ?? '');
                if (parsed == null || parsed == 0) {
                  return 'Ingresa un valor distinto de 0';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
