import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:demo_pedidos/models/fabricacion_gasto.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';

class FabricacionGastoFormResult {
  const FabricacionGastoFormResult({required this.gasto});

  final FabricacionGasto gasto;
}

class FabricacionGastoFormView extends StatefulWidget {
  const FabricacionGastoFormView({
    super.key,
    required this.gasto,
  });

  final FabricacionGasto? gasto;

  @override
  State<FabricacionGastoFormView> createState() =>
      _FabricacionGastoFormViewState();
}

class _FabricacionGastoFormViewState extends State<FabricacionGastoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _observacionController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final FabricacionGasto? gasto = widget.gasto;
    if (gasto != null) {
      _conceptoController.text = gasto.concepto;
      _montoController.text = gasto.monto.toStringAsFixed(2);
      _observacionController.text = gasto.observacion ?? '';
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    setState(() => _isSaving = true);
    final FabricacionGasto result = FabricacionGasto(
      id: widget.gasto?.id,
      idfabricacion: widget.gasto?.idfabricacion ?? '',
      concepto: _conceptoController.text.trim(),
      monto:
          double.parse(_montoController.text.trim().replaceAll(',', '.')),
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(
      context,
      FabricacionGastoFormResult(gasto: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.gasto != null;
    return FormPageScaffold(
      title: isEditing ? 'Editar gasto' : 'Agregar gasto',
      onSave: _onSave,
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Describe el concepto del gasto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                border: OutlineInputBorder(),
                prefixText: 'S/ ',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: (String? value) {
                final double? parsed =
                    double.tryParse(value?.replaceAll(',', '.') ?? '');
                if (parsed == null || parsed < 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacionController,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
