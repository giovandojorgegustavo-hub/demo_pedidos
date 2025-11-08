import 'package:demo_pedidos/features/viajes/presentation/detail/viaje_detalle_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/form/viaje_form_view.dart';
import 'package:demo_pedidos/models/viaje.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

class ViajesListView extends StatefulWidget {
  const ViajesListView({
    super.key,
    this.includeDrawer = true,
    this.returnResult = false,
  });

  final bool includeDrawer;
  final bool returnResult;

  @override
  State<ViajesListView> createState() => _ViajesListViewState();
}

class _ViajesListViewState extends State<ViajesListView> {
  late Future<List<Viaje>> _future;
  int _pendientesCount = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadViajes();
  }

  Future<List<Viaje>> _loadViajes() async {
    final List<Viaje> items = await Viaje.fetchAll();
    if (!mounted) {
      return items;
    }
    setState(() {
      _pendientesCount = items.where((Viaje v) => !v.estaTerminado).length;
    });
    return items;
  }

  void _reload() {
    setState(() {
      _future = _loadViajes();
    });
  }

  Future<bool?> _openForm(BuildContext context, {Viaje? viaje}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ViajeFormView(viaje: viaje),
      ),
    );
  }

  Future<bool?> _openDetalle(BuildContext context, Viaje viaje) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ViajeDetalleView(viajeId: viaje.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: PageScaffold(
        title: 'Viajes',
        currentSection: AppSection.viajes,
        includeDrawer: widget.includeDrawer,
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final bool? result = await _openForm(context);
            if (result == true) {
              _reload();
            }
          },
          child: const Icon(Icons.add),
        ),
        bottom: TabBar(
          tabs: <Tab>[
            const Tab(text: 'Todos'),
            Tab(text: 'Pendientes (${_pendientesCount})'),
            const Tab(text: 'Llegados'),
          ],
        ),
        body: FutureBuilder<List<Viaje>>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<List<Viaje>> snapshot) {
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
                      const Text('No se pudo cargar la lista.'),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _reload,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final List<Viaje> items = snapshot.data ?? <Viaje>[];
            final List<Viaje> pendientes =
                items.where((Viaje v) => !v.estaTerminado).toList();
            final List<Viaje> llegados =
                items.where((Viaje v) => v.estaTerminado).toList();

            return TabBarView(
              children: <Widget>[
                _buildTableSection(context, items, empty: 'Sin viajes'),
                _buildTableSection(
                  context,
                  pendientes,
                  empty: 'Todos los viajes están completados.',
                ),
                _buildTableSection(
                  context,
                  llegados,
                  empty: 'Sin viajes completados.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTableSection(
    BuildContext context,
    List<Viaje> items, {
    required String empty,
  }) {
    return TableSection<Viaje>(
      items: items,
      columns: _columns,
      onRowTap: (Viaje viaje) async {
        final bool? result = await _openDetalle(context, viaje);
        if (result == true) {
          _reload();
        }
      },
      onRefresh: () async => _reload(),
      searchTextBuilder: (Viaje viaje) =>
          '${viaje.nombreMotorizado} ${viaje.numWsp ?? ''} ${viaje.numLlamadas}',
      searchPlaceholder: 'Buscar motorizado o contacto',
      emptyMessage: empty,
      minTableWidth: 720,
    );
  }

  List<TableColumnConfig<Viaje>> get _columns {
    return <TableColumnConfig<Viaje>>[
      TableColumnConfig<Viaje>(
        label: 'Fecha',
        sortAccessor: (Viaje viaje) => viaje.registradoAt,
        cellBuilder: (Viaje viaje) => Text(_formatFecha(viaje.registradoAt)),
      ),
      TableColumnConfig<Viaje>(
        label: 'Motorizado',
        sortAccessor: (Viaje viaje) => viaje.nombreMotorizado,
        cellBuilder: (Viaje viaje) => Text(viaje.nombreMotorizado),
      ),
      TableColumnConfig<Viaje>(
        label: 'WhatsApp',
        sortAccessor: (Viaje viaje) => viaje.numWsp ?? '',
        cellBuilder: (Viaje viaje) =>
            Text(viaje.numWsp?.isNotEmpty == true ? viaje.numWsp! : '-'),
      ),
      TableColumnConfig<Viaje>(
        label: 'Estado',
        sortAccessor: (Viaje viaje) => viaje.estadoCodigo ?? 99,
        cellBuilder: _estadoChip,
      ),
    ];
  }

  Widget _estadoChip(Viaje viaje) {
    final bool terminado = viaje.estaTerminado;
    final Color color = terminado ? Colors.green : Colors.orange;
    return Chip(
      label: Text(terminado ? 'Llegado' : 'Pendiente'),
      backgroundColor: color.withOpacity(0.12),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
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
