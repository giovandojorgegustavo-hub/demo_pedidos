import 'package:demo_pedidos/features/cargos_cliente/presentation/form/cargos_cliente_form_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/form/clientes_form_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/form/movimiento_form_view.dart';
import 'package:demo_pedidos/features/pagos/presentation/form/pagos_form_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/shared/detalle_pedido_form_view.dart';
import 'package:demo_pedidos/models/cargo_cliente.dart';
import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/detalle_pedido.dart';
import 'package:demo_pedidos/models/movimiento_pedido.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/pago.dart';
import 'package:demo_pedidos/models/pedido.dart';
import 'package:demo_pedidos/models/pedido_detalle_snapshot.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PedidosFormView extends StatefulWidget {
  const PedidosFormView({super.key, this.pedido});

  final Pedido? pedido;

  @override
  State<PedidosFormView> createState() => _PedidosFormViewState();
}

class _PedidosFormViewState extends State<PedidosFormView> {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _newClientValue = '__new_cliente__';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _observacionController = TextEditingController();

  List<Cliente> _clientes = <Cliente>[];
  List<Producto> _productos = <Producto>[];
  List<DetallePedido> _detalles = <DetallePedido>[];
  List<Pago> _pagos = <Pago>[];
  List<CargoCliente> _cargos = <CargoCliente>[];
  List<_MovimientoRow> _movimientos = <_MovimientoRow>[];
  Map<String, double> _draftMovimientoTotals = <String, double>{};
  String? _pedidoId;
  DateTime? _registradoAt;
  String? _registradoPorId;
  bool _draftCreatedInSession = false;
  bool _isPersistingDraft = false;
  String? _selectedClienteId;
  bool _isLoadingClientes = true;
  bool _isLoadingProductos = true;
  bool _isLoadingDetalles = false;
  bool _isLoadingPagos = false;
  bool _isLoadingCargos = false;
  bool _isLoadingMovimientos = false;
  String? _deletingPagoId;
  String? _deletingCargoId;
  String? _deletingMovimientoId;
  bool _isSaving = false;

  bool get _isEditing => widget.pedido != null;
  bool get _isDraftContext => !_isEditing;
  bool get _hasPersistedPedido => _pedidoId != null;
  late final List<_InlineFormSectionConfigBase> _inlineSections =
      _buildInlineSections();

  @override
  void initState() {
    super.initState();
    final Pedido? pedido = widget.pedido;
    _observacionController.text = pedido?.observacion ?? '';
    _selectedClienteId = pedido?.idcliente;
    _pedidoId = pedido?.id;
    _registradoAt = pedido?.registradoAt ?? pedido?.fechapedido;
    _registradoPorId = pedido?.registradoPor;
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    await Future.wait<void>(<Future<void>>[
      _loadClientes(selectId: _selectedClienteId),
      _loadProductos(),
    ]);
    if (_isEditing) {
      final List<Future<void>> loads = _inlineSections
          .where(
            (_InlineFormSectionConfigBase section) =>
                section.loadOnInitWhenEditing,
          )
          .map(
            (_InlineFormSectionConfigBase section) => section.loadData(this),
          )
          .toList(growable: false);
      if (loads.isNotEmpty) {
        await Future.wait<void>(loads);
      }
    }
  }

  @override
  void dispose() {
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
        _selectedClienteId = selected;
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
    final String? pedidoId = _pedidoId;
    if (pedidoId == null) {
      setState(() {
        _isLoadingDetalles = false;
      });
      return;
    }
    try {
      final List<dynamic> data = await _supabase
          .from('detallepedidos')
          .select('id,idproducto,cantidad,precioventa')
          .eq('idpedido', pedidoId)
          .order('registrado_at');
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

  Future<void> _loadPagos() async {
    final String? pedidoId = _pedidoId;
    if (pedidoId == null) {
      return;
    }
    setState(() {
      _isLoadingPagos = true;
    });
    try {
      final List<Pago> pagos = await Pago.getByPedido(pedidoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _pagos = pagos;
        _isLoadingPagos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPagos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los pagos: $error')),
      );
    }
  }

  Future<void> _loadCargos() async {
    final String? pedidoId = _pedidoId;
    if (pedidoId == null) {
      return;
    }
    setState(() {
      _isLoadingCargos = true;
    });
    try {
      final List<CargoCliente> cargos =
          await CargoCliente.getByPedido(pedidoId);
      if (!mounted) {
        return;
      }
      setState(() {
        _cargos = cargos;
        _isLoadingCargos = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingCargos = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los cargos: $error')),
      );
    }
  }

  Future<void> _loadMovimientos() async {
    final String? pedidoId = _pedidoId;
    if (pedidoId == null) {
      return;
    }
    setState(() {
      _isLoadingMovimientos = true;
    });
    try {
      final List<MovimientoPedido> movimientosBase =
          await MovimientoPedido.getByPedido(pedidoId);
      final List<MovimientoResumen> movimientosResumen =
          await MovimientoResumen.fetchByPedido(pedidoId);
      final Map<String, MovimientoResumen> resumenPorId =
          <String, MovimientoResumen>{
        for (final MovimientoResumen resumen in movimientosResumen)
          resumen.id: resumen,
      };
      final List<List<DetalleMovimiento>> detallesList = movimientosBase.isEmpty
          ? <List<DetalleMovimiento>>[]
          : await Future.wait<List<DetalleMovimiento>>(
              movimientosBase.map(
                (MovimientoPedido movimiento) =>
                    DetalleMovimiento.getByMovimiento(movimiento.id),
              ),
            );
      final List<_MovimientoRow> movimientos = <_MovimientoRow>[
        for (int i = 0; i < movimientosBase.length; i++)
          _MovimientoRow(
            base: movimientosBase[i],
            resumen: resumenPorId[movimientosBase[i].id],
            detalles: detallesList.length > i
                ? detallesList[i]
                : <DetalleMovimiento>[],
          ),
      ];
      if (!mounted) {
        return;
      }
      setState(() {
        _movimientos = movimientos;
        _isLoadingMovimientos = false;
        _draftMovimientoTotals = _isDraftContext
            ? _buildDraftMovimientoTotals(movimientos)
            : <String, double>{};
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingMovimientos = false;
        _draftMovimientoTotals = _isDraftContext
            ? _buildDraftMovimientoTotals(_movimientos)
            : <String, double>{};
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No se pudieron cargar los movimientos: $error')),
      );
    }
  }

  List<_InlineFormSectionConfigBase> _buildInlineSections() {
    return <_InlineFormSectionConfigBase>[
      _InlineFormSectionConfig<_DetalleRow>(
        key: 'detalles',
        title: 'Detalle ped',
        helperText: 'Productos asociados al pedido.',
        emptyMessage: 'Sin productos agregados.',
        minTableWidth: 560,
        isLoadingSelector: (_PedidosFormViewState state) =>
            state._isLoadingProductos || state._isLoadingDetalles,
        itemsSelector: (_PedidosFormViewState state) => state._detalleRows,
        columnsBuilder: (_PedidosFormViewState state) =>
            state._detalleColumns(),
        onAdd: (_PedidosFormViewState state) => state._openDetalleForm(),
        onEdit: (_PedidosFormViewState state, _DetalleRow row) =>
            state._openDetalleForm(
          detalle: row.detalle,
          index: row.index,
        ),
        loadDataCallback: (_PedidosFormViewState state) =>
            state._loadDetalles(),
        visiblePredicate: (_PedidosFormViewState state) => true,
        loadOnInitWhenEditing: true,
      ),
      _InlineFormSectionConfig<Pago>(
        key: 'pagos',
        title: 'Pagos',
        helperText: 'Pagos asociados al pedido.',
        emptyMessage: 'Sin pagos registrados.',
        minTableWidth: 560,
        isLoadingSelector: (_PedidosFormViewState state) =>
            state._isLoadingPagos,
        itemsSelector: (_PedidosFormViewState state) => state._pagos,
        columnsBuilder: (_PedidosFormViewState state) => state._pagoColumns(),
        onAdd: (_PedidosFormViewState state) => state._openPagoForm(),
        onEdit: (_PedidosFormViewState state, Pago pago) =>
            state._openPagoForm(pago: pago),
        loadDataCallback: (_PedidosFormViewState state) => state._loadPagos(),
        visiblePredicate: (_PedidosFormViewState state) => true,
        loadOnInitWhenEditing: true,
      ),
      _InlineFormSectionConfig<CargoCliente>(
        key: 'cargos',
        title: 'Cargo',
        helperText: 'Ajustes aplicados al pedido.',
        emptyMessage: 'Sin cargos registrados.',
        minTableWidth: 560,
        isLoadingSelector: (_PedidosFormViewState state) =>
            state._isLoadingCargos,
        itemsSelector: (_PedidosFormViewState state) => state._cargos,
        columnsBuilder: (_PedidosFormViewState state) => state._cargoColumns(),
        onAdd: (_PedidosFormViewState state) => state._openCargoForm(),
        onEdit: (_PedidosFormViewState state, CargoCliente cargo) =>
            state._openCargoForm(cargo: cargo),
        loadDataCallback: (_PedidosFormViewState state) => state._loadCargos(),
        visiblePredicate: (_PedidosFormViewState state) => true,
        loadOnInitWhenEditing: true,
      ),
      _InlineFormSectionConfig<_MovimientoRow>(
        key: 'movimientos',
        title: 'Movimiento',
        helperText: 'Seguimiento de entregas y envíos.',
        emptyMessage: 'Sin movimientos registrados.',
        minTableWidth: 560,
        isLoadingSelector: (_PedidosFormViewState state) =>
            state._isLoadingMovimientos,
        itemsSelector: (_PedidosFormViewState state) => state._movimientos,
        columnsBuilder: (_PedidosFormViewState state) =>
            state._movimientoColumns(),
        onAdd: (_PedidosFormViewState state) => state._openMovimientoForm(),
        onEdit: (_PedidosFormViewState state, _MovimientoRow row) =>
            state._openMovimientoForm(row: row),
        loadDataCallback: (_PedidosFormViewState state) =>
            state._loadMovimientos(),
        visiblePredicate: (_PedidosFormViewState state) => true,
        loadOnInitWhenEditing: true,
        rowMaxHeightBuilder: (_PedidosFormViewState state,
            List<_MovimientoRow> items) {
          final bool needsExtraHeight = items.any(
            (_MovimientoRow row) =>
                row.base.esProvincia &&
                state
                    ._movimientoDestino(row.resumen, row.base.esProvincia)
                    .contains('\n'),
          );
          return needsExtraHeight ? 108 : null;
        },
      ),
    ];
  }

  String _formatDateTime(DateTime date) {
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/${date.year} $hour:$minute';
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

  Future<void> _openDetalleForm({DetallePedido? detalle, int? index}) async {
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
    if (result.reloadProductos) {
      await _loadProductos(selectId: result.detalle.idproducto);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      if (index != null) {
        _detalles[index] = result.detalle;
      } else {
        _detalles.add(result.detalle);
      }
    });
  }

  void _removeDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  double _detalleTotal(DetallePedido detalle) =>
      detalle.cantidad * detalle.precioventa;

  Widget _buildReadOnlyTimestamp() {
    final DateTime? created = _registradoAt ??
        widget.pedido?.registradoAt ??
        widget.pedido?.fechapedido;
    if (created == null) {
      return const SizedBox.shrink();
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Registrado el'),
      subtitle: Text(_formatDateTime(created)),
      dense: true,
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
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta registrar el detalle del pedido.'),
        ),
      );
      return;
    }
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para registrar.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final String? observacionInput = _observacionController.text.trim().isEmpty
        ? null
        : _observacionController.text.trim();

    final bool hasPersisted = _pedidoId != null;
    final DateTime now = DateTime.now();
    final DateTime creadoAt = _registradoAt ??
        widget.pedido?.registradoAt ??
        widget.pedido?.fechapedido ??
        now;
    final String? registradoPor =
        hasPersisted ? (_registradoPorId ?? userId) : userId;

    final Pedido payload = Pedido(
      id: _pedidoId ?? '',
      idcliente: _selectedClienteId!,
      fechapedido: creadoAt,
      observacion: observacionInput,
      clienteNombre: widget.pedido?.clienteNombre,
      clienteNumero: widget.pedido?.clienteNumero,
      registradoAt: creadoAt,
      registradoPor: registradoPor,
      editadoAt: hasPersisted ? now : null,
      editadoPor: hasPersisted ? userId : null,
    );

    try {
      String pedidoId = _pedidoId ?? '';
      if (!hasPersisted) {
        pedidoId = await Pedido.insert(payload);
      } else {
        await Pedido.update(payload.copyWith(id: pedidoId));
        await _supabase
            .from('detallepedidos')
            .delete()
            .eq('idpedido', pedidoId);
      }

      final List<Map<String, dynamic>> detalleMaps =
          _detalles.map((DetallePedido detalle) {
        final Map<String, dynamic> map = detalle.toJson();
        map.remove('id');
        map['idpedido'] = pedidoId;
        return map;
      }).toList();
      await _supabase.from('detallepedidos').insert(detalleMaps);

      setState(() {
        _pedidoId = pedidoId;
        _registradoAt = creadoAt;
        _registradoPorId = registradoPor;
        _draftCreatedInSession = false;
      });

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

    final List<DropdownMenuItem<String>> items = _clientes
        .map(
          (Cliente cliente) => DropdownMenuItem<String>(
            value: cliente.id,
            child: Text(cliente.nombre),
          ),
        )
        .toList(growable: true)
      ..add(
        DropdownMenuItem<String>(
          value: _newClientValue,
          child: Row(
            children: const <Widget>[
              Icon(Icons.add, size: 16),
              SizedBox(width: 6),
              Text('Agregar cliente nuevo'),
            ],
          ),
        ),
      );

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
          initialValue: dropdownValue,
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
      ],
    );
  }

  Widget _loadingCard() {
    return const Card(
      margin: EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<_DetalleRow> get _detalleRows => List<_DetalleRow>.generate(
        _detalles.length,
        (int index) => _DetalleRow(detalle: _detalles[index], index: index),
      );

  List<TableColumnConfig<_DetalleRow>> _detalleColumns() {
    return <TableColumnConfig<_DetalleRow>>[
      TableColumnConfig<_DetalleRow>(
        label: 'Producto',
        sortAccessor: (_DetalleRow row) =>
            _productoNombre(row.detalle.idproducto),
        cellBuilder: (_DetalleRow row) =>
            Text(_productoNombre(row.detalle.idproducto)),
      ),
      TableColumnConfig<_DetalleRow>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (_DetalleRow row) => row.detalle.cantidad,
        cellBuilder: (_DetalleRow row) =>
            Text(row.detalle.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<_DetalleRow>(
        label: 'Precio',
        isNumeric: true,
        sortAccessor: (_DetalleRow row) => row.detalle.precioventa,
        cellBuilder: (_DetalleRow row) =>
            Text('S/ ${row.detalle.precioventa.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<_DetalleRow>(
        label: 'Acciones',
        cellBuilder: (_DetalleRow row) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              tooltip: 'Editar',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () =>
                  _openDetalleForm(detalle: row.detalle, index: row.index),
            ),
            IconButton(
              tooltip: 'Eliminar',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _removeDetalle(row.index),
            ),
          ],
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
        cellBuilder: (Pago pago) {
          final bool isDeleting = _deletingPagoId == pago.id;
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: 'Editar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openPagoForm(pago: pago),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deletePago(pago.id),
                ),
            ],
          );
        },
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
        sortAccessor: (CargoCliente cargo) =>
            cargo.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (CargoCliente cargo) => cargo.createdAt == null
            ? const Text('-')
            : Text(_formatDateTime(cargo.createdAt!)),
      ),
      TableColumnConfig<CargoCliente>(
        label: 'Acciones',
        cellBuilder: (CargoCliente cargo) {
          final bool isDeleting = _deletingCargoId == cargo.id;
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: 'Editar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openCargoForm(cargo: cargo),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteCargo(cargo.id),
                ),
            ],
          );
        },
      ),
    ];
  }

  String _movimientoContacto(MovimientoResumen? resumen) {
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

  String _movimientoDestino(MovimientoResumen? resumen, bool esProvincia) {
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

  String _movimientoBaseNombre(
    MovimientoResumen? resumen,
    MovimientoPedido base,
  ) {
    final String? nombre = resumen?.baseNombre?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      return nombre;
    }
    return base.baseNombre ?? '-';
  }

  List<TableColumnConfig<_MovimientoRow>> _movimientoColumns() {
    return <TableColumnConfig<_MovimientoRow>>[
      TableColumnConfig<_MovimientoRow>(
        label: 'Fecha',
        sortAccessor: (_MovimientoRow row) =>
            row.resumen?.fecha ?? row.base.fecharegistro,
        cellBuilder: (_MovimientoRow row) => Text(
          _formatDateTime(row.resumen?.fecha ?? row.base.fecharegistro),
        ),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Base',
        sortAccessor: (_MovimientoRow row) =>
            _movimientoBaseNombre(row.resumen, row.base),
        cellBuilder: (_MovimientoRow row) =>
            Text(_movimientoBaseNombre(row.resumen, row.base)),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Provincia',
        sortAccessor: (_MovimientoRow row) => row.base.esProvincia ? 1 : 0,
        cellBuilder: (_MovimientoRow row) =>
            Text(row.base.esProvincia ? 'Sí' : 'No'),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Contacto',
        sortAccessor: (_MovimientoRow row) => _movimientoContacto(row.resumen),
        cellBuilder: (_MovimientoRow row) =>
            Text(_movimientoContacto(row.resumen)),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Dirección / Destino',
        sortAccessor: (_MovimientoRow row) => _movimientoDestino(
          row.resumen,
          row.base.esProvincia,
        ),
        cellBuilder: (_MovimientoRow row) => Text(
          _movimientoDestino(row.resumen, row.base.esProvincia),
        ),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Productos',
        isNumeric: true,
        sortAccessor: (_MovimientoRow row) => row.detalles.length,
        cellBuilder: (_MovimientoRow row) => Text('${row.detalles.length}'),
      ),
      TableColumnConfig<_MovimientoRow>(
        label: 'Acciones',
        cellBuilder: (_MovimientoRow row) {
          final bool isDeleting = _deletingMovimientoId == row.base.id;
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: 'Editar',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openMovimientoForm(row: row),
              ),
              if (isDeleting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteMovimiento(row.base.id),
                ),
            ],
          );
        },
      ),
    ];
  }

  Future<void> _openPagoForm({Pago? pago}) async {
    if (!await _ensurePedidoPersisted()) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PagosFormView(
          pedidoId: _pedidoId!,
          pago: pago,
        ),
      ),
    );
    if (result == true) {
      await _loadPagos();
    }
  }

  Future<void> _openCargoForm({CargoCliente? cargo}) async {
    if (!await _ensurePedidoPersisted()) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CargosClienteFormView(
          pedidoId: _pedidoId!,
          cargo: cargo,
        ),
      ),
    );
    if (result == true) {
      await _loadCargos();
    }
  }

  Future<void> _openMovimientoForm({_MovimientoRow? row}) async {
    final List<PedidoDetalleSnapshot> snapshots = _detalleRows
        .map(
          (_DetalleRow detalle) => PedidoDetalleSnapshot(
            idProducto: detalle.detalle.idproducto,
            cantidad: detalle.detalle.cantidad,
            nombre: _productoNombre(detalle.detalle.idproducto),
          ),
        )
        .toList(growable: false);
    final Map<String, double>? draftBuffer =
        _draftBufferForMovimiento(row: row);
    if (!await _ensurePedidoPersisted()) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoFormView(
          pedidoId: _pedidoId!,
          clienteId: _selectedClienteId,
          movimiento: row?.base,
          detalles: row?.detalles,
          resumen: row?.resumen,
          pedidoSnapshots: snapshots.isEmpty ? null : snapshots,
          pedidoDraftMovimientoConsumos: draftBuffer,
        ),
      ),
    );
    if (result == true) {
      await _loadMovimientos();
    }
  }

  Future<bool> _ensurePedidoPersisted() async {
    if (_pedidoId != null) {
      return true;
    }
    if (_selectedClienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona un cliente antes de continuar.')),
      );
      return false;
    }
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para continuar.')),
      );
      return false;
    }

    final String? observacionInput = _observacionController.text.trim().isEmpty
        ? null
        : _observacionController.text.trim();

    setState(() {
      _isPersistingDraft = true;
    });

    final DateTime now = DateTime.now();
    final Pedido draft = Pedido(
      id: '',
      idcliente: _selectedClienteId!,
      fechapedido: now,
      observacion: observacionInput,
      clienteNombre: null,
      clienteNumero: null,
      registradoAt: now,
      registradoPor: userId,
      editadoAt: null,
      editadoPor: null,
    );

    try {
      final String newId = await Pedido.insert(draft);
      if (!mounted) {
        return false;
      }
      setState(() {
        _pedidoId = newId;
        _registradoAt = draft.registradoAt;
        _registradoPorId = userId;
        if (widget.pedido == null) {
          _draftCreatedInSession = true;
        }
      });
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear el pedido: $error')),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isPersistingDraft = false;
        });
      }
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
      await _loadPagos();
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
      await _loadCargos();
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
      await _loadMovimientos();
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

  Future<void> _handleCancel() async {
    if (_isSaving || _isPersistingDraft) {
      return;
    }
    if (widget.pedido == null && _draftCreatedInSession && _pedidoId != null) {
      try {
        await Pedido.deleteById(_pedidoId!);
      } catch (_) {
        // ignore cleanup errors
      }
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context, false);
  }

  Map<String, double> _buildDraftMovimientoTotals(
      List<_MovimientoRow> movimientos) {
    if (movimientos.isEmpty) {
      return <String, double>{};
    }
    final Map<String, double> totals = <String, double>{};
    for (final _MovimientoRow row in movimientos) {
      for (final DetalleMovimiento detalle in row.detalles) {
        totals[detalle.idproducto] =
            (totals[detalle.idproducto] ?? 0) + detalle.cantidad;
      }
    }
    totals.removeWhere((String _, double value) => value <= 0);
    return totals;
  }

  Map<String, double>? _draftBufferForMovimiento({_MovimientoRow? row}) {
    if (!_isDraftContext || _draftMovimientoTotals.isEmpty) {
      return null;
    }
    final Map<String, double> buffer =
        Map<String, double>.from(_draftMovimientoTotals);
    if (row != null) {
      for (final DetalleMovimiento detalle in row.detalles) {
        final String productoId = detalle.idproducto;
        final double updated =
            (buffer[productoId] ?? 0) - detalle.cantidad;
        if (updated <= 0.0001) {
          buffer.remove(productoId);
        } else {
          buffer[productoId] = updated;
        }
      }
    }
    buffer.removeWhere((String _, double value) => value <= 0.0001);
    return buffer.isEmpty ? null : buffer;
  }

  @override
  Widget build(BuildContext context) {
    final Widget formBody = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildClienteField(),
          if (_isEditing) ...<Widget>[
            const SizedBox(height: 12),
            _buildReadOnlyTimestamp(),
          ],
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
          ..._inlineSections
              .where(
                (_InlineFormSectionConfigBase section) =>
                    section.shouldDisplay(this),
              )
              .map(
                (_InlineFormSectionConfigBase section) =>
                    section.buildSection(this),
              ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pedido == null ? 'Nuevo pedido' : 'Editar pedido'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: formBody,
              ),
            ),
            SafeArea(
              top: false,
              child: _FormFooter(
                isSaving: _isSaving || _isPersistingDraft,
                onCancel:
                    (_isSaving || _isPersistingDraft) ? null : _handleCancel,
                onSave: (_isSaving || _isPersistingDraft) ? null : _onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalleRow {
  const _DetalleRow({required this.detalle, required this.index});

  final DetallePedido detalle;
  final int index;
}

class _MovimientoRow {
  const _MovimientoRow({
    required this.base,
    required this.resumen,
    required this.detalles,
  });

  final MovimientoPedido base;
  final MovimientoResumen? resumen;
  final List<DetalleMovimiento> detalles;
}

abstract class _InlineFormSectionConfigBase {
  const _InlineFormSectionConfigBase();

  bool get loadOnInitWhenEditing;

  Future<void> loadData(_PedidosFormViewState state);

  bool shouldDisplay(_PedidosFormViewState state);

  Widget buildSection(_PedidosFormViewState state);
}

class _InlineFormSectionConfig<T> extends _InlineFormSectionConfigBase {
  const _InlineFormSectionConfig({
    required this.key,
    required this.title,
    required this.helperText,
    required this.emptyMessage,
    required this.minTableWidth,
    required this.itemsSelector,
    required this.isLoadingSelector,
    required this.columnsBuilder,
    this.onAdd,
    this.onEdit,
    this.loadDataCallback,
    this.visiblePredicate,
    this.loadOnInitWhenEditing = false,
    this.rowMaxHeight,
    this.rowMaxHeightBuilder,
  });

  final String key;
  final String title;
  final String helperText;
  final String emptyMessage;
  final double minTableWidth;
  final List<T> Function(_PedidosFormViewState state) itemsSelector;
  final bool Function(_PedidosFormViewState state) isLoadingSelector;
  final List<TableColumnConfig<T>> Function(_PedidosFormViewState state)
      columnsBuilder;
  final Future<void> Function(_PedidosFormViewState state)? onAdd;
  final Future<void> Function(_PedidosFormViewState state, T item)? onEdit;
  final Future<void> Function(_PedidosFormViewState state)? loadDataCallback;
  final bool Function(_PedidosFormViewState state)? visiblePredicate;
  @override
  final bool loadOnInitWhenEditing;
  final double? rowMaxHeight;
  final double? Function(_PedidosFormViewState state, List<T> items)?
      rowMaxHeightBuilder;

  @override
  Future<void> loadData(_PedidosFormViewState state) {
    if (loadDataCallback == null) {
      return Future<void>.value();
    }
    return loadDataCallback!(state);
  }

  @override
  bool shouldDisplay(_PedidosFormViewState state) =>
      visiblePredicate?.call(state) ?? true;

  @override
  Widget buildSection(_PedidosFormViewState state) {
    if (isLoadingSelector(state)) {
      return state._loadingCard();
    }

    final List<T> items = itemsSelector(state);
    final double? effectiveRowMaxHeight =
        rowMaxHeightBuilder?.call(state, items) ?? rowMaxHeight;
    return InlineFormTable<T>(
      title: title,
      items: items,
      columns: columnsBuilder(state),
      minTableWidth: minTableWidth,
      emptyMessage: emptyMessage,
      helperText: helperText,
      rowMaxHeight: effectiveRowMaxHeight,
      onAdd: onAdd == null ? null : () => onAdd!(state),
      onRowTap: onEdit == null ? null : (T item) => onEdit!(state, item),
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onSave,
              child: Text(isSaving ? 'Guardando...' : 'Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
