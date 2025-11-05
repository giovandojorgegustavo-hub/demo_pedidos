import 'package:flutter/material.dart';

import '../models/detalle_movimiento.dart';
import '../models/logistica_base.dart';
import '../models/movimiento_pedido.dart';
import '../models/producto.dart';
import 'bases_form.dart';
import 'productos_form.dart';

class MovimientoFormView extends StatefulWidget {
  const MovimientoFormView({
    super.key,
    required this.pedidoId,
    this.movimiento,
    this.detalles,
  });

  final String pedidoId;
  final MovimientoPedido? movimiento;
  final List<DetalleMovimiento>? detalles;

  @override
  State<MovimientoFormView> createState() => _MovimientoFormViewState();
}

class _MovimientoFormViewState extends State<MovimientoFormView> {
  static const String _newBaseValue = '__new_base__';
  static const String _newProductValue = '__new_producto__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<Producto> _productos = <Producto>[];
  List<DetalleMovimiento> _detalles = <DetalleMovimiento>[];
  bool _isLoadingBases = true;
  bool _isLoadingProductos = true;
  bool _isSaving = false;
  String? _selectedBaseId;
  bool _esProvincia = false;
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  String? _movimientoId;

  bool get _isEditing => widget.movimiento != null;

  @override
  void initState() {
    super.initState();
    final MovimientoPedido? movimiento = widget.movimiento;
    if (movimiento != null) {
      _movimientoId = movimiento.id;
      _selectedBaseId = movimiento.idbase.isEmpty ? null : movimiento.idbase;
      _esProvincia = movimiento.esProvincia;
      _fecha = movimiento.fecharegistro;
      _hora =
          TimeOfDay(hour: movimiento.fecharegistro.hour, minute: movimiento.fecharegistro.minute);
    }
    final List<DetalleMovimiento>? detalles = widget.detalles;
    if (detalles != null && detalles.isNotEmpty) {
      _detalles = detalles
          .map(
            (DetalleMovimiento detalle) => DetalleMovimiento(
              id: detalle.id,
              idmovimiento: detalle.idmovimiento,
              idproducto: detalle.idproducto,
              cantidad: detalle.cantidad,
              productoNombre: detalle.productoNombre,
            ),
          )
          .toList();
    }
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await Future.wait<void>(<Future<void>>[
      _loadBases(
        selectId: _selectedBaseId,
        fallbackName: widget.movimiento?.baseNombre,
      ),
      _loadProductos(),
    ]);
  }

  Future<void> _loadBases({String? selectId, String? fallbackName}) async {
    setState(() {
      _isLoadingBases = true;
    });
    try {
      final List<LogisticaBase> bases = await LogisticaBase.getBases();
      if (!mounted) {
        return;
      }
      if (selectId != null &&
          selectId.isNotEmpty &&
          bases.every((LogisticaBase base) => base.id != selectId)) {
        bases.insert(
          0,
          LogisticaBase(
            id: selectId,
            nombre: fallbackName ?? 'Base asignada',
          ),
        );
      }
      setState(() {
        _bases = bases;
        _isLoadingBases = false;
        if (selectId != null && bases.any((LogisticaBase base) => base.id == selectId)) {
          _selectedBaseId = selectId;
        } else if (_selectedBaseId == null && bases.isNotEmpty) {
          _selectedBaseId = bases.first.id;
        } else if (bases.every((LogisticaBase base) => base.id != _selectedBaseId)) {
          _selectedBaseId = bases.isNotEmpty ? bases.first.id : null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingBases = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
      );
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _isLoadingProductos = true;
    });
    try {
      final List<Producto> productos = await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productos;
        _isLoadingProductos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingProductos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  Future<void> _openNuevaBase() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const BasesFormView(),
      ),
    );
    if (newId != null) {
      await _loadBases(selectId: newId);
    }
  }

  Future<String?> _openNuevoProducto() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ProductosFormView(),
      ),
    );
    if (newId != null) {
      await _loadProductos();
    }
    return newId;
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

  String _formatFecha() {
    final String day = _fecha.day.toString().padLeft(2, '0');
    final String month = _fecha.month.toString().padLeft(2, '0');
    return '$day/$month/${_fecha.year}';
  }

  Future<void> _openDetalleDialog({DetalleMovimiento? detalle, int? index}) async {
    String? selectedProductoId = detalle?.idproducto ??
        (_productos.isNotEmpty ? _productos.first.id : null);
    final TextEditingController cantidadController = TextEditingController(
      text: detalle?.cantidad.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext,
              void Function(void Function()) setStateDialog) {
            final List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[
              ..._productos.map(
                (Producto producto) => DropdownMenuItem<String>(
                  value: producto.id,
                  child: Text(producto.nombre),
                ),
              ),
              const DropdownMenuItem<String>(
                value: _newProductValue,
                child: Text('➕ Agregar nuevo producto'),
              ),
            ];

            return AlertDialog(
              title: Text(detalle == null ? 'Agregar producto' : 'Editar producto'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: selectedProductoId,
                    items: items,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String? value) async {
                      if (value == _newProductValue) {
                        final String? newId = await _openNuevoProducto();
                        if (newId != null) {
                          setStateDialog(() {
                            selectedProductoId = newId;
                          });
                        }
                        return;
                      }
                      setStateDialog(() {
                        selectedProductoId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedProductoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona un producto')),
                      );
                      return;
                    }
                    final double? cantidad =
                        double.tryParse(cantidadController.text.trim());
                    if (cantidad == null || cantidad <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cantidad inválida')),
                      );
                      return;
                    }
                    final DetalleMovimiento nuevo = DetalleMovimiento(
                      id: detalle?.id,
                      idproducto: selectedProductoId!,
                      cantidad: cantidad,
                    );
                    setState(() {
                      if (index != null) {
                        _detalles[index] = nuevo;
                      } else {
                        _detalles.add(nuevo);
                      }
                    });
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _productoNombre(String idProducto) {
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == idProducto,
      orElse: () =>
          Producto(id: idProducto, nombre: 'Producto desconocido', precio: 0),
    );
    return producto?.nombre ?? 'Producto desconocido';
  }

  void _removeDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final DateTime fechaMovimiento = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final MovimientoPedido payload = MovimientoPedido(
      id: _movimientoId ?? '',
      idpedido: widget.movimiento?.idpedido ?? widget.pedidoId,
      idbase: _selectedBaseId ?? '',
      esProvincia: _esProvincia,
      fecharegistro: fechaMovimiento,
    );

    try {
      final String movimientoId;
      if (_isEditing && _movimientoId != null) {
        await MovimientoPedido.update(payload);
        movimientoId = _movimientoId!;
      } else {
        movimientoId = await MovimientoPedido.insert(payload);
      }
      await DetalleMovimiento.replaceForMovimiento(movimientoId, _detalles);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el movimiento: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar movimiento' : 'Registrar movimiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              if (_isLoadingBases)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  value: _selectedBaseId,
                  decoration: const InputDecoration(
                    labelText: 'Base logística',
                    border: OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<String>>[
                    ..._bases.map(
                      (LogisticaBase base) => DropdownMenuItem<String>(
                        value: base.id,
                        child: Text(base.nombre),
                      ),
                    ),
                    const DropdownMenuItem<String>(
                      value: _newBaseValue,
                      child: Text('➕ Agregar nueva base'),
                    ),
                  ],
                  onChanged: (String? value) {
                    if (value == _newBaseValue) {
                      _openNuevaBase();
                      return;
                    }
                    setState(() {
                      _selectedBaseId = value;
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona una base';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _openNuevaBase,
                  child: const Text('Nueva base'),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('¿Provincia?'),
                value: _esProvincia,
                onChanged: (bool value) {
                  setState(() {
                    _esProvincia = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectFecha,
                      child: Text('Fecha: ${_formatFecha()}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectHora,
                      child: Text('Hora: ${_hora.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoadingProductos)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Detalle del movimiento',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openDetalleDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar producto'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_detalles.isEmpty)
                      const Text('Sin productos agregados.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _detalles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final DetalleMovimiento detalle = _detalles[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(_productoNombre(detalle.idproducto)),
                              subtitle: Text(
                                'Cantidad: ${detalle.cantidad.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: 'Editar',
                                    onPressed: () => _openDetalleDialog(
                                      detalle: detalle,
                                      index: index,
                                    ),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    tooltip: 'Eliminar',
                                    onPressed: () => _removeDetalle(index),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                child: Text(_isSaving ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
