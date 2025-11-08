import 'package:demo_pedidos/models/cargo_cliente.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class CargosClienteFormView extends StatefulWidget {
  const CargosClienteFormView({
    super.key,
    required this.pedidoId,
    this.cargo,
  });

  final String pedidoId;
  final CargoCliente? cargo;

  @override
  State<CargosClienteFormView> createState() => _CargosClienteFormViewState();
}

class _CargosClienteFormViewState extends State<CargosClienteFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _conceptoController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.cargo != null;

  @override
  void initState() {
    super.initState();
    final CargoCliente? cargo = widget.cargo;
    if (cargo != null) {
      _conceptoController.text = cargo.concepto;
      _montoController.text = cargo.monto.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _conceptoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    final double? monto = double.tryParse(_montoController.text.trim());
    if (monto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final CargoCliente data = CargoCliente(
      id: widget.cargo?.id ?? '',
      idpedido: widget.cargo?.idpedido ?? widget.pedidoId,
      concepto: _conceptoController.text.trim(),
      monto: monto,
    );

    try {
      if (_isEditing) {
        await CargoCliente.update(data);
      } else {
        await CargoCliente.insert(data);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el cargo: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar cargo' : 'Registrar cargo',
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
              controller: _conceptoController,
              decoration: const InputDecoration(
                labelText: 'Concepto',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el concepto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto (S/)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el monto';
                }
                return double.tryParse(value) == null ? 'Monto inválido' : null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
