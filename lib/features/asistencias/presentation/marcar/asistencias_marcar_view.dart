import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/asistencia_estado.dart';
import 'package:demo_pedidos/models/asistencia_pendiente.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class AsistenciasMarcarView extends StatefulWidget {
  const AsistenciasMarcarView({super.key});

  @override
  State<AsistenciasMarcarView> createState() => _AsistenciasMarcarViewState();
}

class _AsistenciasMarcarViewState extends State<AsistenciasMarcarView> {
  DateTime _selectedDate = DateTime.now();
  String? _baseFilter;
  late Future<List<AsistenciaPendiente>> _future = _load();
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

  Future<List<AsistenciaPendiente>> _load() {
    return AsistenciaPendiente.fetch(
      fecha: _selectedDate,
      baseId: _baseFilter,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      await _reload();
    }
  }

  Future<void> _marcarAsistencia(
    AsistenciaPendiente item,
    AsistenciaEstado estado,
  ) async {
    final TextEditingController obsCtrl = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Marcar ${_estadoLabel(estado)}'),
        content: TextField(
          controller: obsCtrl,
          decoration: const InputDecoration(
            labelText: 'Observación (opcional)',
          ),
          maxLines: 2,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    await AsistenciaPendiente.marcar(
      idBase: item.idBase,
      idSlot: item.idSlot,
      fecha: item.fecha,
      estado: estado,
      observacion:
          obsCtrl.text.trim().isEmpty ? null : obsCtrl.text.trim(),
      registroId: item.registroId,
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Marcar asistencia',
      currentSection: AppSection.asistenciasMarcar,
      actions: <Widget>[
        IconButton(
          tooltip: 'Seleccionar fecha',
          onPressed: _pickDate,
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Fecha: ${_selectedDate.day.toString().padLeft(2, '0')}/'
                    '${_selectedDate.month.toString().padLeft(2, '0')}/'
                    '${_selectedDate.year}',
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey<String>('base-${_baseFilter ?? 'all'}'),
                    initialValue: _baseFilter,
                    decoration: const InputDecoration(
                      labelText: 'Base',
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las bases'),
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
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<AsistenciaPendiente>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<AsistenciaPendiente>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar las asistencias.'),
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
                final List<AsistenciaPendiente> data =
                    snapshot.data ?? <AsistenciaPendiente>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('No hay slots programados para esta fecha.'),
                  );
                }
                return TableSection<AsistenciaPendiente>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  toolbarActions: const <Widget>[],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<AsistenciaPendiente>> get _columns {
    return <TableColumnConfig<AsistenciaPendiente>>[
      TableColumnConfig<AsistenciaPendiente>(
        label: 'Base',
        sortAccessor: (AsistenciaPendiente item) => item.baseNombre,
        cellBuilder: (AsistenciaPendiente item) => Text(item.baseNombre),
      ),
      TableColumnConfig<AsistenciaPendiente>(
        label: 'Slot',
        sortAccessor: (AsistenciaPendiente item) =>
            '${item.slotNombre} ${item.slotHora}',
        cellBuilder: (AsistenciaPendiente item) =>
            Text('${item.slotNombre} (${item.slotHora.substring(0, 5)})'),
      ),
      TableColumnConfig<AsistenciaPendiente>(
        label: 'Estado',
        sortAccessor: (AsistenciaPendiente item) => item.estado.index,
        cellBuilder: (AsistenciaPendiente item) => Chip(
          label: Text(_estadoLabel(item.estado)),
          backgroundColor: _estadoColor(item.estado),
        ),
      ),
      TableColumnConfig<AsistenciaPendiente>(
        label: 'Acciones',
        cellBuilder: (AsistenciaPendiente item) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
              tooltip: 'Marcar asistencia',
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              onPressed: () => _marcarAsistencia(item, AsistenciaEstado.asistio),
            ),
            IconButton(
              tooltip: 'Justificar',
              icon: const Icon(Icons.pending_actions_outlined,
                  color: Colors.orange),
              onPressed: () =>
                  _marcarAsistencia(item, AsistenciaEstado.justificado),
            ),
            IconButton(
              tooltip: 'Marcar falta',
              icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
              onPressed: () => _marcarAsistencia(item, AsistenciaEstado.falta),
            ),
          ],
        ),
      ),
    ];
  }

  String _estadoLabel(AsistenciaEstado estado) {
    return switch (estado) {
      AsistenciaEstado.asistio => 'Asistió',
      AsistenciaEstado.justificado => 'Justificado',
      AsistenciaEstado.falta => 'Falta',
    };
  }

  Color _estadoColor(AsistenciaEstado estado) {
    return switch (estado) {
      AsistenciaEstado.asistio => Colors.green.shade100,
      AsistenciaEstado.justificado => Colors.orange.shade100,
      AsistenciaEstado.falta => Colors.red.shade100,
    };
  }
}
