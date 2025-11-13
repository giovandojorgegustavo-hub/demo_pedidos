import 'package:demo_pedidos/features/viajes/presentation/detail/viaje_detalle_view.dart';
import 'package:demo_pedidos/models/viaje_detalle.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/entity_table_page.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class ViajeDetallesListView extends StatefulWidget {
  const ViajeDetallesListView({
    super.key,
    this.viajeId,
    this.includeDrawer = true,
    this.returnResult = false,
  });

  final String? viajeId;
  final bool includeDrawer;
  final bool returnResult;

  @override
  State<ViajeDetallesListView> createState() => _ViajeDetallesListViewState();
}

class _ViajeDetallesListViewState extends State<ViajeDetallesListView> {
  int _reloadToken = 0;

  Future<List<ViajeDetalle>> _loadItems() async {
    final List<ViajeDetalle> items = widget.viajeId == null
        ? await ViajeDetalle.fetchAll()
        : await ViajeDetalle.getByViaje(widget.viajeId!);
    // Sólo mostrar pendientes (sin llegada)
    return items.where((ViajeDetalle item) => !item.entregado).toList();
  }

  Future<void> _markLlegada(ViajeDetalle detalle) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marcar llegada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(detalle.clienteNombre ?? 'Cliente'),
              const SizedBox(height: 4),
              Text(detalle.contactoNumero ?? '-'),
              const SizedBox(height: 4),
              Text(detalle.direccionTexto ?? detalle.provinciaDestino ?? ''),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Llegó'),
            ),
          ],
        );
      },
    );
    if (confirm != true) {
      return;
    }
    await ViajeDetalle.marcarLlegada(
      id: detalle.id,
      usuario: 'system',
      fecha: DateTime.now(),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Llegada registrada.')),
    );
    setState(() {
      _reloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return EntityTablePage<ViajeDetalle>(
      key: ValueKey<int>(_reloadToken),
      title: 'Detalle de viajes',
      currentSection: AppSection.viajesDetalle,
      includeDrawer: widget.includeDrawer,
      returnResult: widget.returnResult,
      loadItems: _loadItems,
      columns: _columns(context),
      searchTextBuilder: (ViajeDetalle item) =>
          '${item.clienteNombre ?? ''} ${item.contactoNumero ?? ''} '
          '${item.direccionTexto ?? ''} ${item.provinciaDestino ?? ''}',
      searchPlaceholder: 'Buscar cliente o contacto',
      minTableWidth: 780,
      onRowTap: (BuildContext context, ViajeDetalle item) async {
        final bool? result = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => ViajeDetalleView(viajeId: item.idViaje),
          ),
        );
        return result ?? false;
      },
      onDeleteSelected:
          (BuildContext context, List<ViajeDetalle> selected) async {
        for (final ViajeDetalle detalle in selected) {
          if (detalle.id.isNotEmpty) {
            await ViajeDetalle.delete(detalle.id);
          }
        }
      },
    );
  }

  List<TableColumnConfig<ViajeDetalle>> _columns(BuildContext context) {
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
              ? _destinoProvincia(item)
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
        label: 'Acciones',
        cellBuilder: (ViajeDetalle item) => Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Marcar llegada',
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _markLlegada(item),
            ),
          ],
        ),
      ),
    ];
  }

  String _destinoProvincia(ViajeDetalle item) {
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
