import 'package:demo_pedidos/features/viajes/presentation/form/viaje_form_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viaje_detalles_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/shared/viaje_detalle_form_view.dart';
import 'package:demo_pedidos/models/viaje.dart';
import 'package:demo_pedidos/models/viaje_detalle.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/detail_inline_section.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class ViajeDetalleView extends StatefulWidget {
  const ViajeDetalleView({
    super.key,
    required this.viajeId,
  });

  final String viajeId;

  @override
  State<ViajeDetalleView> createState() => _ViajeDetalleViewState();
}

class _ViajeDetalleViewState extends State<ViajeDetalleView> {
  late Future<void> _future;
  Viaje? _viaje;
  List<ViajeDetalle> _detalles = <ViajeDetalle>[];

  bool _hasChanges = false;
  bool _isDeletingViaje = false;
  String? _detalleEnProceso;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() async {
    final Viaje? viaje = await Viaje.fetchById(widget.viajeId);
    final List<ViajeDetalle> detalles =
        await ViajeDetalle.getByViaje(widget.viajeId);
    if (!mounted) {
      return;
    }
    setState(() {
      _viaje = viaje;
      _detalles = detalles;
    });
  }

  Future<void> _refresh() {
    final Future<void> future = _loadData();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _confirmDelete() async {
    final Viaje? viaje = _viaje;
    if (viaje == null) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar viaje'),
          content: Text(
            '¿Deseas eliminar el viaje de ${viaje.nombreMotorizado}? Esta acción no se puede deshacer.',
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
    if (confirm == true) {
      await _deleteViaje();
    }
  }

  Future<void> _deleteViaje() async {
    setState(() {
      _isDeletingViaje = true;
    });
    try {
      await Viaje.deleteById(widget.viajeId);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDeletingViaje = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el viaje: $error')),
      );
    }
  }

  Future<void> _editViaje() async {
    final Viaje? viaje = _viaje;
    if (viaje == null) {
      return;
    }
    final bool? result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ViajeFormView(viaje: viaje),
      ),
    );
    if (result == true) {
      _hasChanges = true;
      await _refresh();
    }
  }

  Future<void> _openDetalleForm({ViajeDetalle? detalle}) async {
    final Viaje? viaje = _viaje;
    if (viaje == null) {
      return;
    }
    final ViajeDetalleFormResult? result =
        await Navigator.push<ViajeDetalleFormResult>(
      context,
      MaterialPageRoute<ViajeDetalleFormResult>(
        builder: (_) => ViajeDetalleFormView(
          viajeId: viaje.id,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      _detalleEnProceso = detalle?.id ?? '__new__';
    });
    try {
      if (detalle == null) {
        await ViajeDetalle.insert(
          idViaje: viaje.id,
          idMovimiento: result.idMovimiento,
        );
      } else {
        await ViajeDetalle.actualizarMovimiento(
          id: detalle.id,
          idMovimiento: result.idMovimiento,
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
        SnackBar(content: Text('No se pudo guardar el detalle: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _detalleEnProceso = null;
        });
      }
    }
  }

  Future<void> _deleteDetalle(ViajeDetalle detalle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Quitar movimiento'),
          content: const Text(
            '¿Deseas quitar este movimiento del viaje?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Quitar'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    setState(() {
      _detalleEnProceso = detalle.id;
    });
    try {
      await ViajeDetalle.delete(detalle.id);
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
        SnackBar(content: Text('No se pudo quitar el movimiento: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _detalleEnProceso = null;
        });
      }
    }
  }

  Future<void> _openDetalleTabla() async {
    final Viaje? viaje = _viaje;
    if (viaje == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ViajeDetallesListView(
          includeDrawer: false,
          returnResult: true,
          viajeId: viaje.id,
        ),
      ),
    );
    if (changed == true) {
      _hasChanges = true;
      await _refresh();
    }
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
        title: 'Detalle del viaje',
        currentSection: AppSection.viajes,
        includeDrawer: false,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: _isDeletingViaje ? 'Eliminando...' : 'Eliminar',
            onPressed: _isDeletingViaje ? null : _confirmDelete,
            icon: _isDeletingViaje
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
          ),
        ],
        floatingActionButton: _viaje == null
            ? null
            : FloatingActionButton(
                tooltip: 'Editar',
                onPressed: _editViaje,
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
                      const Text('No se pudo cargar el viaje.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
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

            final Viaje? viaje = _viaje;
            if (viaje == null) {
              return const Center(child: Text('Viaje no encontrado.'));
            }

            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double viewportWidth = constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final double safeWidth = viewportWidth.isFinite
                    ? viewportWidth
                    : MediaQuery.of(context).size.width;
                final double minTableWidth = safeWidth < 640 ? 640 : safeWidth;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _SummaryCard(viaje: viaje),
                      const SizedBox(height: 16),
                      DetailInlineSection<ViajeDetalle>(
                        title: 'Movimientos asignados',
                        items: _detalles,
                        columns: _detalleColumns(),
                        minTableWidth: minTableWidth,
                        emptyMessage: 'Sin movimientos asignados.',
                        onAdd: () => _openDetalleForm(),
                        onView: _openDetalleTabla,
                        onRowTap: (ViajeDetalle item) =>
                            _openDetalleForm(detalle: item),
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

  List<TableColumnConfig<ViajeDetalle>> _detalleColumns() {
    return <TableColumnConfig<ViajeDetalle>>[
      TableColumnConfig<ViajeDetalle>(
        label: 'Cliente',
        sortAccessor: (ViajeDetalle item) => item.clienteNombre ?? '',
        cellBuilder: (ViajeDetalle item) =>
            Text(item.clienteNombre ?? 'Cliente'),
      ),
      TableColumnConfig<ViajeDetalle>(
        label: 'Contacto',
        sortAccessor: (ViajeDetalle item) => item.contactoNumero ?? '',
        cellBuilder: (ViajeDetalle item) => Text(item.contactoNumero ?? '-'),
      ),
      TableColumnConfig<ViajeDetalle>(
        label: 'Dirección / Destino',
        sortAccessor: (ViajeDetalle item) => item.esProvincia
            ? (item.provinciaDestino ?? '')
            : (item.direccionTexto ?? ''),
        cellBuilder: (ViajeDetalle item) => Text(
          item.esProvincia
              ? _buildProvinciaDestino(item)
              : (item.direccionTexto?.isNotEmpty == true
                  ? item.direccionTexto!
                  : 'Sin dirección'),
        ),
      ),
      TableColumnConfig<ViajeDetalle>(
        label: 'Packing',
        sortAccessor: (ViajeDetalle item) => item.packingNombre ?? '',
        cellBuilder: (ViajeDetalle item) =>
            Text(item.packingNombre ?? 'No asignado'),
      ),
      TableColumnConfig<ViajeDetalle>(
        label: 'Estado',
        sortAccessor: (ViajeDetalle item) => item.entregado ? 1 : 0,
        cellBuilder: (ViajeDetalle item) => item.entregado
            ? const Chip(
                label: Text('Entregado'),
                visualDensity: VisualDensity.compact,
              )
            : const Chip(
                label: Text('Pendiente'),
                visualDensity: VisualDensity.compact,
              ),
      ),
      TableColumnConfig<ViajeDetalle>(
        label: 'Acciones',
        cellBuilder: (ViajeDetalle item) => DetailRowActions(
          onEdit: () => _openDetalleForm(detalle: item),
          onDelete:
              _detalleEnProceso == item.id ? null : () => _deleteDetalle(item),
          isDeleting: _detalleEnProceso == item.id,
        ),
      ),
    ];
  }

  String _buildProvinciaDestino(ViajeDetalle item) {
    final List<String> parts = <String>[];
    if ((item.provinciaDestino ?? '').trim().isNotEmpty) {
      parts.add(item.provinciaDestino!.trim());
    }
    if ((item.provinciaDestinatario ?? '').trim().isNotEmpty) {
      parts.add('Destinatario: ${item.provinciaDestinatario!.trim()}');
    }
    if ((item.provinciaDni ?? '').trim().isNotEmpty) {
      parts.add('DNI: ${item.provinciaDni!.trim()}');
    }
    return parts.isEmpty ? 'Provincia' : parts.join('\n');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.viaje,
  });

  final Viaje viaje;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_Field> fields = <_Field>[
      _Field(label: 'Motorizado', value: viaje.nombreMotorizado),
      _Field(
        label: 'WhatsApp',
        value: viaje.numWsp?.isNotEmpty == true ? viaje.numWsp! : '-',
      ),
      _Field(label: 'Número llamadas', value: viaje.numLlamadas),
      _Field(label: 'Número pago', value: viaje.numPago),
      _Field(
        label: 'Link',
        value: viaje.link.isNotEmpty ? viaje.link : '-',
      ),
      _Field(
        label: 'Packing',
        value: viaje.packingNombre ?? 'No asignado',
      ),
      _Field(
        label: 'Fecha de viaje',
        value: _formatFecha(viaje.registradoAt),
      ),
      _Field(
        label: 'Total movimientos',
        value: '${viaje.totalItems}',
      ),
      _Field(
        label: 'Pendientes',
        value: '${viaje.pendientes}',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Información del motorizado',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < fields.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(height: 12),
              fields[i],
            ],
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final String day = fecha.day.toString().padLeft(2, '0');
    final String month = fecha.month.toString().padLeft(2, '0');
    final String hour = fecha.hour.toString().padLeft(2, '0');
    final String min = fecha.minute.toString().padLeft(2, '0');
    return '$day/$month/${fecha.year} $hour:$min';
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

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
        ),
      ],
    );
  }
}
