import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cliente.dart';
import '../models/detalle_pedido.dart';
import '../models/pedido.dart';
import '../models/producto.dart';
import 'clientes_form.dart';
import 'productos_form.dart';

class PedidosFormView extends StatefulWidget {
  const PedidosFormView({super.key, this.pedido});

  final Pedido? pedido;

  @override
  State<PedidosFormView> createState() => _PedidosFormViewState();
}

class _PedidosFormViewState extends State<PedidosFormView> {
  static const String _newClientValue = '__new_cliente__';
  static const String _newProductValue = '__new_producto__';

  final SupabaseClient _supabase = Supabase.instance.client;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _observacionController = TextEditingController();

  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<DetallePedido> _detalles = <DetallePedido>[];
  String? _selectedClienteId;
  DateTime _fecha = DateTime.now();
  bool _isLoadingClientes = true;
  bool _isLoadingProductos = true;
  bool _isLoadingDetalles = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final Pedido? pedido = widget.pedido;
    _fecha = pedido?.fechapedido ?? DateTime.now();
    _observacionController.text = pedido?.observacion ?? '';
    _fechaController.text = _formatDate(_fecha);
    _selectedClienteId = pedido?.idcliente;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await _loadClientes(selectId: _selectedClienteId);
    await _loadProductos();
    if (widget.pedido != null) {
      await _loadDetalles();
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes({String? selectId}) async {
    setState(() {
      _isLoadingClientes = true;
    });
    try {
      final List<Cliente> clientes = await Cliente.getClientes();
      if (!mounted) {
        return;
      }
      setState(() {
        _clientes = clientes;
        _isLoadingClientes = false;
        String? selected = selectId ?? _selectedClienteId;
        if (selected != null &&
            !_clientes.any((Cliente cliente) => cliente.id == selected)) {
          selected = null;
        }
        _selectedClienteId =
            selected ?? (_clientes.isNotEmpty ? _clientes.first.id : null);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingClientes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los clientes: $error')),
      );
    }
  }

  Future<void> _loadProductos({String? selectId}) async {
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
      if (selectId != null) {
        setState(() {});
      }
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

  Future<void> _loadDetalles() async {
    setState(() {
      _isLoadingDetalles = true;
    });
    try {
      final List<dynamic> data = await _supabase
          .from('detallepedidos')
          .select('id,idproducto,cantidad,precioventa')
          .eq('idpedido', widget.pedido!.id)
          .order('created_at');
      if (!mounted) {
        return;
      }
      setState(() {
        _detalles = data
            .map(
              (dynamic item) =>
                  DetallePedido.fromJson(item as Map<String, dynamic>),
            )
            .toList();
        _isLoadingDetalles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDetalles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los detalles: $error')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _fecha = pickedDate;
        _fechaController.text = _formatDate(_fecha);
      });
    }
  }

  Future<void> _openNuevoCliente() async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const ClientesFormView(),
      ),
    );
    if (newId != null) {
      await _loadClientes(selectId: newId);
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
      await _loadProductos(selectId: newId);
    }
    return newId;
  }

  Future<void> _openDetalleDialog({DetallePedido? detalle, int? index}) async {
    String? selectedProductoId =
        detalle?.idproducto ?? (_productos.isNotEmpty ? _productos.first.id : null);
    final TextEditingController cantidadController = TextEditingController(
      text: detalle?.cantidad.toString() ?? '',
    );
    final TextEditingController precioController = TextEditingController(
      text: detalle?.precioventa.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder:
              (BuildContext dialogContext, void Function(void Function()) setStateDialog) {
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio unitario',
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
                    final double? precio =
                        double.tryParse(precioController.text.trim());
                    if (cantidad == null || precio == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cantidad o precio inválidos')),
                      );
                      return;
                    }
                    final DetallePedido nuevo = DetallePedido(
                      id: detalle?.id,
                      idproducto: selectedProductoId!,
                      cantidad: cantidad,
                      precioventa: precio,
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

  void _removeDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  double _detalleTotal(DetallePedido detalle) =>
      detalle.cantidad * detalle.precioventa;

  String _productoNombre(String idProducto) {
    final Producto? producto = _productos.firstWhere(
      (Producto item) => item.id == idProducto,
      orElse: () => Producto(id: idProducto, nombre: 'Producto desconocido', precio: 0),
    );
    return producto?.nombre ?? 'Producto desconocido';
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true ||
        _isSaving ||
        _selectedClienteId == null) {
      if (_selectedClienteId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un cliente')),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String? observacionInput =
        _observacionController.text.trim().isEmpty ? null : _observacionController.text.trim();

    final Pedido payload = Pedido(
      id: widget.pedido?.id ?? '',
      idcliente: _selectedClienteId!,
      fechapedido: _fecha,
      observacion: observacionInput,
      clienteNombre: widget.pedido?.clienteNombre,
    );

    try {
      String pedidoId;
      if (widget.pedido == null) {
        pedidoId = await Pedido.insert(payload);
      } else {
        pedidoId = widget.pedido!.id;
        await Pedido.update(payload.copyWith(id: pedidoId));
        await _supabase.from('detallepedidos').delete().eq('idpedido', pedidoId);
      }

      if (_detalles.isNotEmpty) {
        final List<Map<String, dynamic>> detalleMaps = _detalles
            .map((DetallePedido detalle) {
              final Map<String, dynamic> map = detalle.toJson();
              map.remove('id');
              map['idpedido'] = pedidoId;
              return map;
            })
            .toList();
        await _supabase.from('detallepedidos').insert(detalleMaps);
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
        SnackBar(content: Text('No se pudo guardar el pedido: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildClienteField() {
    if (_isLoadingClientes) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<DropdownMenuItem<String>> items = <DropdownMenuItem<String>>[
      ..._clientes.map(
        (Cliente cliente) => DropdownMenuItem<String>(
          value: cliente.id,
          child: Text(cliente.nombre),
        ),
      ),
      const DropdownMenuItem<String>(
        value: _newClientValue,
        child: Text('➕ Agregar nuevo cliente'),
      ),
    ];

    final bool hasSelected = _selectedClienteId != null &&
        _clientes.any((Cliente cliente) => cliente.id == _selectedClienteId);
    final String? dropdownValue = hasSelected ? _selectedClienteId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Cliente',
            border: OutlineInputBorder(),
          ),
          value: dropdownValue,
          items: items,
          hint: const Text('Selecciona un cliente'),
          onChanged: (String? value) {
            if (value == _newClientValue) {
              _openNuevoCliente();
              return;
            }
            setState(() {
              _selectedClienteId = value;
            });
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: _openNuevoCliente,
            child: const Text('Nuevo cliente'),
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesSection() {
    if (_isLoadingProductos || _isLoadingDetalles) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Detalle del pedido',
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
              final DetallePedido detalle = _detalles[index];
              final String nombreProducto = _productoNombre(detalle.idproducto);
              final double total = _detalleTotal(detalle);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(nombreProducto),
                  subtitle: Text(
                    'Cantidad: ${detalle.cantidad.toStringAsFixed(2)} · Precio: S/ ${detalle.precioventa.toStringAsFixed(2)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Total: S/ ${total.toStringAsFixed(2)}'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pedido == null ? 'Nuevo pedido' : 'Editar pedido'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildClienteField(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha del pedido',
                  border: OutlineInputBorder(),
                ),
                onTap: _selectDate,
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
              _buildDetallesSection(),
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
