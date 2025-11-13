import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/finanzas_transferencia.dart';

class FinanzasTransferenciaFormView extends StatefulWidget {
  const FinanzasTransferenciaFormView({
    super.key,
    this.transferencia,
    required this.cuentas,
  });

  final FinanzasTransferencia? transferencia;
  final List<CuentaBancaria> cuentas;

  @override
  State<FinanzasTransferenciaFormView> createState() =>
      _FinanzasTransferenciaFormViewState();
}

class _FinanzasTransferenciaFormViewState
    extends State<FinanzasTransferenciaFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _observacionCtrl;
  String? _cuentaOrigenId;
  String? _cuentaDestinoId;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl = TextEditingController(
      text: widget.transferencia?.descripcion ?? '',
    );
    _montoCtrl = TextEditingController(
      text: widget.transferencia == null
          ? ''
          : widget.transferencia!.monto.toStringAsFixed(2),
    );
    _observacionCtrl = TextEditingController(
      text: widget.transferencia?.observacion ?? '',
    );
    _cuentaOrigenId = widget.transferencia?.idCuentaOrigen;
    _cuentaDestinoId = widget.transferencia?.idCuentaDestino;
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final double monto =
        double.parse(_montoCtrl.text.replaceAll(',', '.'));
    try {
      if (widget.transferencia == null) {
        await FinanzasTransferencia.create(
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          cuentaOrigenId: _cuentaOrigenId!,
          cuentaDestinoId: _cuentaDestinoId!,
          observacion: _observacionCtrl.text.trim().isEmpty
              ? null
              : _observacionCtrl.text.trim(),
        );
      } else {
        await FinanzasTransferencia.update(
          id: widget.transferencia!.id,
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          cuentaOrigenId: _cuentaOrigenId!,
          cuentaDestinoId: _cuentaDestinoId!,
          observacion: _observacionCtrl.text.trim().isEmpty
              ? null
              : _observacionCtrl.text.trim(),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.transferencia == null || _isDeleting) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar transferencia'),
        content: const Text(
          'Esta acción eliminará el movimiento financiero. ¿Continuar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await FinanzasTransferencia.delete(widget.transferencia!.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.transferencia != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar transferencia' : 'Nueva transferencia'),
        actions: <Widget>[
          if (editing)
            IconButton(
              onPressed: _isDeleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _montoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  prefixText: 'S/ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (String? value) {
                  final double? parsed =
                      double.tryParse(value?.replaceAll(',', '.') ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Ingresa un monto válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('origen-${_cuentaOrigenId ?? 'none'}'),
                initialValue: _cuentaOrigenId,
                decoration:
                    const InputDecoration(labelText: 'Cuenta origen (egreso)'),
                items: widget.cuentas
                    .map(
                      (CuentaBancaria cuenta) => DropdownMenuItem<String>(
                        value: cuenta.id,
                        child: Text(cuenta.nombre),
                      ),
                    )
                    .toList(growable: false),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona la cuenta de origen';
                  }
                  if (value == _cuentaDestinoId) {
                    return 'No puede coincidir con la cuenta destino';
                  }
                  return null;
                },
                onChanged: (String? value) {
                  setState(() {
                    _cuentaOrigenId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('destino-${_cuentaDestinoId ?? 'none'}'),
                initialValue: _cuentaDestinoId,
                decoration:
                    const InputDecoration(labelText: 'Cuenta destino (ingreso)'),
                items: widget.cuentas
                    .map(
                      (CuentaBancaria cuenta) => DropdownMenuItem<String>(
                        value: cuenta.id,
                        child: Text(cuenta.nombre),
                      ),
                    )
                    .toList(growable: false),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona la cuenta destino';
                  }
                  if (value == _cuentaOrigenId) {
                    return 'No puede coincidir con la cuenta origen';
                  }
                  return null;
                },
                onChanged: (String? value) {
                  setState(() {
                    _cuentaDestinoId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionCtrl,
                decoration:
                    const InputDecoration(labelText: 'Observación (opcional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Guardar cambios' : 'Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
