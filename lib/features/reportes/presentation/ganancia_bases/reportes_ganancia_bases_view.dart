import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/reporte_ganancia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ReportesGananciaBasesView extends StatefulWidget {
  const ReportesGananciaBasesView({super.key});

  @override
  State<ReportesGananciaBasesView> createState() =>
      _ReportesGananciaBasesViewState();
}

class _ReportesGananciaBasesViewState extends State<ReportesGananciaBasesView> {
  DateTimeRange? _dateRange;
  String? _baseId;
  late Future<List<ReporteGananciaBaseMensual>> _future = _load();
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
    setState(() {
      _bases = bases;
    });
  }

  Future<List<ReporteGananciaBaseMensual>> _load() {
    return ReporteGananciaBaseMensual.fetch(
      from: _dateRange?.start,
      to: _dateRange?.end,
      baseId: _baseId,
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
      title: 'Ganancia por base',
      currentSection: AppSection.reportesGananciaBases,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  _dateRange == null
                      ? 'Últimos 12 meses'
                      : '${_formatDate(_dateRange!.start)} · ${_formatDate(_dateRange!.end)}',
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _baseId,
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
                      setState(() => _baseId = value);
                      await _reload();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReporteGananciaBaseMensual>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ReporteGananciaBaseMensual>> snapshot,
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
                final List<ReporteGananciaBaseMensual> data =
                    snapshot.data ?? <ReporteGananciaBaseMensual>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para los filtros actuales.'),
                  );
                }
                return TableSection<ReporteGananciaBaseMensual>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  searchPlaceholder: 'Buscar por base',
                  searchTextBuilder: (ReporteGananciaBaseMensual item) =>
                      '${_formatMonth(item.periodo)} ${item.baseNombre ?? ''}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ReporteGananciaBaseMensual>> get _columns {
    return <TableColumnConfig<ReporteGananciaBaseMensual>>[
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Periodo',
        sortAccessor: (ReporteGananciaBaseMensual item) => item.periodo,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(_formatMonth(item.periodo)),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Base',
        sortAccessor: (ReporteGananciaBaseMensual item) =>
            item.baseNombre ?? '',
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(item.baseNombre ?? '-'),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Pedidos',
        isNumeric: true,
        sortAccessor: (ReporteGananciaBaseMensual item) => item.pedidos,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(item.pedidos.toString()),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Venta',
        isNumeric: true,
        sortAccessor: (ReporteGananciaBaseMensual item) => item.totalVenta,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(_formatCurrency(item.totalVenta)),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Costo',
        isNumeric: true,
        sortAccessor: (ReporteGananciaBaseMensual item) => item.totalCosto,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(_formatCurrency(item.totalCosto)),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Ganancia',
        isNumeric: true,
        sortAccessor: (ReporteGananciaBaseMensual item) => item.ganancia,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text(_formatCurrency(item.ganancia)),
      ),
      TableColumnConfig<ReporteGananciaBaseMensual>(
        label: 'Margen %',
        isNumeric: true,
        sortAccessor: (ReporteGananciaBaseMensual item) => item.margen,
        cellBuilder: (ReporteGananciaBaseMensual item) =>
            Text('${item.margen.toStringAsFixed(2)} %'),
      ),
    ];
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
