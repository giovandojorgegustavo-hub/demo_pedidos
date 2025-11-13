import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:demo_pedidos/models/transferencia_detalle.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class TransferenciaDetalleResult {
  const TransferenciaDetalleResult({required this.detalle});

  final TransferenciaDetalle detalle;
}

class TransferenciaProductoDisponible {
  const TransferenciaProductoDisponible({
    required this.id,
    required this.nombre,
    required this.disponible,
  });

  final String id;
  final String nombre;
  final double disponible;
}

class TransferenciaDetalleFormView extends StatefulWidget {
  const TransferenciaDetalleFormView({
    super.key,
    required this.productosDisponibles,
    this.detalle,
  });

  final List<TransferenciaProductoDisponible> productosDisponibles;
  final TransferenciaDetalle? detalle;

  @override
  State<TransferenciaDetalleFormView> createState() =>
      _TransferenciaDetalleFormViewState();
}

class _TransferenciaDetalleFormViewState
    extends State<TransferenciaDetalleFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _cantidadController = TextEditingController(
    text: widget.detalle?.cantidad.toString() ?? '',
  );

  late List<TransferenciaProductoDisponible> _productos =
      widget.productosDisponibles;
  String? _selectedProductoId;

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

  TransferenciaProductoDisponible? get _selectedProducto {
    for (final TransferenciaProductoDisponible option in _productos) {
      if (option.id == _selectedProductoId) {
        return option;
      }
    }
    return null;
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    final String? productoId = _selectedProductoId;
    final TransferenciaProductoDisponible? producto = _selectedProducto;
    if (productoId == null || producto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto válido.')),
      );
      return;
    }
    final double? cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    if (cantidad == null || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una cantidad válida')),
      );
      return;
    }
    if (cantidad > producto.disponible + 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Solo hay ${_formatCantidad(producto.disponible)} disponibles '
            'para ${producto.nombre}.',
          ),
        ),
      );
      return;
    }

    final TransferenciaDetalle detalle = TransferenciaDetalle(
      id: widget.detalle?.id,
      idtransferencia: widget.detalle?.idtransferencia ?? '',
      idproducto: productoId,
      cantidad: cantidad,
      productoNombre: producto.nombre,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      TransferenciaDetalleResult(detalle: detalle),
    );
  }

  String _formatCantidad(double value) => value.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> items = _productos
        .map(
          (TransferenciaProductoDisponible producto) =>
              DropdownMenuItem<String>(
            value: producto.id,
            child: Text(producto.nombre),
          ),
        )
        .toList(growable: false);

    final bool hasSelected = _selectedProductoId != null &&
        _productos.any((TransferenciaProductoDisponible p) =>
            p.id == _selectedProductoId);

    final double disponibleActual = _selectedProducto?.disponible ?? 0;

    return FormPageScaffold(
      title: widget.detalle == null ? 'Agregar producto' : 'Editar producto',
      onSave: _onSave,
      onCancel: () => Navigator.pop(context),
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
              items: items,
              initialValue: hasSelected ? _selectedProductoId : null,
              onChanged: (String? value) {
                setState(() {
                  _selectedProductoId = value;
                });
              },
              validator: (String? value) {
                if (value == null) {
                  return 'Selecciona un producto';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Disponible en base origen: ${_formatCantidad(disponibleActual)}',
              style: Theme.of(context).textTheme.bodySmall,
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
                final TransferenciaProductoDisponible? producto =
                    _selectedProducto;
                if (producto != null && parsed > producto.disponible + 0.0001) {
                  return 'Máximo disponible: ${_formatCantidad(producto.disponible)}';
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
