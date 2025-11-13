import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/operaciones/presentation/ajustes_detail_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/ajustes_form_view.dart';
import 'package:demo_pedidos/models/ajuste.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

class AjustesListView extends StatefulWidget {
  const AjustesListView({super.key});

  @override
  State<AjustesListView> createState() => _AjustesListViewState();
}

class _AjustesListViewState extends State<AjustesListView> {
  late Future<List<_AjusteRow>> _future = _load();

  Future<List<_AjusteRow>> _load() async {
    final List<Ajuste> ajustes = await Ajuste.fetchAll();
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    final Map<String, String> baseNames = <String, String>{
      for (final LogisticaBase base in bases) base.id: base.nombre,
    };
    return ajustes
        .map(
          (Ajuste ajuste) => _AjusteRow(
            ajuste: ajuste,
            baseNombre: baseNames[ajuste.idbase] ?? 'Base',
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

  Future<void> _openForm({Ajuste? ajuste}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AjustesFormView(ajuste: ajuste),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  Future<void> _openDetail(_AjusteRow row) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AjustesDetailView(ajusteId: row.ajuste.id),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Ajustes de inventario',
      currentSection: AppSection.operacionesAjustes,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () => _openForm(),
          tooltip: 'Nuevo ajuste',
          icon: const Icon(Icons.add_chart_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Registrar ajuste',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<_AjusteRow>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<_AjusteRow>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudieron cargar los ajustes.'),
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
          final List<_AjusteRow> rows = snapshot.data ?? <_AjusteRow>[];
          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras ajustes.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Registrar ajuste'),
                  ),
                ],
              ),
            );
          }
          return TableSection<_AjusteRow>(
            items: rows,
            columns: <TableColumnConfig<_AjusteRow>>[
              TableColumnConfig<_AjusteRow>(
                label: 'Fecha',
                sortAccessor: (_AjusteRow row) =>
                    row.ajuste.registradoAt ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                cellBuilder: (_AjusteRow row) =>
                    Text(_formatDate(row.ajuste.registradoAt)),
              ),
              TableColumnConfig<_AjusteRow>(
                label: 'Base',
                sortAccessor: (_AjusteRow row) => row.baseNombre,
                cellBuilder: (_AjusteRow row) => Text(row.baseNombre),
              ),
              TableColumnConfig<_AjusteRow>(
                label: 'Observación',
                sortAccessor: (_AjusteRow row) =>
                    row.ajuste.observacion ?? '',
                cellBuilder: (_AjusteRow row) =>
                    Text(row.ajuste.observacion ?? '-'),
              ),
            ],
            onRowTap: _openDetail,
            onRefresh: _reload,
            searchPlaceholder: 'Buscar por base u observación',
            searchTextBuilder: (_AjusteRow row) =>
                '${row.baseNombre} ${row.ajuste.observacion ?? ''}',
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

class _AjusteRow {
  const _AjusteRow({required this.ajuste, required this.baseNombre});

  final Ajuste ajuste;
  final String baseNombre;
}
