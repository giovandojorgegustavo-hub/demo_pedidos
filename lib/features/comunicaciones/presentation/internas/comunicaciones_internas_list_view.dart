import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/comunicaciones/presentation/internas/comunicaciones_interna_form_view.dart';
import 'package:demo_pedidos/models/comunicacion_interna.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ComunicacionesInternasListView extends StatefulWidget {
  const ComunicacionesInternasListView({super.key});

  @override
  State<ComunicacionesInternasListView> createState() =>
      _ComunicacionesInternasListViewState();
}

class _ComunicacionesInternasListViewState
    extends State<ComunicacionesInternasListView> {
  String? _estadoFilter;
  String? _prioridadFilter;
  String? _baseFilter;
  late Future<List<ComunicacionInterna>> _future = _load();
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

  Future<List<ComunicacionInterna>> _load() {
    return ComunicacionInterna.fetchAll(
      estado: _estadoFilter,
      baseId: _baseFilter,
      prioridad: _prioridadFilter,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openForm({ComunicacionInterna? comunicacion}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ComunicacionesInternaFormView(
          comunicacion: comunicacion,
        ),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openThread(ComunicacionInterna comunicacion) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _ComunicacionDetalleSheet(
          comunicacion: comunicacion,
          onUpdated: _reload,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Comunicaciones internas',
      currentSection: AppSection.comunicacionesInternas,
      actions: <Widget>[
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add_comment),
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
                      ...kComunicacionEstados.map(
                        (String estado) => DropdownMenuItem<String?>(
                          value: estado,
                          child: Text(estado),
                        ),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _estadoFilter = value);
                      await _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Prioridad'),
                    initialValue: _prioridadFilter,
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...kComunicacionPrioridades.map(
                        (String prioridad) => DropdownMenuItem<String?>(
                          value: prioridad,
                          child: Text(prioridad),
                        ),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _prioridadFilter = value);
                      await _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String?>(
                    decoration: const InputDecoration(labelText: 'Base'),
                    initialValue: _baseFilter,
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
            child: FutureBuilder<List<ComunicacionInterna>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ComunicacionInterna>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text(
                          'No se pudieron cargar las comunicaciones.',
                        ),
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
                final List<ComunicacionInterna> data =
                    snapshot.data ?? <ComunicacionInterna>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin comunicaciones registradas.'),
                  );
                }
                return TableSection<ComunicacionInterna>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  searchPlaceholder: 'Buscar por asunto o base',
                  searchTextBuilder: (ComunicacionInterna item) =>
                      '${item.asunto} ${item.baseNombre ?? ''} ${item.mensaje}',
                  onRowTap: (ComunicacionInterna item) =>
                      _openForm(comunicacion: item),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ComunicacionInterna>> get _columns {
    return <TableColumnConfig<ComunicacionInterna>>[
      TableColumnConfig<ComunicacionInterna>(
        label: 'Fecha',
        sortAccessor: (ComunicacionInterna item) =>
            item.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (ComunicacionInterna item) => Text(
          item.registradoAt == null
              ? '-'
              : _formatDate(item.registradoAt!),
        ),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Base',
        sortAccessor: (ComunicacionInterna item) => item.baseNombre ?? '',
        cellBuilder: (ComunicacionInterna item) =>
            Text(item.baseNombre ?? '-'),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Asunto',
        sortAccessor: (ComunicacionInterna item) => item.asunto,
        cellBuilder: (ComunicacionInterna item) => Text(item.asunto),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Mensaje',
        cellBuilder: (ComunicacionInterna item) => Text(
          item.mensaje,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Prioridad',
        sortAccessor: (ComunicacionInterna item) => item.prioridad,
        cellBuilder: (ComunicacionInterna item) => Chip(
          label: Text(item.prioridad),
          backgroundColor: _prioridadColor(item.prioridad),
        ),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Estado',
        sortAccessor: (ComunicacionInterna item) => item.estado,
        cellBuilder: (ComunicacionInterna item) => Chip(
          label: Text(item.estado),
          backgroundColor: _estadoColor(item.estado),
        ),
      ),
      TableColumnConfig<ComunicacionInterna>(
        label: 'Respuestas',
        cellBuilder: (ComunicacionInterna item) => IconButton(
          tooltip: 'Ver seguimiento',
          icon: const Icon(Icons.mark_chat_read_outlined),
          onPressed: () => _openThread(item),
        ),
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _prioridadColor(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return Colors.red.shade100;
      case 'baja':
        return Colors.green.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'atendido':
      case 'cerrado':
        return Colors.green.shade100;
      case 'en_proceso':
        return Colors.orange.shade100;
      default:
        return Colors.red.shade100;
    }
  }
}

class _ComunicacionDetalleSheet extends StatefulWidget {
  const _ComunicacionDetalleSheet({
    required this.comunicacion,
    this.onUpdated,
  });

  final ComunicacionInterna comunicacion;
  final Future<void> Function()? onUpdated;

  @override
  State<_ComunicacionDetalleSheet> createState() =>
      _ComunicacionDetalleSheetState();
}

class _ComunicacionDetalleSheetState
    extends State<_ComunicacionDetalleSheet> {
  late Future<List<ComunicacionRespuesta>> _future =
      ComunicacionRespuesta.fetch(widget.comunicacion.id);
  final TextEditingController _mensajeCtrl = TextEditingController();
  late String _estadoSeleccionado;
  late String _estadoPersistido;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _estadoPersistido = widget.comunicacion.estado;
    _estadoSeleccionado = _estadoPersistido;
  }

  @override
  void dispose() {
    _mensajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _future = ComunicacionRespuesta.fetch(widget.comunicacion.id);
    });
    await _future;
  }

  Future<void> _saveChanges() async {
    if (_isSaving) {
      return;
    }
    final String trimmed = _mensajeCtrl.text.trim();
    final bool estadoCambio = _estadoSeleccionado != _estadoPersistido;
    if (trimmed.isEmpty && !estadoCambio) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (estadoCambio) {
        await ComunicacionInterna.update(
          widget.comunicacion.id,
          <String, dynamic>{'estado': _estadoSeleccionado},
        );
        setState(() {
          _estadoPersistido = _estadoSeleccionado;
        });
        if (widget.onUpdated != null) {
          await widget.onUpdated!();
        }
      }
      if (trimmed.isNotEmpty) {
        await ComunicacionRespuesta.create(
          comunicacionId: widget.comunicacion.id,
          mensaje: trimmed,
        );
        _mensajeCtrl.clear();
        await _reload();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.85;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            children: <Widget>[
            ListTile(
              title: Text(widget.comunicacion.asunto),
              subtitle: Text(widget.comunicacion.baseNombre ?? 'Sin base'),
              trailing: Chip(label: Text(_estadoPersistido)),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _estadoSeleccionado,
                    decoration:
                        const InputDecoration(labelText: 'Actualizar estado'),
                    items: kComunicacionEstados
                        .map(
                          (String estado) => DropdownMenuItem<String>(
                            value: estado,
                            child: Text(estado),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _estadoSeleccionado = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mensajeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Agregar respuesta',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveChanges,
                      icon: const Icon(Icons.send),
                      label: const Text('Guardar cambios'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<List<ComunicacionRespuesta>>(
                future: _future,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<ComunicacionRespuesta>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final List<ComunicacionRespuesta> data =
                      snapshot.data ?? <ComunicacionRespuesta>[];
                  if (data.isEmpty) {
                    return const Center(
                      child: Text('Sin respuestas todavía.'),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (BuildContext context, int index) {
                      final ComunicacionRespuesta item = data[index];
                      return ListTile(
                        title: Text(item.mensaje),
                        subtitle: Text(
                          item.registradoAt == null
                              ? '-'
                              : item.registradoAt!
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16),
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
    ),
  );
  }
}
