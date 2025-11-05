import 'package:flutter/material.dart';

import '../models/logistica_base.dart';

class BasesFormView extends StatefulWidget {
  const BasesFormView({super.key});

  @override
  State<BasesFormView> createState() => _BasesFormViewState();
}

class _BasesFormViewState extends State<BasesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final LogisticaBase base = LogisticaBase(
      id: '',
      nombre: _nombreController.text.trim(),
    );

    try {
      final String id = await LogisticaBase.insert(base);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la base: $error')),
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
        title: const Text('Nueva base'),
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
                  labelText: 'Nombre de la base',
                  border: OutlineInputBorder(),
                ),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre';
                  }
                  return null;
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
