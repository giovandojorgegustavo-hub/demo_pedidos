import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/reporte_ganancia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ReportesGananciaMensualView extends StatefulWidget {
  const ReportesGananciaMensualView({super.key});

  @override
  State<ReportesGananciaMensualView> createState() =>
      _ReportesGananciaMensualViewState();
}

class _ReportesGananciaMensualViewState
    extends State<ReportesGananciaMensualView> {
  DateTimeRange? _dateRange;
  late Future<List<ReporteGananciaMensual>> _future = _load();

  Future<List<ReporteGananciaMensual>> _load() {
    return ReporteGananciaMensual.fetch(
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
          end: now,
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3, 1, 1),
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
      title: 'Ganancia mensual',
      currentSection: AppSection.reportesGananciaMensual,
      actions: <Widget>[
        IconButton(
          tooltip: 'Rango de fechas',
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
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                _dateRange == null
                    ? 'Últimos 12 meses'
                    : '${_formatDate(_dateRange!.start)} · ${_formatDate(_dateRange!.end)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReporteGananciaMensual>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ReporteGananciaMensual>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ErrorState(
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                final List<ReporteGananciaMensual> data =
                    snapshot.data ?? <ReporteGananciaMensual>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para el rango seleccionado.'),
                  );
                }
                return Column(
                  children: <Widget>[
                    _SummaryRow(
                      totalVenta: _sum(data,
                          (ReporteGananciaMensual item) => item.totalVenta),
                      totalCosto: _sum(data,
                          (ReporteGananciaMensual item) => item.totalCosto),
                      totalGanancia: _sum(
                          data, (ReporteGananciaMensual item) => item.ganancia),
                    ),
                    Expanded(
                      child: TableSection<ReporteGananciaMensual>(
                        items: data,
                        columns: _columns,
                        minTableWidth: 900,
                        searchPlaceholder: 'Buscar por mes',
                        searchTextBuilder: (ReporteGananciaMensual item) =>
                            _formatMonth(item.periodo),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ReporteGananciaMensual>> get _columns {
    return <TableColumnConfig<ReporteGananciaMensual>>[
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Periodo',
        sortAccessor: (ReporteGananciaMensual item) => item.periodo,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text(_formatMonth(item.periodo)),
      ),
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Pedidos',
        isNumeric: true,
        sortAccessor: (ReporteGananciaMensual item) => item.pedidos,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text(item.pedidos.toString()),
      ),
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Venta',
        isNumeric: true,
        sortAccessor: (ReporteGananciaMensual item) => item.totalVenta,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text(_formatCurrency(item.totalVenta)),
      ),
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Costo',
        isNumeric: true,
        sortAccessor: (ReporteGananciaMensual item) => item.totalCosto,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text(_formatCurrency(item.totalCosto)),
      ),
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Ganancia',
        isNumeric: true,
        sortAccessor: (ReporteGananciaMensual item) => item.ganancia,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text(_formatCurrency(item.ganancia)),
      ),
      TableColumnConfig<ReporteGananciaMensual>(
        label: 'Margen %',
        isNumeric: true,
        sortAccessor: (ReporteGananciaMensual item) => item.margen,
        cellBuilder: (ReporteGananciaMensual item) =>
            Text('${item.margen.toStringAsFixed(2)} %'),
      ),
    ];
  }

  double _sum(
    List<ReporteGananciaMensual> data,
    double Function(ReporteGananciaMensual item) selector,
  ) {
    return data.fold<double>(0, (double acc, ReporteGananciaMensual item) {
      return acc + selector(item);
    });
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.totalVenta,
    required this.totalCosto,
    required this.totalGanancia,
  });

  final double totalVenta;
  final double totalCosto;
  final double totalGanancia;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: <Widget>[
          _SummaryCard(
            label: 'Venta',
            value: _formatCurrency(totalVenta),
            icon: Icons.trending_up,
          ),
          _SummaryCard(
            label: 'Costo',
            value: _formatCurrency(totalCosto),
            icon: Icons.trending_down,
          ),
          _SummaryCard(
            label: 'Ganancia',
            value: _formatCurrency(totalGanancia),
            icon: Icons.ssid_chart_outlined,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text('No se pudo cargar la información.'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatMonth(DateTime date) {
  return '${_monthNames[date.month - 1]} ${date.year}';
}

String _formatCurrency(double value) {
  return 'S/ ${value.toStringAsFixed(2)}';
}

const List<String> _monthNames = <String>[
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
