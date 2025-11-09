import 'package:demo_pedidos/features/cargos_cliente/presentation/form/cargos_cliente_form_view.dart';
import 'package:demo_pedidos/features/cargos_cliente/presentation/list/cargos_cliente_list_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/detail/movimiento_detalle_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/form/movimiento_form_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/list/movimientos_list_view.dart';
import 'package:demo_pedidos/features/pagos/presentation/form/pagos_form_view.dart';
import 'package:demo_pedidos/features/pagos/presentation/list/pagos_list_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/form/pedidos_form_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/list/pedido_productos_list_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/shared/detalle_pedido_form_view.dart';
import 'package:demo_pedidos/models/cargo_cliente.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/detalle_pedido.dart';
import 'package:demo_pedidos/models/movimiento_pedido.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/pago.dart';
import 'package:demo_pedidos/models/pedido.dart';
import 'package:demo_pedidos/models/pedido_detalle_snapshot.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/table/detail_inline_section.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

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
  List<Pago> _pagos = <Pago>[];
  List<_MovimientoItem> _movimientos = <_MovimientoItem>[];
  List<CargoCliente> _cargos = <CargoCliente>[];

  bool _isDeleting = false;
  bool _hasChanges = false;
  String? _deletingPagoId;
  String? _deletingMovimientoId;
  List<Producto> _productos = <Producto>[];
  String? _deletingCargoId;
  String? _deletingDetalleId;

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
        .select('id,idproducto,cantidad,precioventa,productos!inner(nombre)')
        .eq('idpedido', widget.pedidoId)
        .order('registrado_at');

    final List<Pago> pagos = await Pago.getByPedido(widget.pedidoId);
    final List<CargoCliente> cargos =
        await CargoCliente.getByPedido(widget.pedidoId);
    final List<Producto> productos =
        await Producto.getProductos(); // Load products
    final List<MovimientoPedido> movimientosBase =
        await MovimientoPedido.getByPedido(widget.pedidoId);
    final List<MovimientoResumen> movimientosResumen =
        await MovimientoResumen.fetchByPedido(widget.pedidoId);
    final Map<String, MovimientoResumen> resumenPorId =
        <String, MovimientoResumen>{
      for (final MovimientoResumen resumen in movimientosResumen)
        resumen.id: resumen,
    };

    final List<_MovimientoItem> movimientos = <_MovimientoItem>[];
    for (final MovimientoPedido movimiento in movimientosBase) {
      final List<DetalleMovimiento> detalleMov =
          await DetalleMovimiento.getByMovimiento(movimiento.id);
      movimientos.add(
        _MovimientoItem(
          base: movimiento,
          resumen: resumenPorId[movimiento.id],
          detalles: detalleMov,
        ),
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
      _productos = productos; // Set products
      _detalles = detalleData.map((dynamic item) {
        final Map<String, dynamic> map = item as Map<String, dynamic>;
        final DetallePedido detalle = DetallePedido.fromJson(map);
        final Map<String, dynamic>? producto =
            map['productos'] as Map<String, dynamic>?;
        return _DetalleItem(
          detalle: detalle,
          productoNombre:
              producto?['nombre'] as String? ?? 'Producto desconocido',
        );
      }).toList(growable: false);
    });
  }

  Future<void> _refreshData({bool markChanged = false}) {
    final Future<void> future = _loadData();
    if (!mounted) {
      return future;
    }
    setState(() {
      _future = future;
      if (markChanged) {
        _hasChanges = true;
      }
    });
    return future;
  }

  String _formatDateTime(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $h:$min';
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
        SnackBar(content: Text('No se pudo eliminar el pedido: $error')),
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
      });
      _refreshData(markChanged: true);
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
      });
      _refreshData(markChanged: true);
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
      });
      _refreshData(markChanged: true);
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

  Future<void> _openPedidoForm(Pedido pedido) async {
    final bool? updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PedidosFormView(pedido: pedido),
      ),
    );
    if (updated == true && mounted) {
      _refreshData(markChanged: true);
    }
  }

  Future<void> _openPagoForm({Pago? pago}) async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PagosFormView(
          pedidoId: pedido.id,
          pago: pago,
        ),
      ),
    );
    if (result == true && mounted) {
      _refreshData(markChanged: true);
    }
  }

  Future<void> _openCargoForm({CargoCliente? cargo}) async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CargosClienteFormView(
          pedidoId: pedido.id,
          cargo: cargo,
        ),
      ),
    );
    if (result == true && mounted) {
      _refreshData(markChanged: true);
    }
  }

  Future<void> _openMovimientoForm({_MovimientoItem? item}) async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final List<PedidoDetalleSnapshot>? snapshots = _detalles.isEmpty
        ? null
        : _detalles
            .map(
              (_DetalleItem detalle) => PedidoDetalleSnapshot(
                idProducto: detalle.detalle.idproducto,
                cantidad: detalle.detalle.cantidad,
                nombre: detalle.productoNombre,
              ),
            )
            .toList();
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoFormView(
          pedidoId: pedido.id,
          clienteId: pedido.idcliente,
          movimiento: item?.base,
          detalles: item?.detalles,
          resumen: item?.resumen,
          pedidoSnapshots: snapshots,
        ),
      ),
    );
    if (result == true && mounted) {
      _refreshData(markChanged: true);
    }
  }

  Future<void> _openMovimientoDetalle(String movimientoId) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoDetalleView(
          movimientoId: movimientoId,
        ),
      ),
    );
    if (changed == true && mounted) {
      _refreshData(markChanged: true);
    }
  }

  Future<void> _openProductosTable() async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PedidoProductosListView(
          pedidoId: pedido.id,
          returnResult: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refreshData(markChanged: true);
    }
  }

  Future<void> _openPagosTable() async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PagosListView(
          pedidoId: pedido.id,
          returnResult: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refreshData(markChanged: true);
    }
  }

  Future<void> _openCargosTable() async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CargosClienteListView(
          pedidoId: pedido.id,
          returnResult: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refreshData(markChanged: true);
    }
  }

  Future<void> _openMovimientosTable() async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientosListView(
          pedidoId: pedido.id,
          includeDrawer: false,
          returnResult: true,
        ),
      ),
    );
    if (changed == true && mounted) {
      await _refreshData(markChanged: true);
    }
  }

  Future<void> _createDetalle() async {
    final Pedido? pedido = _pedido;
    if (pedido == null) {
      return;
    }
    final DetallePedidoFormResult? result =
        await Navigator.push<DetallePedidoFormResult>(
      context,
      MaterialPageRoute<DetallePedidoFormResult>(
        builder: (_) => DetallePedidoFormView(
          detalle: null,
          productos: _productos,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    final SupabaseClient client = Supabase.instance.client;
    final DetallePedido detalle = result.detalle;
    try {
      final Map<String, dynamic> payload = detalle.toJson()
        ..remove('id')
        ..['idpedido'] = pedido.id;
      await client.from('detallepedidos').insert(payload);
      if (result.reloadProductos) {
        final List<Producto> productos = await Producto.getProductos();
        if (mounted) {
          setState(() {
            _productos = productos;
          });
        }
      }
      if (mounted) {
        await _refreshData(markChanged: true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo agregar el producto: $error')),
      );
    }
  }

  Future<void> _openDetalleForm(DetallePedido detalle) async {
    if (_pedido == null || detalle.id == null) {
      return;
    }
    final DetallePedidoFormResult? result =
        await Navigator.push<DetallePedidoFormResult>(
      context,
      MaterialPageRoute<DetallePedidoFormResult>(
        builder: (_) => DetallePedidoFormView(
          detalle: detalle,
          productos: _productos,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    final SupabaseClient client = Supabase.instance.client;
    try {
      await client
          .from('detallepedidos')
          .update(result.detalle.toJson())
          .eq('id', detalle.id!);
      if (mounted) {
        await _refreshData(markChanged: true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el detalle: $error')),
      );
    }
  }

  Future<void> _deleteDetalle(DetallePedido detalle) async {
    final String? id = detalle.id;
    if (id == null) {
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: const Text(
            '¿Deseas eliminar este producto del pedido? Esta acción no se puede deshacer.',
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
    if (confirmed != true) {
      return;
    }

    setState(() {
      _deletingDetalleId = id;
    });
    try {
      final SupabaseClient client = Supabase.instance.client;
      await client.from('detallepedidos').delete().eq('id', id);
      if (mounted) {
        await _refreshData(markChanged: true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingDetalleId = null;
        });
      }
    }
  }

  List<TableColumnConfig<_DetalleItem>> _detalleColumns(Pedido pedido) {
    return <TableColumnConfig<_DetalleItem>>[
      TableColumnConfig<_DetalleItem>(
        label: 'Producto',
        sortAccessor: (_DetalleItem item) => item.productoNombre,
        cellBuilder: (_DetalleItem item) => Text(item.productoNombre),
      ),
      TableColumnConfig<_DetalleItem>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (_DetalleItem item) => item.detalle.cantidad,
        cellBuilder: (_DetalleItem item) =>
            Text(item.detalle.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<_DetalleItem>(
        label: 'Precio',
        isNumeric: true,
        sortAccessor: (_DetalleItem item) => item.detalle.precioventa,
        cellBuilder: (_DetalleItem item) =>
            Text('S/ ${item.detalle.precioventa.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<_DetalleItem>(
        label: 'Acciones',
        cellBuilder: (_DetalleItem item) => DetailRowActions(
          onEdit: () => _openDetalleForm(item.detalle),
          onDelete:
              item.detalle.id == null || _deletingDetalleId == item.detalle.id
                  ? null
                  : () => _deleteDetalle(item.detalle),
          isDeleting: _deletingDetalleId == item.detalle.id,
        ),
      ),
    ];
  }

  List<TableColumnConfig<Pago>> _pagoColumns() {
    return <TableColumnConfig<Pago>>[
      TableColumnConfig<Pago>(
        label: 'Fecha',
        sortAccessor: (Pago pago) => pago.fechapago,
        cellBuilder: (Pago pago) => Text(_formatDateTime(pago.fechapago)),
      ),
      TableColumnConfig<Pago>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (Pago pago) => pago.monto,
        cellBuilder: (Pago pago) => Text('S/ ${pago.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<Pago>(
        label: 'Cuenta',
        sortAccessor: (Pago pago) => pago.cuentaNombre ?? '',
        cellBuilder: (Pago pago) => Text(pago.cuentaNombre ?? '-'),
      ),
      TableColumnConfig<Pago>(
        label: 'Acciones',
        cellBuilder: (Pago pago) => DetailRowActions(
          onEdit: () => _openPagoForm(pago: pago),
          onDelete:
              _deletingPagoId == pago.id ? null : () => _deletePago(pago.id),
          isDeleting: _deletingPagoId == pago.id,
        ),
      ),
    ];
  }

  List<TableColumnConfig<CargoCliente>> _cargoColumns() {
    return <TableColumnConfig<CargoCliente>>[
      TableColumnConfig<CargoCliente>(
        label: 'Concepto',
        sortAccessor: (CargoCliente cargo) => cargo.concepto,
        cellBuilder: (CargoCliente cargo) => Text(cargo.concepto),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (CargoCliente cargo) => cargo.monto,
        cellBuilder: (CargoCliente cargo) =>
            Text('S/ ${cargo.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Registrado',
        sortAccessor: (CargoCliente cargo) => cargo.createdAt ?? DateTime(1970),
        cellBuilder: (CargoCliente cargo) => cargo.createdAt == null
            ? const Text('-')
            : Text(_formatDateTime(cargo.createdAt!)),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Acciones',
        cellBuilder: (CargoCliente cargo) => DetailRowActions(
          onEdit: () => _openCargoForm(cargo: cargo),
          onDelete: _deletingCargoId == cargo.id
              ? null
              : () => _deleteCargo(cargo.id),
          isDeleting: _deletingCargoId == cargo.id,
        ),
      ),
    ];
  }

  String _movimientoDestinoTexto(
    MovimientoResumen? resumen,
    bool esProvincia,
  ) {
    if (resumen == null) {
      return esProvincia ? '-' : 'Sin dirección';
    }
    if (esProvincia) {
      final List<String> parts = <String>[];
      final String destino = (resumen.provinciaDestino ?? '').trim();
      if (destino.isNotEmpty) {
        parts.add(destino);
      }
      final String destinatario = (resumen.provinciaDestinatario ?? '').trim();
      if (destinatario.isNotEmpty) {
        parts.add('Destinatario: $destinatario');
      }
      final String dni = (resumen.provinciaDni ?? '').trim();
      if (dni.isNotEmpty) {
        parts.add('DNI: $dni');
      }
      return parts.isEmpty ? '-' : parts.join('\n');
    }
    final String direccion = (resumen.direccion ?? '').trim();
    final String referencia = (resumen.direccionReferencia ?? '').trim();
    if (referencia.isEmpty) {
      return direccion.isEmpty ? 'Sin dirección' : direccion;
    }
    if (direccion.isEmpty) {
      return 'Ref: $referencia';
    }
    return '$direccion\nRef: $referencia';
  }

  List<TableColumnConfig<_MovimientoItem>> _movimientoColumns() {
    String contacto(MovimientoResumen? resumen) {
      if (resumen == null) {
        return '-';
      }
      final String? contacto = resumen.contactoNumero?.trim();
      if (contacto != null && contacto.isNotEmpty) {
        return contacto;
      }
      final String? clienteNumero = resumen.clienteNumero?.trim();
      if (clienteNumero != null && clienteNumero.isNotEmpty) {
        return clienteNumero;
      }
      return '-';
    }

    String baseNombre(
      MovimientoResumen? resumen,
      MovimientoPedido base,
    ) {
      final String? nombre = resumen?.baseNombre?.trim();
      if (nombre != null && nombre.isNotEmpty) {
        return nombre;
      }
      return base.baseNombre ?? '-';
    }

    return <TableColumnConfig<_MovimientoItem>>[
      TableColumnConfig<_MovimientoItem>(
        label: 'Fecha',
        sortAccessor: (_MovimientoItem item) =>
            item.resumen?.fecha ?? item.base.fecharegistro,
        cellBuilder: (_MovimientoItem item) => Text(
          _formatDateTime(item.resumen?.fecha ?? item.base.fecharegistro),
        ),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Contacto',
        sortAccessor: (_MovimientoItem item) => contacto(item.resumen),
        cellBuilder: (_MovimientoItem item) => Text(contacto(item.resumen)),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Dirección / Destino',
        sortAccessor: (_MovimientoItem item) =>
            _movimientoDestinoTexto(item.resumen, item.base.esProvincia),
        cellBuilder: (_MovimientoItem item) =>
            Text(_movimientoDestinoTexto(item.resumen, item.base.esProvincia)),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Provincia',
        sortAccessor: (_MovimientoItem item) => item.base.esProvincia ? 1 : 0,
        cellBuilder: (_MovimientoItem item) =>
            Text(item.base.esProvincia ? 'Sí' : 'No'),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Base',
        sortAccessor: (_MovimientoItem item) =>
            baseNombre(item.resumen, item.base),
        cellBuilder: (_MovimientoItem item) =>
            Text(baseNombre(item.resumen, item.base)),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Productos',
        isNumeric: true,
        sortAccessor: (_MovimientoItem item) => item.detalles.length,
        cellBuilder: (_MovimientoItem item) => Text('${item.detalles.length}'),
      ),
      TableColumnConfig<_MovimientoItem>(
        label: 'Acciones',
        cellBuilder: (_MovimientoItem item) => DetailRowActions(
          onEdit: () => _openMovimientoForm(item: item),
          onDelete: _deletingMovimientoId == item.base.id
              ? null
              : () => _deleteMovimiento(item.base.id),
          isDeleting: _deletingMovimientoId == item.base.id,
        ),
      ),
    ];
  }

  Widget _buildSummaryCard(Pedido pedido) {
    final ThemeData theme = Theme.of(context);
    final String observacion = (pedido.observacion ?? '').trim();
    final String numero = (pedido.clienteNumero ?? '').trim();
    final DateTime? registrado = pedido.registradoAt ?? pedido.fechapedido;
    final DateTime? editado = pedido.editadoAt;
    String resolveUser(String? display, String? id) {
      return (display ?? id ?? '').trim();
    }

    final String registradoPor =
        resolveUser(pedido.registradoPorNombre, pedido.registradoPor);
    final String editadoPor =
        resolveUser(pedido.editadoPorNombre, pedido.editadoPor);
    final List<_FieldRow> fields = <_FieldRow>[
      _FieldRow(
        label: 'Fecha de registro',
        value: registrado != null
            ? _formatDateTime(registrado)
            : 'Sin información',
      ),
      _FieldRow(
        label: 'Registrado por',
        value: registradoPor.isEmpty ? 'Sin información' : registradoPor,
      ),
      _FieldRow(
        label: 'Fecha de edición',
        value: editado != null ? _formatDateTime(editado) : 'Sin edición',
      ),
      _FieldRow(
        label: 'Editado por',
        value: editadoPor.isEmpty ? 'Sin información' : editadoPor,
      ),
      _FieldRow(
        label: 'Número de contacto',
        value: numero.isEmpty ? 'Sin número' : numero,
      ),
      if (observacion.isNotEmpty)
        _FieldRow(
          label: 'Observación',
          value: observacion,
          multiline: true,
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    pedido.clienteNombre ?? 'Cliente desconocido',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < fields.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 16),
              fields[i],
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> actions = <Widget>[
      IconButton(
        onPressed: () => _refreshData(),
        tooltip: 'Actualizar',
        icon: const Icon(Icons.refresh),
      ),
      if (_pedido != null)
        IconButton(
          onPressed: _isDeleting ? null : () => _confirmDelete(_pedido!),
          tooltip: _isDeleting ? 'Eliminando...' : 'Eliminar',
          icon: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
        ),
    ];

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, true);
      },
      child: PageScaffold(
        title: 'Detalle del pedido',
        currentSection: AppSection.pedidos,
        includeDrawer: false,
        actions: actions,
        floatingActionButton: _pedido == null
            ? null
            : FloatingActionButton(
                tooltip: 'Editar',
                onPressed: () => _openPedidoForm(_pedido!),
                child: const Icon(Icons.edit),
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
                        onPressed: () => _refreshData(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final Pedido? pedido = _pedido;
            if (pedido == null) {
              return const Center(child: Text('Pedido no encontrado.'));
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewportWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final double safeWidth = viewportWidth.isFinite
                    ? viewportWidth
                    : MediaQuery.of(context).size.width;
                final double minTableWidth = safeWidth < 560 ? 560 : safeWidth;
                final List<TableColumnConfig<_DetalleItem>> detalleColumns =
                    _detalleColumns(pedido);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildSummaryCard(pedido),
                      const SizedBox(height: 16),
                      DetailInlineSection<_DetalleItem>(
                        title: 'Detalle Ped',
                        items: _detalles,
                        columns: detalleColumns,
                        emptyMessage: 'Sin productos en este pedido.',
                        minTableWidth: minTableWidth,
                        onAdd: () => _createDetalle(),
                        onRowTap: (_DetalleItem item) =>
                            _openDetalleForm(item.detalle),
                        onView: _openProductosTable,
                      ),
                      const SizedBox(height: 16),
                      DetailInlineSection<Pago>(
                        title: 'Pagos',
                        items: _pagos,
                        columns: _pagoColumns(),
                        onAdd: () => _openPagoForm(),
                        onView: _openPagosTable,
                        emptyMessage: 'Sin pagos registrados.',
                        minTableWidth: minTableWidth,
                      ),
                      const SizedBox(height: 16),
                      DetailInlineSection<CargoCliente>(
                        title: 'Cargos',
                        items: _cargos,
                        columns: _cargoColumns(),
                        onAdd: () => _openCargoForm(),
                        onView: _openCargosTable,
                        emptyMessage: 'Sin cargos registrados.',
                        minTableWidth: minTableWidth,
                      ),
                      const SizedBox(height: 16),
                      DetailInlineSection<_MovimientoItem>(
                        title: 'Movimiento',
                        items: _movimientos,
                        columns: _movimientoColumns(),
                        onAdd: () => _openMovimientoForm(),
                        onView: _openMovimientosTable,
                        onRowTap: (_MovimientoItem item) =>
                            _openMovimientoDetalle(item.base.id),
                        emptyMessage: 'Sin movimientos registrados.',
                        minTableWidth: minTableWidth,
                        rowMaxHeightBuilder: (List<_MovimientoItem> items) {
                          final bool needsExtra = items.any(
                            (_MovimientoItem item) =>
                                item.base.esProvincia &&
                                _movimientoDestinoTexto(
                                      item.resumen,
                                      item.base.esProvincia,
                                    ).contains('\n'),
                          );
                          return needsExtra ? 108 : null;
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge,
          maxLines: multiline ? null : 1,
          overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
      ],
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
    required this.base,
    required this.resumen,
    required this.detalles,
  });

  final MovimientoPedido base;
  final MovimientoResumen? resumen;
  final List<DetalleMovimiento> detalles;
}
