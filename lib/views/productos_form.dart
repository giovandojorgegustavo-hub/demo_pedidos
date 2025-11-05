import 'package:flutter/material.dart';

import '../models/producto.dart';

class ProductosFormView extends StatefulWidget {
  const ProductosFormView({super.key});

  @override
  State<ProductosFormView> createState() => _ProductosFormViewState();
}

class _ProductosFormViewState extends State<ProductosFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    final double? precio = double.tryParse(_precioController.text.trim());
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un precio válido')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Producto producto = Producto(
      id: '',
      nombre: _nombreController.text.trim(),
      precio: precio,
    );

    try {
      final String id = await Producto.insert(producto);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el producto: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el precio';
                  }
                  return double.tryParse(value) == null
                      ? 'Precio inválido'
                      : null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
