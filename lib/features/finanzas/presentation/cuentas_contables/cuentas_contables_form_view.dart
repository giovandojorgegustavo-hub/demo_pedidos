import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cuenta_contable.dart';

class CuentaContableFormView extends StatefulWidget {
  const CuentaContableFormView({
    super.key,
    this.cuenta,
    required this.cuentas,
    this.initialParentId,
    this.initialTipo,
    this.excludedParentIds = const <String>{},
    this.hasChildren = false,
  });

  final CuentaContable? cuenta;
  final List<CuentaContable> cuentas;
  final String? initialParentId;
  final String? initialTipo;
  final Set<String> excludedParentIds;
  final bool hasChildren;

  @override
  State<CuentaContableFormView> createState() => _CuentaContableFormViewState();
}

class _CuentaContableFormViewState extends State<CuentaContableFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _codigoCtrl;
  late final TextEditingController _nombreCtrl;
  String? _parentId;
  late String _tipo;
  bool _esTerminal = true;
  bool _isSaving = false;

  late final Map<String, CuentaContable> _cuentasMap;
  late final Map<String, int> _depthCache;

  @override
  void initState() {
    super.initState();
    _cuentasMap = <String, CuentaContable>{
      for (final CuentaContable cuenta in widget.cuentas) cuenta.id: cuenta,
    };
    _depthCache = <String, int>{};

    _codigoCtrl = TextEditingController(text: widget.cuenta?.codigo ?? '');
    _nombreCtrl = TextEditingController(text: widget.cuenta?.nombre ?? '');
    _parentId = widget.cuenta?.parentId ?? widget.initialParentId;
    _tipo =
        widget.cuenta?.tipo ?? widget.initialTipo ?? kCuentaContableTipos.first;
    _esTerminal = widget.cuenta?.esTerminal ?? true;
    if (widget.hasChildren) {
      _esTerminal = false;
    }
    if (_parentId != null) {
      final CuentaContable? parent = _cuentasMap[_parentId!];
      if (parent != null) {
        _tipo = parent.tipo;
      }
    }
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _nombreCtrl.dispose();
    super.dispose();
  }

  bool get _tipoEditable => _parentId == null;

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      if (widget.cuenta == null) {
        await CuentaContable.create(
          codigo: _codigoCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          parentId: _parentId,
          esTerminal: _esTerminal,
        );
      } else {
        await CuentaContable.update(
          id: widget.cuenta!.id,
          codigo: _codigoCtrl.text.trim(),
          nombre: _nombreCtrl.text.trim(),
          tipo: _tipo,
          parentId: _parentId,
          esTerminal: _esTerminal,
          previousParentId: widget.cuenta!.parentId,
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
        SnackBar(
          content: Text('No se pudo guardar la cuenta: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  List<DropdownMenuItem<String?>> _parentItems() {
    final List<CuentaContable> orden =
        List<CuentaContable>.from(widget.cuentas)..sort(_sortByCodigo);
    final List<DropdownMenuItem<String?>> items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Sin padre'),
      ),
    ];
    for (final CuentaContable cuenta in orden) {
      if (widget.cuenta != null && cuenta.id == widget.cuenta!.id) {
        continue;
      }
      if (widget.excludedParentIds.contains(cuenta.id)) {
        continue;
      }
      final String indent = '  ' * _depthFor(cuenta);
      items.add(
        DropdownMenuItem<String?>(
          value: cuenta.id,
          child: Text('$indent${cuenta.codigo} · ${cuenta.nombre}'),
        ),
      );
    }
    return items;
  }

  int _depthFor(CuentaContable cuenta) {
    if (_depthCache.containsKey(cuenta.id)) {
      return _depthCache[cuenta.id]!;
    }
    int depth = 0;
    String? currentParent = cuenta.parentId;
    while (currentParent != null) {
      final CuentaContable? parent = _cuentasMap[currentParent];
      if (parent == null) {
        break;
      }
      depth++;
      currentParent = parent.parentId;
    }
    _depthCache[cuenta.id] = depth;
    return depth;
  }

  int _sortByCodigo(CuentaContable a, CuentaContable b) {
    return a.codigo.compareTo(b.codigo);
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.cuenta != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar cuenta' : 'Nueva cuenta contable'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _codigoCtrl,
                      decoration: const InputDecoration(labelText: 'Código'),
                      textCapitalization: TextCapitalization.characters,
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un código';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey<String>('tipo-$_tipo-${_parentId ?? 'root'}'),
                      initialValue: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: kCuentaContableTipos
                          .map(
                            (String tipo) => DropdownMenuItem<String>(
                              value: tipo,
                              child: Text(_tipoLabel(tipo)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: _tipoEditable
                          ? (String? value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                _tipo = value;
                              });
                            }
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                key: ValueKey<String>('parent-${_parentId ?? 'root'}'),
                initialValue: _parentId,
                decoration: const InputDecoration(labelText: 'Cuenta padre'),
                items: _parentItems(),
                onChanged: (String? value) {
                  setState(() {
                    _parentId = value;
                    if (_parentId != null) {
                      final CuentaContable? parent = _cuentasMap[_parentId!];
                      if (parent != null) {
                        _tipo = parent.tipo;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                title: const Text('¿Es cuenta terminal?'),
                subtitle: widget.hasChildren
                    ? const Text(
                        'No se puede marcar como terminal porque tiene subcuentas.',
                      )
                    : const Text(
                        'Las cuentas terminales se usan para registrar movimientos.',
                      ),
                value: _esTerminal,
                onChanged: widget.hasChildren
                    ? null
                    : (bool value) {
                        setState(() {
                          _esTerminal = value;
                        });
                      },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Guardar cambios' : 'Crear cuenta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'activo':
        return 'Activo';
      case 'pasivo':
        return 'Pasivo';
      case 'patrimonio':
        return 'Patrimonio';
      case 'ingreso':
        return 'Ingreso';
      case 'gasto':
        return 'Gasto';
      default:
        return tipo;
    }
  }
}
