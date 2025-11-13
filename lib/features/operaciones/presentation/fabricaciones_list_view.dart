import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/operaciones/presentation/fabricaciones_form_view.dart';
import 'package:demo_pedidos/models/fabricacion.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FabricacionesListView extends StatefulWidget {
  const FabricacionesListView({super.key});

  @override
  State<FabricacionesListView> createState() => _FabricacionesListViewState();
}

class _FabricacionesListViewState extends State<FabricacionesListView> {
  late Future<List<_FabricacionRow>> _future = _load();

  Future<List<_FabricacionRow>> _load() async {
    final List<Fabricacion> fabricaciones = await Fabricacion.fetchAll();
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    final Map<String, String> baseNames = <String, String>{
      for (final LogisticaBase base in bases) base.id: base.nombre,
    };
    return fabricaciones
        .map(
          (Fabricacion fabricacion) => _FabricacionRow(
            fabricacion: fabricacion,
            baseNombre: baseNames[fabricacion.idbase] ?? 'Base',
          ),
        )
        .toList(growable: false);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openForm({Fabricacion? fabricacion}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => FabricacionesFormView(fabricacion: fabricacion),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Fabricaciones',
      currentSection: AppSection.operacionesFabricacion,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () => _openForm(),
          tooltip: 'Nueva fabricación',
          icon: const Icon(Icons.factory_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Registrar fabricación',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<_FabricacionRow>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<_FabricacionRow>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudieron cargar las fabricaciones.'),
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
          final List<_FabricacionRow> rows =
              snapshot.data ?? <_FabricacionRow>[];
          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras fabricaciones.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Registrar fabricación'),
                  ),
                ],
              ),
            );
          }
          return TableSection<_FabricacionRow>(
            items: rows,
            columns: <TableColumnConfig<_FabricacionRow>>[
              TableColumnConfig<_FabricacionRow>(
                label: 'Fecha',
                sortAccessor: (_FabricacionRow row) =>
                    row.fabricacion.registradoAt ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                cellBuilder: (_FabricacionRow row) =>
                    Text(_formatDate(row.fabricacion.registradoAt)),
              ),
              TableColumnConfig<_FabricacionRow>(
                label: 'Base',
                sortAccessor: (_FabricacionRow row) => row.baseNombre,
                cellBuilder: (_FabricacionRow row) => Text(row.baseNombre),
              ),
              TableColumnConfig<_FabricacionRow>(
                label: 'Observación',
                sortAccessor: (_FabricacionRow row) =>
                    row.fabricacion.observacion ?? '',
                cellBuilder: (_FabricacionRow row) =>
                    Text(row.fabricacion.observacion ?? '-'),
              ),
            ],
            onRowTap: (_FabricacionRow row) =>
                _openForm(fabricacion: row.fabricacion),
            onRefresh: _reload,
            searchPlaceholder: 'Buscar por base u observación',
            searchTextBuilder: (_FabricacionRow row) =>
                '${row.baseNombre} ${row.fabricacion.observacion ?? ''}',
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
  }
}

class _FabricacionRow {
  const _FabricacionRow({required this.fabricacion, required this.baseNombre});

  final Fabricacion fabricacion;
  final String baseNombre;
}
