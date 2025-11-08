import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NumRecibeFormView extends StatefulWidget {
  const NumRecibeFormView({super.key, required this.clienteId});

  final String clienteId;

  @override
  State<NumRecibeFormView> createState() => _NumRecibeFormViewState();
}

class _NumRecibeFormViewState extends State<NumRecibeFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSaving = false;

  @override
  void dispose() {
    _numeroController.dispose();
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
    final Map<String, dynamic> payload = <String, dynamic>{
      'idcliente': widget.clienteId,
      'numero': _numeroController.text.trim(),
      if (_nombreController.text.trim().isNotEmpty)
        'nombre_contacto': _nombreController.text.trim(),
    };
    try {
      final Map<String, dynamic> inserted = await _supabase
          .from('numrecibe')
          .insert(payload)
          .select('id')
          .single();
      if (!mounted) {
        return;
      }
      Navigator.pop(context, inserted['id'] as String);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el contacto: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nuevo número',
      onCancel: _isSaving ? null : () => Navigator.pop(context, null),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número de contacto',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el número';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
