import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DireccionProvinciaFormView extends StatefulWidget {
  const DireccionProvinciaFormView({super.key, required this.clienteId});

  final String clienteId;

  @override
  State<DireccionProvinciaFormView> createState() =>
      _DireccionProvinciaFormViewState();
}

class _DireccionProvinciaFormViewState
    extends State<DireccionProvinciaFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _destinatarioController =
      TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSaving = false;

  @override
  void dispose() {
    _destinoController.dispose();
    _destinatarioController.dispose();
    _dniController.dispose();
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
      'lugar_llegada': _destinoController.text.trim(),
      if (_destinatarioController.text.trim().isNotEmpty)
        'nombre_completo': _destinatarioController.text.trim(),
      if (_dniController.text.trim().isNotEmpty) 'dni': _dniController.text.trim(),
    };
    try {
      final Map<String, dynamic> inserted = await _supabase
          .from('direccion_provincia')
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
        SnackBar(content: Text('No se pudo guardar el destino: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nuevo destino provincia',
      onCancel: _isSaving ? null : () => Navigator.pop(context, null),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _destinoController,
              decoration: const InputDecoration(
                labelText: 'Destino',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el destino';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _destinatarioController,
              decoration: const InputDecoration(
                labelText: 'Destinatario (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dniController,
              decoration: const InputDecoration(
                labelText: 'DNI (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
