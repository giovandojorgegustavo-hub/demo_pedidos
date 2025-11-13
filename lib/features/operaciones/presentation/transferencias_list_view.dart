import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/operaciones/presentation/transferencias_form_view.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/transferencia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class TransferenciasListView extends StatefulWidget {
  const TransferenciasListView({super.key});

  @override
  State<TransferenciasListView> createState() =>
      _TransferenciasListViewState();
}

class _TransferenciasListViewState extends State<TransferenciasListView> {
  late Future<List<_TransferenciaRow>> _future = _load();

  Future<List<_TransferenciaRow>> _load() async {
    final List<Transferencia> transferencias =
        await Transferencia.fetchAll();
    final List<LogisticaBase> bases = await LogisticaBase.getBases();
    final Map<String, String> baseNames = <String, String>{
      for (final LogisticaBase base in bases) base.id: base.nombre,
    };
    return transferencias.map((Transferencia t) {
      final String origen = baseNames[t.idbaseOrigen] ?? 'Base origen';
      final String destino = baseNames[t.idbaseDestino] ?? 'Base destino';
      return _TransferenciaRow(
        transferencia: t,
        baseOrigen: origen,
        baseDestino: destino,
      );
    }).toList(growable: false);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openForm({Transferencia? transferencia}) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => TransferenciasFormView(transferencia: transferencia),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Transferencias',
      currentSection: AppSection.operacionesTransferencias,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          tooltip: 'Actualizar',
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: () => _openForm(),
          tooltip: 'Nueva transferencia',
          icon: const Icon(Icons.add_home_work_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        tooltip: 'Registrar transferencia',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<_TransferenciaRow>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<_TransferenciaRow>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('No se pudieron cargar las transferencias.'),
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
          final List<_TransferenciaRow> rows = snapshot.data ?? <_TransferenciaRow>[];
          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Aún no registras transferencias.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openForm(),
                    child: const Text('Registrar transferencia'),
                  ),
                ],
              ),
            );
          }
          return TableSection<_TransferenciaRow>(
            items: rows,
            columns: <TableColumnConfig<_TransferenciaRow>>[
              TableColumnConfig<_TransferenciaRow>(
                label: 'Fecha',
                sortAccessor: (_TransferenciaRow row) =>
                    row.transferencia.registradoAt ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                cellBuilder: (_TransferenciaRow row) =>
                    Text(_formatDate(row.transferencia.registradoAt)),
              ),
              TableColumnConfig<_TransferenciaRow>(
                label: 'Origen',
                sortAccessor: (_TransferenciaRow row) => row.baseOrigen,
                cellBuilder: (_TransferenciaRow row) => Text(row.baseOrigen),
              ),
              TableColumnConfig<_TransferenciaRow>(
                label: 'Destino',
                sortAccessor: (_TransferenciaRow row) => row.baseDestino,
                cellBuilder: (_TransferenciaRow row) => Text(row.baseDestino),
              ),
              TableColumnConfig<_TransferenciaRow>(
                label: 'Observación',
                sortAccessor: (_TransferenciaRow row) =>
                    row.transferencia.observacion ?? '',
                cellBuilder: (_TransferenciaRow row) =>
                    Text(row.transferencia.observacion ?? '-'),
              ),
            ],
            onRowTap: (_TransferenciaRow row) =>
                _openForm(transferencia: row.transferencia),
            onRefresh: _reload,
            searchPlaceholder: 'Buscar por base u observación',
            searchTextBuilder: (_TransferenciaRow row) =>
                '${row.baseOrigen} ${row.baseDestino} '
                '${row.transferencia.observacion ?? ''}',
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

class _TransferenciaRow {
  const _TransferenciaRow({
    required this.transferencia,
    required this.baseOrigen,
    required this.baseDestino,
  });

  final Transferencia transferencia;
  final String baseOrigen;
  final String baseDestino;
}
