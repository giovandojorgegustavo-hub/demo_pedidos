import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/compra_pago.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';

class CompraPagoFormView extends StatefulWidget {
  const CompraPagoFormView({
    super.key,
    required this.compraId,
    this.pago,
  });

  final String compraId;
  final CompraPago? pago;

  @override
  State<CompraPagoFormView> createState() => _CompraPagoFormViewState();
}

class _CompraPagoFormViewState extends State<CompraPagoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedCuentaId;

  bool get _isEditing => widget.pago != null;

  @override
  void initState() {
    super.initState();
    if (widget.pago != null) {
      _montoController.text = widget.pago!.monto.toStringAsFixed(2);
      _selectedCuentaId = widget.pago!.idcuenta;
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
        if (_isEditing &&
            widget.pago?.idcuenta != null &&
            cuentas.every((CuentaBancaria c) => c.id != widget.pago!.idcuenta)) {
          cuentas.insert(
            0,
            CuentaBancaria(
              id: widget.pago!.idcuenta!,
              nombre: widget.pago!.cuentaNombre ?? 'Cuenta asignada',
            ),
          );
        }
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
    _montoController.dispose();
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
    final CompraPago payload = CompraPago(
      id: widget.pago?.id ?? '',
      idcompra: widget.compraId,
      idcuenta: _selectedCuentaId,
      monto: monto,
    );
    try {
      if (_isEditing) {
        await CompraPago.update(payload);
      } else {
        await CompraPago.insert(payload);
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
        SnackBar(content: Text('No se pudo guardar el pago: $error')),
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
        title: Text(_isEditing ? 'Editar pago' : 'Registrar pago'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
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
