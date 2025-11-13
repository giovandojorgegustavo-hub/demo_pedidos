import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/asistencias/presentation/asignaciones/asistencias_asignacion_form_view.dart';
import 'package:demo_pedidos/models/asistencia_asignacion.dart';
import 'package:demo_pedidos/models/asistencia_slot.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

const Map<String, String> _diasLabels = <String, String>{
  'lunes': 'Lunes',
  'martes': 'Martes',
  'miercoles': 'Miércoles',
  'jueves': 'Jueves',
  'viernes': 'Viernes',
  'sabado': 'Sábado',
  'domingo': 'Domingo',
};

class AsistenciasAsignacionesListView extends StatefulWidget {
  const AsistenciasAsignacionesListView({super.key});

  @override
  State<AsistenciasAsignacionesListView> createState() =>
      _AsistenciasAsignacionesListViewState();
}

class _AsistenciasAsignacionesListViewState
    extends State<AsistenciasAsignacionesListView> {
  late Future<List<AsistenciaAsignacion>> _future = _load();
  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<AsistenciaSlot> _slots = <AsistenciaSlot>[];
  Future<void>? _catalogosFuture;

  @override
  void initState() {
    super.initState();
    _catalogosFuture = _loadCatalogos();
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      LogisticaBase.getBases(),
      AsistenciaSlot.fetchAll(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _bases = results[0] as List<LogisticaBase>;
      _slots = results[1] as List<AsistenciaSlot>;
    });
  }

  Future<List<AsistenciaAsignacion>> _load() {
    return AsistenciaAsignacion.fetchAll();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openForm({AsistenciaAsignacion? asignacion}) async {
    await _catalogosFuture;
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AsistenciasAsignacionFormView(
          asignacion: asignacion,
          bases: _bases,
          slots: _slots,
        ),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Asignaciones de slots',
      currentSection: AppSection.asistenciasBaseSlots,
      actions: <Widget>[
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<AsistenciaAsignacion>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<AsistenciaAsignacion>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudieron cargar las asignaciones.'),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _reload,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }
          final List<AsistenciaAsignacion> data =
              snapshot.data ?? <AsistenciaAsignacion>[];
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras asignaciones.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Crear asignación'),
                  ),
                ],
              ),
            );
          }
          return TableSection<AsistenciaAsignacion>(
            items: data,
            columns: _columns,
            searchPlaceholder: 'Buscar por base o slot',
            searchTextBuilder: (AsistenciaAsignacion asignacion) =>
                '${asignacion.baseNombre} ${asignacion.slotNombre}',
            minTableWidth: 900,
            onRowTap: (AsistenciaAsignacion asignacion) =>
                _openForm(asignacion: asignacion),
          );
        },
      ),
    );
  }

  List<TableColumnConfig<AsistenciaAsignacion>> get _columns {
    return <TableColumnConfig<AsistenciaAsignacion>>[
      TableColumnConfig<AsistenciaAsignacion>(
        label: 'Base',
        sortAccessor: (AsistenciaAsignacion item) => item.baseNombre,
        cellBuilder: (AsistenciaAsignacion item) => Text(item.baseNombre),
      ),
      TableColumnConfig<AsistenciaAsignacion>(
        label: 'Slot',
        sortAccessor: (AsistenciaAsignacion item) =>
            '${item.slotNombre} ${item.slotHora}',
        cellBuilder: (AsistenciaAsignacion item) =>
            Text('${item.slotNombre} (${item.slotHora.substring(0, 5)})'),
      ),
      TableColumnConfig<AsistenciaAsignacion>(
        label: 'Días',
        sortAccessor: (AsistenciaAsignacion item) =>
            item.diasSemana.join(','),
        cellBuilder: (AsistenciaAsignacion item) =>
            Text(_formatDias(item.diasSemana)),
      ),
      TableColumnConfig<AsistenciaAsignacion>(
        label: 'Estado',
        sortAccessor: (AsistenciaAsignacion item) => item.activo ? '1' : '0',
        cellBuilder: (AsistenciaAsignacion item) => Chip(
          label: Text(item.activo ? 'Activo' : 'Inactivo'),
          backgroundColor:
              item.activo ? Colors.green.shade100 : Colors.grey.shade300,
        ),
      ),
    ];
  }

  String _formatDias(List<String> dias) {
    final List<String> labels = dias
        .map((String dia) => _diasLabels[dia] ?? dia)
        .toList(growable: false);
    return labels.join(', ');
  }
}
