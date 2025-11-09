import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/compra_detalle.dart';
import 'package:demo_pedidos/models/producto.dart';

class DetalleCompraFormResult {
  const DetalleCompraFormResult({
    required this.detalle,
    required this.reloadProductos,
  });

  final CompraDetalle detalle;
  final bool reloadProductos;
}

class DetalleCompraFormView extends StatefulWidget {
  const DetalleCompraFormView({
    super.key,
    required this.compraId,
    required this.productos,
    this.detalle,
  });

  final String compraId;
  final List<Producto> productos;
  final CompraDetalle? detalle;

  @override
  State<DetalleCompraFormView> createState() => _DetalleCompraFormViewState();
}

class _DetalleCompraFormViewState extends State<DetalleCompraFormView> {
  static const String _newProductValue = '__new__';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String? _selectedProductoId = widget.detalle?.idproducto;
  late final TextEditingController _cantidadController = TextEditingController(
      text: widget.detalle?.cantidad.toString() ?? '');
  late final TextEditingController _costoController = TextEditingController(
      text: widget.detalle?.costoTotal.toString() ?? '');
  bool _reloadProductos = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _costoController.dispose();
    super.dispose();
  }

  Future<void> _openProductoForm() async {
    await Future<void>.delayed(Duration.zero);
    final String? newProductId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ProductosFormView(),
      ),
    );
    if (newProductId != null) {
      setState(() {
        _reloadProductos = true;
        _selectedProductoId = newProductId;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final double cantidad =
        double.parse(_cantidadController.text.replaceAll(',', '.'));
    final double costo =
        double.parse(_costoController.text.replaceAll(',', '.'));
    final CompraDetalle detalle = CompraDetalle(
      id: widget.detalle?.id,
      idcompra: widget.compraId,
      idproducto: _selectedProductoId!,
      cantidad: cantidad,
      costoTotal: costo,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      DetalleCompraFormResult(
        detalle: detalle,
        reloadProductos: _reloadProductos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = widget.productos
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
          child: Text('➕ Agregar nuevo producto'),
        ),
      );

    final bool hasSelected = _selectedProductoId != null &&
        widget.productos.any((Producto p) => p.id == _selectedProductoId);
    final String? dropdownValue = hasSelected ? _selectedProductoId : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.detalle == null
            ? 'Agregar producto'
            : 'Editar producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  border: OutlineInputBorder(),
                ),
                initialValue: dropdownValue,
                items: items,
                onChanged: (String? value) async {
                  if (value == _newProductValue) {
                    await _openProductoForm();
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
                validator: (String? value) {
                  final double? parsed =
                      double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa una cantidad válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costoController,
                decoration: const InputDecoration(
                  labelText: 'Costo total',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (String? value) {
                  final double? parsed =
                      double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
