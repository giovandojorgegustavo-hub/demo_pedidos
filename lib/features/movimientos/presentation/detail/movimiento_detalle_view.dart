import 'package:demo_pedidos/features/movimientos/presentation/form/movimiento_form_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/list/detalle_movimiento_list_view.dart';
import 'package:demo_pedidos/features/movimientos/presentation/shared/detalle_movimiento_form_view.dart';
import 'package:demo_pedidos/models/detalle_movimiento.dart';
import 'package:demo_pedidos/models/movimiento_pedido.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/producto.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/detail_inline_section.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class MovimientoDetalleView extends StatefulWidget {
  const MovimientoDetalleView({super.key, required this.movimientoId});

  final String movimientoId;

  @override
  State<MovimientoDetalleView> createState() => _MovimientoDetalleViewState();
}

class _MovimientoDetalleViewState extends State<MovimientoDetalleView> {
  late Future<void> _future;
  MovimientoPedido? _movimiento;
  MovimientoResumen? _resumen;
  List<DetalleMovimiento> _detalles = <DetalleMovimiento>[];
  List<Producto> _productos = <Producto>[];
  bool _isDeleting = false;
  bool _hasChanges = false;
  String? _deletingDetalleId;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() async {
    final MovimientoPedido? movimiento =
        await MovimientoPedido.getById(widget.movimientoId);
    final MovimientoResumen? resumen =
        await MovimientoResumen.fetchById(widget.movimientoId);
    final List<DetalleMovimiento> detalles =
        await DetalleMovimiento.getByMovimiento(widget.movimientoId);
    final List<Producto> productos = await Producto.getProductos();

    if (!mounted) {
      return;
    }

    setState(() {
      _movimiento = movimiento;
      _resumen = resumen;
      _detalles = detalles;
      _productos = productos;
    });
  }

  Future<void> _refresh() {
    final Future<void> future = _loadData();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _reloadProductos() async {
    try {
      final List<Producto> productos = await Producto.getProductos();
      if (!mounted) {
        return;
      }
      setState(() {
        _productos = productos;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron cargar los productos: $error'),
        ),
      );
    }
  }

  Future<void> _delete() async {
    setState(() {
      _isDeleting = true;
    });
    try {
      await MovimientoPedido.deleteById(widget.movimientoId);
      if (!mounted) {
        return;
      }
      _hasChanges = true;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el movimiento: $error')),
      );
    }
  }

  Future<void> _edit() async {
    final MovimientoPedido? movimiento = _movimiento;
    if (movimiento == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => MovimientoFormView(
          pedidoId: movimiento.idpedido,
          movimiento: movimiento,
          detalles: _detalles,
        ),
      ),
    );
    if (changed == true) {
      _hasChanges = true;
      await _refresh();
    }
  }

  Future<void> _openDetalleForm({DetalleMovimiento? detalle}) async {
    if (!mounted) {
      return;
    }
    List<Producto> productos = _productos;
    if (productos.isEmpty) {
      await _reloadProductos();
      if (!mounted) {
        return;
      }
      productos = _productos;
    }
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay productos disponibles.')),
      );
      return;
    }

    final DetalleMovimientoFormResult? result =
        await Navigator.push<DetalleMovimientoFormResult>(
      context,
      MaterialPageRoute<DetalleMovimientoFormResult>(
        builder: (_) => DetalleMovimientoFormView(
          detalle: detalle,
          productos: productos,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.reloadProductos) {
      await _reloadProductos();
      if (!mounted) {
        return;
      }
    }

    final MovimientoPedido? movimiento = _movimiento;
    if (movimiento == null) {
      return;
    }

    try {
      if (detalle?.id != null) {
        await DetalleMovimiento.update(
          DetalleMovimiento(
            id: detalle!.id,
            idmovimiento: movimiento.id,
            idproducto: result.detalle.idproducto,
            cantidad: result.detalle.cantidad,
            productoNombre: result.detalle.productoNombre,
          ),
        );
      } else {
        await DetalleMovimiento.insert(
          movimiento.id,
          DetalleMovimiento(
            idproducto: result.detalle.idproducto,
            cantidad: result.detalle.cantidad,
            productoNombre: result.detalle.productoNombre,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      _hasChanges = true;
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el producto: $error')),
      );
    }
  }

  Future<void> _deleteDetalle(DetalleMovimiento detalle) async {
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
            '¿Deseas eliminar este producto del movimiento? Esta acción no se puede deshacer.',
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
      await DetalleMovimiento.delete(id);
      if (!mounted) {
        return;
      }
      _hasChanges = true;
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el producto: $error')),
      );
    } finally {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingDetalleId = null;
      });
    }
  }

  Future<void> _openDetalleTable() async {
    final MovimientoPedido? movimiento = _movimiento;
    if (movimiento == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => DetalleMovimientoListView(
          movimientoId: movimiento.id,
          includeDrawer: false,
          returnResult: true,
        ),
      ),
    );
    if (changed == true) {
      _hasChanges = true;
      await _refresh();
    }
  }

  List<TableColumnConfig<DetalleMovimiento>> _detalleColumns() {
    return <TableColumnConfig<DetalleMovimiento>>[
      TableColumnConfig<DetalleMovimiento>(
        label: 'Producto',
        sortAccessor: (DetalleMovimiento item) => item.productoNombre ?? '',
        cellBuilder: (DetalleMovimiento item) =>
            Text(item.productoNombre ?? 'Producto'),
      ),
      TableColumnConfig<DetalleMovimiento>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (DetalleMovimiento item) => item.cantidad,
        cellBuilder: (DetalleMovimiento item) =>
            Text(item.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<DetalleMovimiento>(
        label: 'Acciones',
        cellBuilder: (DetalleMovimiento item) => DetailRowActions(
          onEdit: () => _openDetalleForm(detalle: item),
          onDelete: item.id == null || _deletingDetalleId == item.id
              ? null
              : () => _deleteDetalle(item),
          isDeleting: _deletingDetalleId == item.id,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, true);
      },
      child: PageScaffold(
        title: 'Detalle del movimiento',
        currentSection: AppSection.movimientos,
        includeDrawer: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: _isDeleting ? 'Eliminando...' : 'Eliminar',
            onPressed: _isDeleting ? null : _delete,
            icon: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          ),
        ],
        floatingActionButton: _movimiento == null
            ? null
            : FloatingActionButton(
                tooltip: 'Editar',
                onPressed: _edit,
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
                      const Text('No se pudo cargar el movimiento.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final MovimientoPedido? movimiento = _movimiento;
            if (movimiento == null) {
              return const Center(child: Text('Movimiento no encontrado.'));
            }

            final MovimientoResumen? resumen = _resumen;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewportWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final double safeWidth = viewportWidth.isFinite
                    ? viewportWidth
                    : MediaQuery.of(context).size.width;
                final double minTableWidth =
                    safeWidth < 560 ? 560 : safeWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _SummaryCard(movimiento: movimiento, resumen: resumen),
                      const SizedBox(height: 16),
                      DetailInlineSection<DetalleMovimiento>(
                        title: 'Productos del movimiento',
                        items: _detalles,
                        columns: _detalleColumns(),
                        minTableWidth: minTableWidth,
                        emptyMessage: 'Sin productos asociados.',
                        onAdd: () => _openDetalleForm(),
                        onRowTap: (DetalleMovimiento item) =>
                            _openDetalleForm(detalle: item),
                        onView: _openDetalleTable,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.movimiento,
    required this.resumen,
  });

  final MovimientoPedido movimiento;
  final MovimientoResumen? resumen;

  String get _contacto {
    final String? contacto = resumen?.contactoNumero?.trim();
    if (contacto != null && contacto.isNotEmpty) {
      return contacto;
    }
    final String? numero = resumen?.clienteNumero?.trim();
    if (numero != null && numero.isNotEmpty) {
      return numero;
    }
    return '-';
  }

  String get _destino {
    if (resumen == null) {
      return movimiento.esProvincia ? '-' : 'Sin dirección';
    }
    if (movimiento.esProvincia) {
      final List<String> parts = <String>[];
      final String destino = (resumen?.provinciaDestino ?? '').trim();
      if (destino.isNotEmpty) {
        parts.add(destino);
      }
      final String destinatario = (resumen?.provinciaDestinatario ?? '').trim();
      if (destinatario.isNotEmpty) {
        parts.add('Destinatario: $destinatario');
      }
      final String dni = (resumen?.provinciaDni ?? '').trim();
      if (dni.isNotEmpty) {
        parts.add('DNI: $dni');
      }
      return parts.isEmpty ? '-' : parts.join('\n');
    }
    final String direccion = (resumen?.direccion ?? '').trim();
    final String referencia = (resumen?.direccionReferencia ?? '').trim();
    if (referencia.isEmpty) {
      return direccion.isEmpty ? 'Sin dirección' : direccion;
    }
    if (direccion.isEmpty) {
      return 'Ref: $referencia';
    }
    return '$direccion\nRef: $referencia';
  }

  String get _base {
    final String? nombre = resumen?.baseNombre?.trim();
    if (nombre != null && nombre.isNotEmpty) {
      return nombre;
    }
    return movimiento.baseNombre ?? '-';
  }

  String get _observacion {
    final String obs = (resumen?.observacion ?? '').trim();
    return obs.isEmpty ? '-' : obs;
  }

  @override
  Widget build(BuildContext context) {
    final List<_Field> fields = <_Field>[
      _Field(
        label: 'Fecha',
        value: _formatDateTime(movimiento.fecharegistro),
      ),
      _Field(
        label: 'Cliente',
        value: resumen?.clienteNombre ?? '-',
      ),
      _Field(
        label: 'Contacto',
        value: _contacto,
      ),
      _Field(
        label: 'Base',
        value: _base,
      ),
      _Field(
        label: movimiento.esProvincia
            ? 'Destino (provincia)'
            : 'Dirección de entrega',
        value: _destino,
        multiline: true,
      ),
      _Field(
        label: 'Provincia',
        value: movimiento.esProvincia ? 'Sí' : 'No',
      ),
      _Field(
        label: 'Observación',
        value: _observacion,
        multiline: true,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < fields.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 16),
              fields[i],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final String d = date.day.toString().padLeft(2, '0');
    final String m = date.month.toString().padLeft(2, '0');
    final String h = date.hour.toString().padLeft(2, '0');
    final String min = date.minute.toString().padLeft(2, '0');
    return '$d/$m/${date.year} $h:$min';
  }
}

class _Field extends StatelessWidget {
  const _Field({
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
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.outline),
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
