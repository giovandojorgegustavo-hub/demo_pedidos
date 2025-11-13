import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/models/reporte_ganancia.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ReportesGananciaClientesView extends StatefulWidget {
  const ReportesGananciaClientesView({super.key});

  @override
  State<ReportesGananciaClientesView> createState() =>
      _ReportesGananciaClientesViewState();
}

class _ReportesGananciaClientesViewState
    extends State<ReportesGananciaClientesView> {
  DateTimeRange? _dateRange;
  String? _clienteId;
  late Future<List<ReporteGananciaClienteMensual>> _future = _load();
  List<Cliente> _clientes = <Cliente>[];

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    final List<Cliente> clientes = await Cliente.getClientes();
    if (!mounted) {
      return;
    }
    setState(() {
      _clientes = clientes;
    });
  }

  Future<List<ReporteGananciaClienteMensual>> _load() {
    return ReporteGananciaClienteMensual.fetch(
      from: _dateRange?.start,
      to: _dateRange?.end,
      clienteId: _clienteId,
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
      title: 'Ganancia por cliente',
      currentSection: AppSection.reportesGananciaClientes,
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
                  width: 260,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _clienteId,
                    decoration: const InputDecoration(labelText: 'Cliente'),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todos'),
                      ),
                      ..._clientes.map(
                        (Cliente cliente) => DropdownMenuItem<String?>(
                          value: cliente.id,
                          child: Text(cliente.nombre),
                        ),
                      ),
                    ],
                    onChanged: (String? value) async {
                      setState(() => _clienteId = value);
                      await _reload();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ReporteGananciaClienteMensual>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ReporteGananciaClienteMensual>> snapshot,
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
                final List<ReporteGananciaClienteMensual> data =
                    snapshot.data ?? <ReporteGananciaClienteMensual>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para los filtros actuales.'),
                  );
                }
                return TableSection<ReporteGananciaClienteMensual>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 1000,
                  searchPlaceholder: 'Buscar por cliente',
                  searchTextBuilder: (ReporteGananciaClienteMensual item) =>
                      '${_formatMonth(item.periodo)} ${item.clienteNombre ?? ''}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ReporteGananciaClienteMensual>> get _columns {
    return <TableColumnConfig<ReporteGananciaClienteMensual>>[
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Periodo',
        sortAccessor: (ReporteGananciaClienteMensual item) => item.periodo,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(_formatMonth(item.periodo)),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Cliente',
        sortAccessor: (ReporteGananciaClienteMensual item) =>
            item.clienteNombre ?? '',
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(item.clienteNombre ?? '-'),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Pedidos',
        isNumeric: true,
        sortAccessor: (ReporteGananciaClienteMensual item) => item.pedidos,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(item.pedidos.toString()),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Venta',
        isNumeric: true,
        sortAccessor: (ReporteGananciaClienteMensual item) => item.totalVenta,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(_formatCurrency(item.totalVenta)),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Costo',
        isNumeric: true,
        sortAccessor: (ReporteGananciaClienteMensual item) => item.totalCosto,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(_formatCurrency(item.totalCosto)),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Ganancia',
        isNumeric: true,
        sortAccessor: (ReporteGananciaClienteMensual item) => item.ganancia,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
            Text(_formatCurrency(item.ganancia)),
      ),
      TableColumnConfig<ReporteGananciaClienteMensual>(
        label: 'Margen %',
        isNumeric: true,
        sortAccessor: (ReporteGananciaClienteMensual item) => item.margen,
        cellBuilder: (ReporteGananciaClienteMensual item) =>
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
