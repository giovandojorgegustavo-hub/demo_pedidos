import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/comunicaciones/presentation/incidentes/comunicaciones_incidente_form_view.dart';
import 'package:demo_pedidos/models/incidente.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ComunicacionesIncidentesListView extends StatefulWidget {
  const ComunicacionesIncidentesListView({super.key});

  @override
  State<ComunicacionesIncidentesListView> createState() =>
      _ComunicacionesIncidentesListViewState();
}

class _ComunicacionesIncidentesListViewState
    extends State<ComunicacionesIncidentesListView> {
  String? _estadoFilter;
  String? _responsabilidadFilter;
  String? _baseFilter;
  late Future<List<Incidente>> _future = _load();
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

  Future<List<Incidente>> _load() {
    return Incidente.fetchAll(
      estado: _estadoFilter,
      responsabilidad: _responsabilidadFilter,
      baseId: _baseFilter,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openForm({Incidente? incidente}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ComunicacionesIncidenteFormView(
          incidente: incidente,
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
      title: 'Incidencias',
      currentSection: AppSection.comunicacionesIncidentes,
      actions: <Widget>[
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_alert),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Estado'),
                    initialValue: _estadoFilter,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ...kIncidenteEstados.map(
                        (String estado) => DropdownMenuItem<String?>
                            (value: estado, child: Text(estado)),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _estadoFilter = value);
                      await _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    decoration:
                        const InputDecoration(labelText: 'Responsabilidad'),
                    initialValue: _responsabilidadFilter,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...kIncidenteResponsables.map(
                        (String resp) => DropdownMenuItem<String?>
                            (value: resp, child: Text(resp)),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _responsabilidadFilter = value);
                      await _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Base'),
                    initialValue: _baseFilter,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las bases'),
                      ),
                      ..._bases.map(
                        (LogisticaBase base) => DropdownMenuItem<String?>
                            (value: base.id, child: Text(base.nombre)),
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
            child: FutureBuilder<List<Incidente>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<Incidente>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudieron cargar las incidencias.'),
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
                final List<Incidente> data = snapshot.data ?? <Incidente>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin incidencias registradas.'),
                  );
                }
                return TableSection<Incidente>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1100,
                  searchPlaceholder: 'Buscar por título o base',
                  searchTextBuilder: (Incidente item) =>
                      '${item.titulo} ${item.baseNombre ?? ''}',
                  onRowTap: (Incidente item) => _openForm(incidente: item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<Incidente>> get _columns {
    return <TableColumnConfig<Incidente>>[
      TableColumnConfig<Incidente>(
        label: 'Fecha',
        sortAccessor: (Incidente item) =>
            item.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (Incidente item) => item.registradoAt == null
            ? const Text('-')
            : Text(_formatDate(item.registradoAt!)),
      ),
      TableColumnConfig<Incidente>(
        label: 'Título',
        sortAccessor: (Incidente item) => item.titulo,
        cellBuilder: (Incidente item) => Text(item.titulo),
      ),
      TableColumnConfig<Incidente>(
        label: 'Base',
        sortAccessor: (Incidente item) => item.baseNombre ?? '',
        cellBuilder: (Incidente item) => Text(item.baseNombre ?? '-'),
      ),
      TableColumnConfig<Incidente>(
        label: 'Responsable',
        sortAccessor: (Incidente item) => item.responsabilidad ?? '',
        cellBuilder: (Incidente item) =>
            Text(item.responsabilidad ?? '-'),
      ),
      TableColumnConfig<Incidente>(
        label: 'Severidad',
        sortAccessor: (Incidente item) => item.severidad,
        cellBuilder: (Incidente item) => Chip(
          label: Text(item.severidad),
          backgroundColor: _severityColor(item.severidad),
        ),
      ),
      TableColumnConfig<Incidente>(
        label: 'Estado',
        sortAccessor: (Incidente item) => item.estado,
        cellBuilder: (Incidente item) => Chip(
          label: Text(item.estado),
          backgroundColor: _statusColor(item.estado),
        ),
      ),
      TableColumnConfig<Incidente>(
        label: 'Seguimiento',
        cellBuilder: (Incidente item) => IconButton(
          tooltip: 'Ver historial',
          icon: const Icon(Icons.history),
          onPressed: () => _showHistory(item),
        ),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'alta':
        return Colors.red.shade100;
      case 'critica':
        return Colors.red.shade200;
      case 'baja':
        return Colors.green.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _statusColor(String estado) {
    switch (estado) {
      case 'resuelto':
      case 'cerrado':
        return Colors.green.shade100;
      case 'investigacion':
        return Colors.orange.shade100;
      default:
        return Colors.red.shade100;
    }
  }

  Future<void> _showHistory(Incidente incidente) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _IncidenteHistorialSheet(incidente: incidente);
      },
    );
  }
}

class _IncidenteHistorialSheet extends StatefulWidget {
  const _IncidenteHistorialSheet({required this.incidente});

  final Incidente incidente;

  @override
  State<_IncidenteHistorialSheet> createState() =>
      _IncidenteHistorialSheetState();
}

class _IncidenteHistorialSheetState extends State<_IncidenteHistorialSheet> {
  late Future<List<IncidenteHistorial>> _future =
      IncidenteHistorial.fetch(widget.incidente.id);
  final TextEditingController _comentarioCtrl = TextEditingController();
  String? _estado;

  Future<void> _reload() async {
    setState(() {
      _future = IncidenteHistorial.fetch(widget.incidente.id);
    });
    await _future;
  }

  Future<void> _addComment() async {
    if (_comentarioCtrl.text.trim().isEmpty) {
      return;
    }
    await IncidenteHistorial.add(
      incidenteId: widget.incidente.id,
      comentario: _comentarioCtrl.text.trim(),
      estado: _estado,
    );
    _comentarioCtrl.clear();
    setState(() => _estado = null);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              title: Text(widget.incidente.titulo),
              subtitle: Text(widget.incidente.descripcion ?? ''),
              trailing: Chip(label: Text(widget.incidente.estado)),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _comentarioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Agregar comentario',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _estado,
                    decoration:
                        const InputDecoration(labelText: 'Actualizar estado'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin cambio'),
                      ),
                      ...kIncidenteEstados.map(
                        (String item) => DropdownMenuItem<String?>(
                          value: item,
                          child: Text(item),
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      setState(() => _estado = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addComment,
                      child: const Text('Guardar nota'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<IncidenteHistorial>>(
                future: _future,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<IncidenteHistorial>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<IncidenteHistorial> data =
                      snapshot.data ?? <IncidenteHistorial>[];
                  if (data.isEmpty) {
                    return const Center(
                      child: Text('Sin comentarios todavía.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (BuildContext context, int index) {
                      final IncidenteHistorial item = data[index];
                      return ListTile(
                        title: Text(item.comentario ?? '-'),
                        subtitle: Text(
                          '${item.estado ?? ''} · '
                          '${item.registradoAt == null ? '' : item.registradoAt!.toLocal().toString().substring(0, 16)}',
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemCount: data.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
