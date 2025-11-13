import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/contabilidad_estado_resultados.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ContabilidadEstadoResultadosView extends StatefulWidget {
  const ContabilidadEstadoResultadosView({super.key});

  @override
  State<ContabilidadEstadoResultadosView> createState() =>
      _ContabilidadEstadoResultadosViewState();
}

class _ContabilidadEstadoResultadosViewState
    extends State<ContabilidadEstadoResultadosView> {
  late Future<List<ContabilidadEstadoResultados>> _future = _load();
  DateTimeRange? _dateRange;

  Future<List<ContabilidadEstadoResultados>> _load() {
    return ContabilidadEstadoResultados.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
    );
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange initialRange = _dateRange ??
        DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, now.month, 1),
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5, 1, 1),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Estado de resultados',
      currentSection: AppSection.contabilidadEstadoResultados,
      actions: <Widget>[
        IconButton(
          tooltip: 'Filtrar por fechas',
          onPressed: _selectDateRange,
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range_outlined),
                label: Text(_dateRangeLabel()),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ContabilidadEstadoResultados>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ContabilidadEstadoResultados>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudo cargar la información.'),
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
                final List<ContabilidadEstadoResultados> data =
                    snapshot.data ?? <ContabilidadEstadoResultados>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para los filtros seleccionados.'),
                  );
                }
                return TableSection<ContabilidadEstadoResultados>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 800,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ContabilidadEstadoResultados>> get _columns {
    return <TableColumnConfig<ContabilidadEstadoResultados>>[
      TableColumnConfig<ContabilidadEstadoResultados>(
        label: 'Periodo',
        sortAccessor: (ContabilidadEstadoResultados item) => item.periodo,
        cellBuilder: (ContabilidadEstadoResultados item) =>
            Text(_formatPeriod(item.periodo)),
      ),
      TableColumnConfig<ContabilidadEstadoResultados>(
        label: 'Ingresos',
        isNumeric: true,
        sortAccessor: (ContabilidadEstadoResultados item) =>
            item.totalIngresos,
        cellBuilder: (ContabilidadEstadoResultados item) =>
            Text('S/ ${item.totalIngresos.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<ContabilidadEstadoResultados>(
        label: 'Gastos',
        isNumeric: true,
        sortAccessor: (ContabilidadEstadoResultados item) =>
            item.totalGastos,
        cellBuilder: (ContabilidadEstadoResultados item) =>
            Text('S/ ${item.totalGastos.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<ContabilidadEstadoResultados>(
        label: 'Resultado',
        isNumeric: true,
        sortAccessor: (ContabilidadEstadoResultados item) =>
            item.resultado,
        cellBuilder: (ContabilidadEstadoResultados item) => Text(
          'S/ ${item.resultado.toStringAsFixed(2)}',
          style: TextStyle(
            color: item.resultado >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    ];
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Últimos 12 meses';
    }
    return '${_formatDate(_dateRange!.start)} · ${_formatDate(_dateRange!.end)}';
  }

  String _formatPeriod(DateTime date) {
    final List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '01/$month/$year';
  }
}
