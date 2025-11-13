import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/reporte_ganancia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ReportesGananciaDiariaView extends StatefulWidget {
  const ReportesGananciaDiariaView({super.key});

  @override
  State<ReportesGananciaDiariaView> createState() =>
      _ReportesGananciaDiariaViewState();
}

class _ReportesGananciaDiariaViewState
    extends State<ReportesGananciaDiariaView> {
  DateTimeRange? _dateRange;
  late Future<List<ReporteGananciaDiaria>> _future = _load();

  Future<List<ReporteGananciaDiaria>> _load() {
    return ReporteGananciaDiaria.fetch(
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
          start: now.subtract(const Duration(days: 14)),
          end: now,
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
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
      title: 'Ganancia diaria',
      currentSection: AppSection.reportesGananciaDiaria,
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
                    ? 'Últimos 15 días'
                    : '${_formatDate(_dateRange!.start)} · ${_formatDate(_dateRange!.end)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReporteGananciaDiaria>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ReporteGananciaDiaria>> snapshot,
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
                final List<ReporteGananciaDiaria> data =
                    snapshot.data ?? <ReporteGananciaDiaria>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para el rango seleccionado.'),
                  );
                }
                return Column(
                  children: <Widget>[
                    _SummaryRow(
                      totalVenta: _sum(data,
                          (ReporteGananciaDiaria item) => item.totalVenta),
                      totalCosto: _sum(data,
                          (ReporteGananciaDiaria item) => item.totalCosto),
                      totalGanancia: _sum(
                          data, (ReporteGananciaDiaria item) => item.ganancia),
                    ),
                    Expanded(
                      child: TableSection<ReporteGananciaDiaria>(
                        items: data,
                        columns: _columns,
                        minTableWidth: 900,
                        searchPlaceholder: 'Buscar por fecha',
                        searchTextBuilder: (ReporteGananciaDiaria item) =>
                            _formatDate(item.fecha),
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

  List<TableColumnConfig<ReporteGananciaDiaria>> get _columns {
    return <TableColumnConfig<ReporteGananciaDiaria>>[
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Fecha',
        sortAccessor: (ReporteGananciaDiaria item) => item.fecha,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text(_formatDate(item.fecha)),
      ),
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Pedidos',
        isNumeric: true,
        sortAccessor: (ReporteGananciaDiaria item) => item.pedidos,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text(item.pedidos.toString()),
      ),
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Venta',
        isNumeric: true,
        sortAccessor: (ReporteGananciaDiaria item) => item.totalVenta,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text(_formatCurrency(item.totalVenta)),
      ),
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Costo',
        isNumeric: true,
        sortAccessor: (ReporteGananciaDiaria item) => item.totalCosto,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text(_formatCurrency(item.totalCosto)),
      ),
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Ganancia',
        isNumeric: true,
        sortAccessor: (ReporteGananciaDiaria item) => item.ganancia,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text(_formatCurrency(item.ganancia)),
      ),
      TableColumnConfig<ReporteGananciaDiaria>(
        label: 'Margen %',
        isNumeric: true,
        sortAccessor: (ReporteGananciaDiaria item) => item.margen,
        cellBuilder: (ReporteGananciaDiaria item) =>
            Text('${item.margen.toStringAsFixed(2)} %'),
      ),
    ];
  }

  double _sum(
    List<ReporteGananciaDiaria> data,
    double Function(ReporteGananciaDiaria item) selector,
  ) {
    return data.fold<double>(0, (double acc, ReporteGananciaDiaria item) {
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

String _formatCurrency(double value) {
  return 'S/ ${value.toStringAsFixed(2)}';
}
