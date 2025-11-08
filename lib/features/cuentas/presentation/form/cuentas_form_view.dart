import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class CuentasFormView extends StatefulWidget {
  const CuentasFormView({super.key});

  @override
  State<CuentasFormView> createState() => _CuentasFormViewState();
}

class _CuentasFormViewState extends State<CuentasFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _bancoController = TextEditingController();
  bool _activa = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _bancoController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });

    try {
      await CuentaBancaria.insert(
        nombre: _nombreController.text.trim(),
        banco: _bancoController.text.trim(),
        activa: _activa,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la cuenta: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nueva cuenta bancaria',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      contentPadding: EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre interno',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre de la cuenta';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bancoController,
              decoration: const InputDecoration(
                labelText: 'Banco / Plataforma',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el banco o plataforma';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Cuenta activa'),
              value: _activa,
              onChanged: (bool value) {
                setState(() {
                  _activa = value;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
