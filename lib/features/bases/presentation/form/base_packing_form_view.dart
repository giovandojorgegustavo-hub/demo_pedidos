import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/bases/presentation/form/base_packing_draft.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class BasePackingFormView extends StatefulWidget {
  const BasePackingFormView({
    super.key,
    required this.existing,
    this.draft,
  });

  final List<BasePackingDraft> existing;
  final BasePackingDraft? draft;

  @override
  State<BasePackingFormView> createState() => _BasePackingFormViewState();
}

class _BasePackingFormViewState extends State<BasePackingFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController =
      TextEditingController(text: widget.draft?.nombre ?? '');
  bool _activo = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _activo = widget.draft?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    final BasePackingDraft result = BasePackingDraft(
      id: widget.draft?.id,
      nombre: _nombreController.text.trim(),
      activo: _activo,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: widget.draft == null ? 'Nuevo packing' : 'Editar packing',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del packing';
                }
                final String normalized = value.trim().toLowerCase();
                final bool exists = widget.existing.any(
                  (BasePackingDraft item) =>
                      item != widget.draft &&
                      item.nombre.trim().toLowerCase() == normalized,
                );
                if (exists) {
                  return 'Este packing ya existe';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activo'),
              value: _activo,
              onChanged: (bool value) {
                setState(() {
                  _activo = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
