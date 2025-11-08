import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/pago.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class PagosFormView extends StatefulWidget {
  const PagosFormView({
    super.key,
    required this.pedidoId,
    this.pago,
  });

  final String pedidoId;
  final Pago? pago;

  @override
  State<PagosFormView> createState() => _PagosFormViewState();
}

class _PagosFormViewState extends State<PagosFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _montoController = TextEditingController();
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  bool _isSaving = false;
  bool _isLoadingCuentas = true;
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  String? _selectedCuentaId;
  bool get _isEditing => widget.pago != null;

  @override
  void initState() {
    super.initState();
    final Pago? pago = widget.pago;
    if (pago != null) {
      _montoController.text = pago.monto.toStringAsFixed(2);
      _fecha = pago.fechapago;
      _hora =
          TimeOfDay(hour: pago.fechapago.hour, minute: pago.fechapago.minute);
      _selectedCuentaId = pago.idcuenta;
    }
    _loadCuentas();
  }

  Future<void> _loadCuentas() async {
    setState(() {
      _isLoadingCuentas = true;
    });
    try {
      final List<CuentaBancaria> cuentas = await CuentaBancaria.getCuentas();
      if (!mounted) {
        return;
      }
      final Pago? pago = widget.pago;
      if (pago != null &&
          pago.idcuenta != null &&
          cuentas
              .every((CuentaBancaria cuenta) => cuenta.id != pago.idcuenta)) {
        cuentas.insert(
          0,
          CuentaBancaria(
            id: pago.idcuenta!,
            nombre: pago.cuentaNombre ?? 'Cuenta asignada',
          ),
        );
      }
      setState(() {
        _cuentas = cuentas;
        _isLoadingCuentas = false;
        if (_isEditing) {
          _selectedCuentaId = pago?.idcuenta;
        } else if (_cuentas.isNotEmpty) {
          _selectedCuentaId = _cuentas.first.id;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCuentas = false;
      });
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _selectFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  Future<void> _selectHora() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _hora);
    if (picked != null) {
      setState(() {
        _hora = picked;
      });
    }
  }

  String get _fechaLabel {
    final String day = _fecha.day.toString().padLeft(2, '0');
    final String month = _fecha.month.toString().padLeft(2, '0');
    return '$day/$month/${_fecha.year}';
  }

  String get _horaLabel {
    return _hora.format(context);
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

    final DateTime fechaPago = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final Pago payload = Pago(
      id: widget.pago?.id ?? '',
      idpedido: widget.pago?.idpedido ?? widget.pedidoId,
      monto: monto,
      fechapago: fechaPago,
      idcuenta: _selectedCuentaId,
    );

    try {
      if (_isEditing) {
        await Pago.update(payload);
      } else {
        await Pago.insert(payload);
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
        SnackBar(content: Text('No se pudo registrar el pago: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar pago' : 'Registrar pago',
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
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectFecha,
                    child: Text('Fecha: $_fechaLabel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _selectHora,
                    child: Text('Hora: $_horaLabel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingCuentas)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String?>(
                initialValue: _selectedCuentaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Cuenta (opcional)',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String?>>[
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Sin cuenta asignada'),
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
          ],
        ),
      ),
    );
  }
}
