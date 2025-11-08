import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DireccionFormView extends StatefulWidget {
  const DireccionFormView({super.key, required this.clienteId});

  final String clienteId;

  @override
  State<DireccionFormView> createState() => _DireccionFormViewState();
}

class _DireccionFormViewState extends State<DireccionFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSaving = false;

  @override
  void dispose() {
    _direccionController.dispose();
    _referenciaController.dispose();
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
      'direccion': _direccionController.text.trim(),
      if (_referenciaController.text.trim().isNotEmpty)
        'referencia': _referenciaController.text.trim(),
    };
    try {
      final Map<String, dynamic> inserted = await _supabase
          .from('direccion')
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
        SnackBar(content: Text('No se pudo guardar la dirección: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nueva dirección',
      onCancel: _isSaving ? null : () => Navigator.pop(context, null),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _direccionController,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa la dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _referenciaController,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
