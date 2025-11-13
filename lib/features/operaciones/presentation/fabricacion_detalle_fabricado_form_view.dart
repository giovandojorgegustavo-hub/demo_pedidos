import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:demo_pedidos/features/productos/presentation/form/productos_form_view.dart';
import 'package:demo_pedidos/models/fabricacion_detalle_fabricado.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class FabricacionDetalleFabricadoResult {
  const FabricacionDetalleFabricadoResult({
    required this.detalle,
    required this.reloadProductos,
  });

  final FabricacionDetalleFabricado detalle;
  final bool reloadProductos;
}

class FabricacionDetalleFabricadoFormView extends StatefulWidget {
  const FabricacionDetalleFabricadoFormView({
    super.key,
    required this.productos,
    this.detalle,
  });

  final List<Producto> productos;
  final FabricacionDetalleFabricado? detalle;

  @override
  State<FabricacionDetalleFabricadoFormView> createState() =>
      _FabricacionDetalleFabricadoFormViewState();
}

class _FabricacionDetalleFabricadoFormViewState
    extends State<FabricacionDetalleFabricadoFormView> {
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
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad mayor a 0.')),
      );
      return;
    }
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == productoId,
      orElse: () => Producto(id: productoId, nombre: 'Producto'),
    );
    final FabricacionDetalleFabricado detalle = FabricacionDetalleFabricado(
      id: widget.detalle?.id,
      idfabricacion: widget.detalle?.idfabricacion ?? '',
      idproducto: productoId,
      cantidad: cantidad,
      productoNombre: producto?.nombre,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      FabricacionDetalleFabricadoResult(
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
      title: widget.detalle == null
          ? 'Agregar producto fabricado'
          : 'Editar producto fabricado',
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
                labelText: 'Cantidad fabricada',
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
                  return 'Ingresa un valor mayor a 0';
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
