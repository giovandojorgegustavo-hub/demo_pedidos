import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/models/finanzas_movimiento.dart';

class FinanzasMovimientoFormView extends StatefulWidget {
  const FinanzasMovimientoFormView({
    super.key,
    this.movimiento,
    this.cuentasContables = const <CuentaContable>[],
    this.cuentasBancarias = const <CuentaBancaria>[],
  });

  final FinanzasMovimiento? movimiento;
  final List<CuentaContable> cuentasContables;
  final List<CuentaBancaria> cuentasBancarias;

  @override
  State<FinanzasMovimientoFormView> createState() =>
      _FinanzasMovimientoFormViewState();
}

class _FinanzasMovimientoFormViewState
    extends State<FinanzasMovimientoFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _montoCtrl;
  late final TextEditingController _observacionCtrl;
  late String _tipo;
  String? _cuentaContableId;
  String? _cuentaBancariaId;
  bool _isSaving = false;
  bool _isDeleting = false;
  List<CuentaContable> _cuentasContables = <CuentaContable>[];
  List<CuentaBancaria> _cuentasBancarias = <CuentaBancaria>[];
  Future<void>? _catalogosFuture;

  @override
  void initState() {
    super.initState();
    _tipo = widget.movimiento?.tipo ?? 'gasto';
    _descripcionCtrl = TextEditingController(
      text: widget.movimiento?.descripcion ?? '',
    );
    _montoCtrl = TextEditingController(
      text: widget.movimiento == null
          ? ''
          : widget.movimiento!.monto.abs().toStringAsFixed(2),
    );
    _observacionCtrl = TextEditingController();
    _cuentaContableId = widget.movimiento?.idCuentaContable;
    _cuentaBancariaId = widget.movimiento?.idCuentaOrigen ??
        widget.movimiento?.idCuentaDestino;
    _cuentasContables = List<CuentaContable>.from(widget.cuentasContables);
    _cuentasBancarias = List<CuentaBancaria>.from(widget.cuentasBancarias);

    if (_cuentasContables.isEmpty || _cuentasBancarias.isEmpty) {
      _catalogosFuture = _loadCatalogos();
    }
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      CuentaContable.fetchTerminales(),
      CuentaBancaria.getCuentas(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentasContables = results[0] as List<CuentaContable>;
      _cuentasBancarias = results[1] as List<CuentaBancaria>;
    });
  }

  Future<void> _ensureCatalogosReady() async {
    if (_catalogosFuture != null) {
      await _catalogosFuture;
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _montoCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _ensureCatalogosReady();

    final double monto =
        double.tryParse(_montoCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() {
      _isSaving = true;
    });
    try {
      if (widget.movimiento == null) {
        await FinanzasMovimiento.create(
          tipo: _tipo,
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          idCuentaContable: _cuentaContableId!,
          idCuentaBancaria: _cuentaBancariaId,
          observacion: _observacionCtrl.text.trim().isEmpty
              ? null
              : _observacionCtrl.text.trim(),
        );
      } else {
        await FinanzasMovimiento.update(
          id: widget.movimiento!.id,
          tipo: _tipo,
          descripcion: _descripcionCtrl.text.trim(),
          monto: monto,
          idCuentaContable: _cuentaContableId!,
          idCuentaBancaria: _cuentaBancariaId,
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
        SnackBar(content: Text('Error al guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    if (widget.movimiento == null || _isDeleting) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content:
            const Text('¿Deseas eliminar este movimiento definitivamente?'),
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
    setState(() {
      _isDeleting = true;
    });
    try {
      await FinanzasMovimiento.delete(widget.movimiento!.id);
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
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  List<CuentaContable> get _contablesFiltradas {
    final List<CuentaContable> filtered = _cuentasContables
        .where((CuentaContable cuenta) =>
            cuenta.tipo == (_tipo == 'ingreso' ? 'ingreso' : 'gasto'))
        .toList()
      ..sort((CuentaContable a, CuentaContable b) =>
          a.codigo.compareTo(b.codigo));
    final CuentaContable? actual = _findCuentaContable(_cuentaContableId);
    if (actual != null &&
        filtered.every((CuentaContable c) => c.id != actual.id)) {
      filtered.add(actual);
      filtered.sort(
        (CuentaContable a, CuentaContable b) => a.codigo.compareTo(b.codigo),
      );
    }
    return filtered;
  }

  CuentaContable? _findCuentaContable(String? id) {
    if (id == null) {
      return null;
    }
    for (final CuentaContable cuenta in _cuentasContables) {
      if (cuenta.id == id) {
        return cuenta;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.movimiento != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar movimiento' : 'Nuevo movimiento'),
        actions: <Widget>[
          if (editing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _isDeleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: FutureBuilder<void>(
        future: _catalogosFuture,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if ((_cuentasContables.isEmpty || _cuentasBancarias.isEmpty) &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    key: ValueKey<String>('tipo-$_tipo'),
                    initialValue: _tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'gasto',
                        child: Text('Gasto'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'ingreso',
                        child: Text('Ingreso'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _tipo = value;
                        if (_cuentaContableId != null &&
                            _contablesFiltradas
                                .every((CuentaContable c) =>
                                    c.id != _cuentaContableId)) {
                          _cuentaContableId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Ej. Compra de insumos',
                    ),
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
                      final double? amount =
                          double.tryParse(value?.replaceAll(',', '.') ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Ingresa un monto válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: ValueKey<String>('cc-${_cuentaContableId ?? 'null'}-$_tipo'),
                    initialValue: _cuentaContableId,
                    decoration:
                        const InputDecoration(labelText: 'Cuenta contable'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Selecciona'),
                      ),
                      ..._contablesFiltradas.map(
                        (CuentaContable cuenta) => DropdownMenuItem<String?>(
                          value: cuenta.id,
                          child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                        ),
                      ),
                    ],
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecciona una cuenta contable';
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
                    key: ValueKey<String>('cb-${_cuentaBancariaId ?? 'null'}'),
                    initialValue: _cuentaBancariaId,
                    decoration:
                        const InputDecoration(labelText: 'Cuenta bancaria'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin cuenta'),
                      ),
                      ..._cuentasBancarias.map(
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
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(editing ? 'Guardar cambios' : 'Registrar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
