import 'package:flutter/material.dart';
import 'package:demo_pedidos/models/proveedor.dart';

class ProveedorFormResult {
  const ProveedorFormResult({required this.changed, this.proveedorId});

  final bool changed;
  final String? proveedorId;
}

class ProveedoresFormView extends StatefulWidget {
  const ProveedoresFormView({super.key, this.proveedor});

  final Proveedor? proveedor;

  @override
  State<ProveedoresFormView> createState() => _ProveedoresFormViewState();
}

class _ProveedoresFormViewState extends State<ProveedoresFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final Proveedor? proveedor = widget.proveedor;
    if (proveedor != null) {
      _nombreController.text = proveedor.nombre;
      _numeroController.text = proveedor.numero;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isSaving || _formKey.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final String nombre = _nombreController.text.trim();
    final String numero = _numeroController.text.trim();
    final bool numeroDuplicado = await Proveedor.numeroExists(
      numero,
      excludeId: widget.proveedor?.id,
    );
    if (numeroDuplicado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Este número ya está registrado para otro proveedor.'),
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    try {
      if (widget.proveedor == null) {
        final Proveedor nuevo = Proveedor(
          id: '',
          nombre: nombre,
          numero: numero,
        );
        final String newId = await Proveedor.insert(nuevo);
        if (!mounted) {
          return;
        }
        Navigator.pop(
          context,
          ProveedorFormResult(changed: true, proveedorId: newId),
        );
      } else {
        final Proveedor actualizado = widget.proveedor!
            .copyWith(nombre: nombre, numero: numero);
        await Proveedor.update(actualizado);
        if (!mounted) {
          return;
        }
        Navigator.pop(
          context,
          const ProveedorFormResult(changed: true),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.proveedor == null
            ? 'Nuevo proveedor'
            : 'Editar proveedor'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre del proveedor';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número de contacto',
                    border: OutlineInputBorder(),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el número de contacto';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
