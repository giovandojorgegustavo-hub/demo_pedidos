import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/contabilidad_balance_general.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class ContabilidadBalanceGeneralView extends StatefulWidget {
  const ContabilidadBalanceGeneralView({super.key});

  @override
  State<ContabilidadBalanceGeneralView> createState() =>
      _ContabilidadBalanceGeneralViewState();
}

class _ContabilidadBalanceGeneralViewState
    extends State<ContabilidadBalanceGeneralView> {
  late Future<List<ContabilidadBalanceGeneral>> _future = _load();
  DateTimeRange? _dateRange;
  String? _tipoFilter;

  final List<MapEntry<String, String>> _tipos = <MapEntry<String, String>>[
    const MapEntry<String, String>('activo', 'Activo'),
    const MapEntry<String, String>('pasivo', 'Pasivo'),
    const MapEntry<String, String>('patrimonio', 'Patrimonio'),
  ];

  Future<List<ContabilidadBalanceGeneral>> _load() {
    return ContabilidadBalanceGeneral.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      tipo: _tipoFilter,
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
      title: 'Balance general',
      currentSection: AppSection.contabilidadBalanceGeneral,
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
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text(_dateRangeLabel()),
                ),
                DropdownButton<String?>(
                  value: _tipoFilter,
                  hint: const Text('Tipo'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ..._tipos.map(
                      (MapEntry<String, String> entry) =>
                          DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: (String? value) async {
                    setState(() {
                      _tipoFilter = value;
                    });
                    await _reload();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ContabilidadBalanceGeneral>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ContabilidadBalanceGeneral>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('No se pudo cargar el balance general.'),
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
                final List<ContabilidadBalanceGeneral> data =
                    snapshot.data ?? <ContabilidadBalanceGeneral>[];
                if (data.isEmpty) {
                  return const Center(
                    child: Text('Sin datos para los filtros seleccionados.'),
                  );
                }
                return TableSection<ContabilidadBalanceGeneral>(
                  items: data,
                  columns: _columns,
                  minTableWidth: 700,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<ContabilidadBalanceGeneral>> get _columns {
    return <TableColumnConfig<ContabilidadBalanceGeneral>>[
      TableColumnConfig<ContabilidadBalanceGeneral>(
        label: 'Periodo',
        sortAccessor: (ContabilidadBalanceGeneral item) => item.periodo,
        cellBuilder: (ContabilidadBalanceGeneral item) =>
            Text(_formatPeriod(item.periodo)),
      ),
      TableColumnConfig<ContabilidadBalanceGeneral>(
        label: 'Tipo',
        sortAccessor: (ContabilidadBalanceGeneral item) => item.tipo,
        cellBuilder: (ContabilidadBalanceGeneral item) =>
            Text(_tipoLabel(item.tipo)),
      ),
      TableColumnConfig<ContabilidadBalanceGeneral>(
        label: 'Saldo',
        isNumeric: true,
        sortAccessor: (ContabilidadBalanceGeneral item) => item.saldo,
        cellBuilder: (ContabilidadBalanceGeneral item) =>
            Text('S/ ${item.saldo.toStringAsFixed(2)}'),
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

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'activo':
        return 'Activo';
      case 'pasivo':
        return 'Pasivo';
      case 'patrimonio':
        return 'Patrimonio';
      default:
        return tipo;
    }
  }
}
