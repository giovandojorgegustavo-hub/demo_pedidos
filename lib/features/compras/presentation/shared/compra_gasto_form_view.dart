import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/compra_gasto.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';

class CompraGastoFormView extends StatefulWidget {
  const CompraGastoFormView({
    super.key,
    required this.compraId,
    this.gasto,
  });

  final String compraId;
  final CompraGasto? gasto;

  @override
  State<CompraGastoFormView> createState() => _CompraGastoFormViewState();
}

class _CompraGastoFormViewState extends State<CompraGastoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cuentaController = TextEditingController();
  final TextEditingController _montoController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedCuentaId;

  bool get _isEditing => widget.gasto != null;

  @override
  void initState() {
    super.initState();
    if (widget.gasto != null) {
      _cuentaController.text = widget.gasto!.cuentaContable ?? '';
      _montoController.text = widget.gasto!.monto.toStringAsFixed(2);
      _observacionController.text = widget.gasto!.observacion ?? '';
      _selectedCuentaId = widget.gasto!.idcuenta;
    }
    _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<CuentaBancaria> cuentas = await CuentaBancaria.getCuentas();
      if (!mounted) {
        return;
      }
      setState(() {
        _cuentas = cuentas;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _cuentaController.dispose();
    _montoController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    final double? monto =
        double.tryParse(_montoController.text.trim().replaceAll(',', '.'));
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final CompraGasto payload = CompraGasto(
      id: widget.gasto?.id ?? '',
      idcompra: widget.compraId,
      cuentaContable:
          _cuentaController.text.trim().isEmpty ? null : _cuentaController.text,
      idcuenta: _selectedCuentaId,
      monto: monto,
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
    );
    try {
      if (_isEditing) {
        await CompraGasto.update(payload);
      } else {
        await CompraGasto.insert(payload);
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
        SnackBar(content: Text('No se pudo guardar el gasto: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar gasto' : 'Registrar gasto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _cuentaController,
                      decoration: const InputDecoration(
                        labelText: 'Cuenta contable',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Cuenta bancaria',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: _selectedCuentaId,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin cuenta'),
                        ),
                        ..._cuentas.map(
                          (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                            value: cuenta.id,
                            child: Text(cuenta.nombre),
                          ),
                        ),
                      ],
                      onChanged: (String? value) {
                        setState(() {
                          _selectedCuentaId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _montoController,
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (String? value) {
                        final double? parsed = double.tryParse(
                            value?.trim().replaceAll(',', '.') ?? '');
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un monto válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacionController,
                      decoration: const InputDecoration(
                        labelText: 'Observación',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _onSave,
                        child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
