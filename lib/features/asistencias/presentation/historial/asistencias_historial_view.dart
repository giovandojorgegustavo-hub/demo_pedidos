import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/asistencia_estado.dart';
import 'package:demo_pedidos/models/asistencia_historial.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class AsistenciasHistorialView extends StatefulWidget {
  const AsistenciasHistorialView({super.key});

  @override
  State<AsistenciasHistorialView> createState() =>
      _AsistenciasHistorialViewState();
}

class _AsistenciasHistorialViewState
    extends State<AsistenciasHistorialView> {
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  String? _baseFilter;
  AsistenciaEstado? _estadoFilter;
  late Future<List<AsistenciaHistorial>> _future = _load();
  List<LogisticaBase> _bases = <LogisticaBase>[];

  @override
  void initState() {
    super.initState();
    _loadBases();
  }

  Future<void> _loadBases() async {
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    if (!mounted) {
      return;
    }
    setState(() => _bases = bases);
  }

  Future<List<AsistenciaHistorial>> _load() {
    return AsistenciaHistorial.fetch(
      from: _range.start,
      to: _range.end,
      baseId: _baseFilter,
      estado: _estadoFilter,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _pickRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDateRange: _range,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
      });
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Historial de asistencias',
      currentSection: AppSection.asistenciasHistorial,
      actions: <Widget>[
        IconButton(
          tooltip: 'Rango de fechas',
          onPressed: _pickRange,
          icon: const Icon(Icons.date_range_outlined),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(
                  label: Text(
                    '${_formatDate(_range.start)} · ${_formatDate(_range.end)}',
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String>('hist-base-${_baseFilter ?? 'all'}'),
                    initialValue: _baseFilter,
                    decoration: const InputDecoration(labelText: 'Base'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ..._bases.map(
                        (LogisticaBase base) => DropdownMenuItem<String?>(
                          value: base.id,
                          child: Text(base.nombre),
                        ),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _baseFilter = value);
                      await _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<AsistenciaEstado?>(
                    key: ValueKey<String>('hist-estado-${_estadoFilter?.index ?? -1}'),
                    initialValue: _estadoFilter,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: <DropdownMenuItem<AsistenciaEstado?>>[
                      const DropdownMenuItem<AsistenciaEstado?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...AsistenciaEstado.values.map(
                        (AsistenciaEstado estado) =>
                            DropdownMenuItem<AsistenciaEstado?>(
                          value: estado,
                          child: Text(_estadoLabel(estado)),
                        ),
                      ),
                    ],
                    onChanged: (AsistenciaEstado? value) async {
                      setState(() => _estadoFilter = value);
                      await _reload();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AsistenciaHistorial>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<AsistenciaHistorial>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudo cargar el historial.'),
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
                final List<AsistenciaHistorial> data =
                    snapshot.data ?? <AsistenciaHistorial>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin registros para los filtros seleccionados.'),
                  );
                }
                return TableSection<AsistenciaHistorial>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  searchPlaceholder: 'Buscar por base o slot',
                  searchTextBuilder: (AsistenciaHistorial item) =>
                      '${item.baseNombre} ${item.slotNombre} ${item.observacion ?? ''}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<AsistenciaHistorial>> get _columns {
    return <TableColumnConfig<AsistenciaHistorial>>[
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Fecha',
        sortAccessor: (AsistenciaHistorial item) => item.fecha,
        cellBuilder: (AsistenciaHistorial item) =>
            Text(_formatDate(item.fecha)),
      ),
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Base',
        sortAccessor: (AsistenciaHistorial item) => item.baseNombre,
        cellBuilder: (AsistenciaHistorial item) => Text(item.baseNombre),
      ),
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Slot',
        sortAccessor: (AsistenciaHistorial item) =>
            '${item.slotNombre} ${item.slotHora}',
        cellBuilder: (AsistenciaHistorial item) =>
            Text('${item.slotNombre} (${item.slotHora.substring(0, 5)})'),
      ),
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Estado',
        sortAccessor: (AsistenciaHistorial item) => item.estado.index,
        cellBuilder: (AsistenciaHistorial item) => Chip(
          label: Text(_estadoLabel(item.estado)),
          backgroundColor: _estadoColor(item.estado),
        ),
      ),
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Observación',
        sortAccessor: (AsistenciaHistorial item) =>
            item.observacion ?? '',
        cellBuilder: (AsistenciaHistorial item) =>
            Text(item.observacion ?? '-', maxLines: 2),
      ),
      TableColumnConfig<AsistenciaHistorial>(
        label: 'Registrado por',
        sortAccessor: (AsistenciaHistorial item) =>
            item.registradoPor ?? '',
        cellBuilder: (AsistenciaHistorial item) =>
            Text(item.registradoPor ?? '-'),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _estadoLabel(AsistenciaEstado estado) => switch (estado) {
        AsistenciaEstado.asistio => 'Asistió',
        AsistenciaEstado.justificado => 'Justificado',
        AsistenciaEstado.falta => 'Falta',
      };

  Color _estadoColor(AsistenciaEstado estado) => switch (estado) {
        AsistenciaEstado.asistio => Colors.green.shade100,
        AsistenciaEstado.justificado => Colors.orange.shade100,
        AsistenciaEstado.falta => Colors.red.shade100,
      };
}
