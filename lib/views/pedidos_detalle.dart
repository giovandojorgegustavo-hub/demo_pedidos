import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cargo_cliente.dart';
import '../models/detalle_movimiento.dart';
import '../models/detalle_pedido.dart';
import '../models/movimiento_pedido.dart';
import '../models/pago.dart';
import '../models/pedido.dart';
import 'cargos_cliente_form.dart';
import 'movimiento_form.dart';
import 'pagos_form.dart';
import 'pedidos_form.dart';

class PedidosDetalleView extends StatefulWidget {
  const PedidosDetalleView({super.key, required this.pedidoId});

  final String pedidoId;

  @override
  State<PedidosDetalleView> createState() => _PedidosDetalleViewState();
}

class _PedidosDetalleViewState extends State<PedidosDetalleView> {
  late Future<void> _future;
  Pedido? _pedido;
  List<_DetalleItem> _detalles = <_DetalleItem>[];
  bool _isDeleting = false;
  List<Pago> _pagos = <Pago>[];
  List<_MovimientoItem> _movimientos = <_MovimientoItem>[];
  List<CargoCliente> _cargos = <CargoCliente>[];
  String? _deletingPagoId;
  String? _deletingMovimientoId;
  String? _deletingCargoId;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() async {
    final Pedido? pedido = await Pedido.getById(widget.pedidoId);
    final SupabaseClient client = Supabase.instance.client;
    final List<dynamic> detalleData = await client
        .from('detallepedidos')
        .select(
            'id,idproducto,cantidad,precioventa,productos!inner(nombre)')
        .eq('idpedido', widget.pedidoId)
        .order('created_at');
    final List<Pago> pagos = await Pago.getByPedido(widget.pedidoId);
    final List<CargoCliente> cargos =
        await CargoCliente.getByPedido(widget.pedidoId);
    final List<MovimientoPedido> movimientosBase =
        await MovimientoPedido.getByPedido(widget.pedidoId);
    final List<_MovimientoItem> movimientos = <_MovimientoItem>[];
    for (final MovimientoPedido movimiento in movimientosBase) {
      final List<DetalleMovimiento> detalleMov =
          await DetalleMovimiento.getByMovimiento(movimiento.id);
      movimientos.add(
        _MovimientoItem(movimiento: movimiento, detalles: detalleMov),
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _pedido = pedido;
      _pagos = pagos;
      _movimientos = movimientos;
      _cargos = cargos;
      _detalles = detalleData
          .map((dynamic item) {
            final Map<String, dynamic> map = item as Map<String, dynamic>;
            final DetallePedido detalle = DetallePedido.fromJson(map);
            final Map<String, dynamic>? producto =
                map['productos'] as Map<String, dynamic>?;
            return _DetalleItem(
              detalle: detalle,
              productoNombre: producto?['nombre'] as String? ??
                  'Producto desconocido',
            );
          })
          .toList();
    });
  }

  String _formatDate(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = '${date.year}';
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _statusLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Sin datos';
    }
    if (value.length == 1) {
      return value.toUpperCase();
    }
    return value[0].toUpperCase() + value.substring(1);
  }

  Color _stateColor(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'terminado':
        return Colors.green.shade600;
      case 'parcial':
        return Colors.blueGrey;
      case 'pendiente':
      default:
        return Colors.orange.shade700;
    }
  }

  Widget _buildChip(String label, String? value) {
    final Color color = _stateColor(value);
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Text(
        '$label: ${_statusLabel(value)}',
        style: TextStyle(color: color),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _confirmDelete(Pedido pedido) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar pedido'),
          content: Text(
            '¿Deseas eliminar el pedido de ${pedido.clienteNombre ?? 'este cliente'}? Esta acción no se puede deshacer.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deletePedido();
    }
  }

  Future<void> _deletePedido() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      await Pedido.deleteById(widget.pedidoId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      setState(() {
        _isDeleting = false;
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el pedido: $error'),
        ),
      );
    }
  }

  Future<void> _deletePago(String pagoId) async {
    setState(() {
      _deletingPagoId = pagoId;
    });
    try {
      await Pago.deleteById(pagoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPagoId = null;
        _future = _loadData();
        _hasChanges = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingPagoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el pago: $error')),
      );
    }
  }

  Future<void> _deleteMovimiento(String movimientoId) async {
    setState(() {
      _deletingMovimientoId = movimientoId;
    });
    try {
      await MovimientoPedido.deleteById(movimientoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingMovimientoId = null;
        _future = _loadData();
        _hasChanges = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingMovimientoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el movimiento: $error')),
      );
    }
  }

  Future<void> _deleteCargo(String cargoId) async {
    setState(() {
      _deletingCargoId = cargoId;
    });
    try {
      await CargoCliente.deleteById(cargoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingCargoId = null;
        _future = _loadData();
        _hasChanges = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingCargoId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el cargo: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          Navigator.pop(context, true);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle del pedido'),
        ),
        body: FutureBuilder<void>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No se pudo cargar el pedido.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _future = _loadData();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final Pedido? pedido = _pedido;
          if (pedido == null) {
            return const Center(
              child: Text('Pedido no encontrado.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pedido.clienteNombre ?? 'Cliente desconocido',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('Fecha: ${_formatDate(pedido.fechapedido)}'),
                        Text(
                          'Observación: ${pedido.observacion?.isNotEmpty == true ? pedido.observacion : 'Sin observación'}',
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: -8,
                          children: <Widget>[
                            _buildChip('Pago', pedido.estadoPago),
                            _buildChip('Entrega', pedido.estadoEntrega),
                            _buildChip('General', pedido.estadoGeneral),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Detalle del pedido',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_detalles.isEmpty)
                  const Text('Sin productos en este pedido.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _detalles.length,
                    itemBuilder: (BuildContext context, int index) {
                      final _DetalleItem item = _detalles[index];
                      final double total =
                          item.detalle.cantidad * item.detalle.precioventa;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag_outlined),
                          title: Text(item.productoNombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Cantidad: ${item.detalle.cantidad.toStringAsFixed(2)}',
                              ),
                              Text(
                                'Precio: S/ ${item.detalle.precioventa.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          trailing:
                              Text('S/ ${total.toStringAsFixed(2)}'),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Cargos al cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final bool? created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => CargosClienteFormView(
                              pedidoId: pedido.id,
                            ),
                          ),
                        );
                        if (created == true && mounted) {
                          setState(() {
                            _future = _loadData();
                            _hasChanges = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar cargo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_cargos.isEmpty)
                  const Text('Sin cargos registrados.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _cargos.length,
                    itemBuilder: (BuildContext context, int index) {
                      final CargoCliente cargo = _cargos[index];
                      final bool isDeleting = _deletingCargoId == cargo.id;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(cargo.concepto),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Monto: S/ ${cargo.monto.toStringAsFixed(2)}'),
                              if (cargo.createdAt != null)
                                Text(
                                  'Registrado: ${_formatDateTime(cargo.createdAt!)}',
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: isDeleting
                                    ? null
                                    : () async {
                                        final bool? updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute<bool>(
                                            builder: (_) =>
                                                CargosClienteFormView(
                                              pedidoId: pedido.id,
                                              cargo: cargo,
                                            ),
                                          ),
                                        );
                                        if (updated == true && mounted) {
                                          setState(() {
                                            _future = _loadData();
                                            _hasChanges = true;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip:
                                    isDeleting ? 'Eliminando...' : 'Eliminar',
                                onPressed: isDeleting
                                    ? null
                                    : () => _deleteCargo(cargo.id),
                                icon: Icon(
                                  isDeleting
                                      ? Icons.hourglass_top
                                      : Icons.delete_outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Pagos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final bool? created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) =>
                                PagosFormView(pedidoId: pedido.id),
                          ),
                        );
                        if (created == true && mounted) {
                          setState(() {
                            _future = _loadData();
                            _hasChanges = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Registrar pago'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_pagos.isEmpty)
                  const Text('Sin pagos registrados.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pagos.length,
                    itemBuilder: (BuildContext context, int index) {
                      final Pago pago = _pagos[index];
                      final bool isDeleting = _deletingPagoId == pago.id;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text('S/ ${pago.monto.toStringAsFixed(2)}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text('Fecha: ${_formatDateTime(pago.fechapago)}'),
                              if (pago.cuentaNombre != null)
                                Text('Cuenta: ${pago.cuentaNombre}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: isDeleting
                                    ? null
                                    : () async {
                                        final bool? updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute<bool>(
                                            builder: (_) => PagosFormView(
                                              pedidoId: pedido.id,
                                              pago: pago,
                                            ),
                                          ),
                                        );
                                        if (updated == true && mounted) {
                                          setState(() {
                                            _future = _loadData();
                                            _hasChanges = true;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip:
                                    isDeleting ? 'Eliminando...' : 'Eliminar',
                                onPressed: isDeleting
                                    ? null
                                    : () => _deletePago(pago.id),
                                icon: Icon(
                                  isDeleting
                                      ? Icons.hourglass_top
                                      : Icons.delete_outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Movimientos logísticos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final bool? created = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute<bool>(
                            builder: (_) => MovimientoFormView(
                              pedidoId: pedido.id,
                            ),
                          ),
                        );
                        if (created == true && mounted) {
                          setState(() {
                            _future = _loadData();
                            _hasChanges = true;
                          });
                        }
                      },
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Registrar movimiento'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_movimientos.isEmpty)
                  const Text('Sin movimientos registrados.')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _movimientos.length,
                    itemBuilder: (BuildContext context, int index) {
                      final _MovimientoItem item = _movimientos[index];
                      final MovimientoPedido movimiento = item.movimiento;
                      final bool isDeleting =
                          _deletingMovimientoId == movimiento.id;
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_shipping_outlined),
                          title:
                              Text(movimiento.baseNombre ?? 'Base sin nombre'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                movimiento.esProvincia
                                    ? 'Destino: Provincia'
                                    : 'Destino: Lima',
                              ),
                              Text(
                                'Fecha: ${_formatDateTime(movimiento.fecharegistro)}',
                              ),
                              if (item.detalles.isEmpty)
                                const Text('Sin productos asociados.')
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: item.detalles
                                      .map(
                                        (DetalleMovimiento detalle) => Text(
                                          '- ${detalle.productoNombre ?? 'Producto'}: ${detalle.cantidad.toStringAsFixed(2)}',
                                        ),
                                      )
                                      .toList(),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: isDeleting
                                    ? null
                                    : () async {
                                        final bool? updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute<bool>(
                                            builder: (_) =>
                                                MovimientoFormView(
                                              pedidoId: pedido.id,
                                              movimiento: movimiento,
                                              detalles: item.detalles,
                                            ),
                                          ),
                                        );
                                        if (updated == true && mounted) {
                                          setState(() {
                                            _future = _loadData();
                                            _hasChanges = true;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip:
                                    isDeleting ? 'Eliminando...' : 'Eliminar',
                                onPressed: isDeleting
                                    ? null
                                    : () => _deleteMovimiento(movimiento.id),
                                icon: Icon(
                                  isDeleting
                                      ? Icons.hourglass_top
                                      : Icons.delete_outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final bool? updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder: (_) => PedidosFormView(pedido: pedido),
                            ),
                          );
                          if (updated == true && mounted) {
                            setState(() {
                              _future = _loadData();
                              _hasChanges = true;
                            });
                          }
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            _isDeleting ? null : () => _confirmDelete(pedido),
                        icon: const Icon(Icons.delete),
                        label: Text(
                          _isDeleting ? 'Eliminando...' : 'Eliminar',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        ),
      ),
    );
  }
}

class _DetalleItem {
  const _DetalleItem({
    required this.detalle,
    required this.productoNombre,
  });

  final DetallePedido detalle;
  final String productoNombre;
}

class _MovimientoItem {
  const _MovimientoItem({
    required this.movimiento,
    required this.detalles,
  });

  final MovimientoPedido movimiento;
  final List<DetalleMovimiento> detalles;
}
