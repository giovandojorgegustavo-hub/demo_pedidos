import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/models/finanzas_ajuste.dart';

class FinanzasAjusteFormView extends StatefulWidget {
  const FinanzasAjusteFormView({
    super.key,
    this.ajuste,
    required this.cuentas,
    required this.cuentasContables,
  });

  final FinanzasAjuste? ajuste;
  final List<CuentaBancaria> cuentas;
  final List<CuentaContable> cuentasContables;

  @override
  State<FinanzasAjusteFormView> createState() => _FinanzasAjusteFormViewState();
}

class _FinanzasAjusteFormViewState extends State<FinanzasAjusteFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _observacionCtrl;
  String? _cuentaBancariaId;
  String? _cuentaContableId;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _descripcionCtrl = TextEditingController(
      text: widget.ajuste?.descripcion ?? '',
    );
    _montoCtrl = TextEditingController(
      text: widget.ajuste == null
          ? ''
          : widget.ajuste!.monto.toStringAsFixed(2),
    );
    _observacionCtrl = TextEditingController(
      text: widget.ajuste?.observacion ?? '',
    );
    _cuentaBancariaId = widget.ajuste?.idCuentaBancaria;
    _cuentaContableId = widget.ajuste?.idCuentaContable;
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
    final double monto =
        double.parse(_montoCtrl.text.replaceAll(',', '.'));
    setState(() => _isSaving = true);
    try {
      if (widget.ajuste == null) {
        await FinanzasAjuste.create(
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          cuentaContableId: _cuentaContableId!,
          cuentaBancariaId: _cuentaBancariaId,
          observacion: _observacionCtrl.text.trim().isEmpty
              ? null
              : _observacionCtrl.text.trim(),
        );
      } else {
        await FinanzasAjuste.update(
          id: widget.ajuste!.id,
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          cuentaContableId: _cuentaContableId!,
          cuentaBancariaId: _cuentaBancariaId,
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
    if (widget.ajuste == null || _isDeleting) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar ajuste'),
        content: const Text(
          'Esta acción eliminará el movimiento financiero. ¿Deseas continuar?',
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
      await FinanzasAjuste.delete(widget.ajuste!.id);
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
    final bool editing = widget.ajuste != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar ajuste' : 'Nuevo ajuste'),
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
                key: ValueKey<String>(
                    'contable-${_cuentaContableId ?? 'none'}'),
                initialValue: _cuentaContableId,
                decoration:
                    const InputDecoration(labelText: 'Cuenta contable'),
                items: widget.cuentasContables
                    .map(
                      (CuentaContable cuenta) => DropdownMenuItem<String>(
                        value: cuenta.id,
                        child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                      ),
                    )
                    .toList(growable: false),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona la cuenta contable';
                  }
                  return null;
                },
                onChanged: (String? value) {
                  setState(() {
                    _cuentaContableId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key:
                    ValueKey<String>('bancaria-${_cuentaBancariaId ?? 'none'}'),
                initialValue: _cuentaBancariaId,
                decoration:
                    const InputDecoration(labelText: 'Cuenta bancaria (opcional)'),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin cuenta'),
                  ),
                  ...widget.cuentas.map(
                    (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                      value: cuenta.id,
                      child: Text(cuenta.nombre),
                    ),
                  ),
                ],
                onChanged: (String? value) {
                  setState(() {
                    _cuentaBancariaId = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionCtrl,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Observación (opcional)'),
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
