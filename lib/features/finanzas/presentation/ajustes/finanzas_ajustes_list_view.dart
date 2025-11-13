import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/finanzas/presentation/ajustes/finanzas_ajuste_form_view.dart';
import 'package:demo_pedidos/models/cuenta_bancaria.dart';
import 'package:demo_pedidos/models/cuenta_contable.dart';
import 'package:demo_pedidos/models/finanzas_ajuste.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class FinanzasAjustesListView extends StatefulWidget {
  const FinanzasAjustesListView({super.key});

  @override
  State<FinanzasAjustesListView> createState() =>
      _FinanzasAjustesListViewState();
}

class _FinanzasAjustesListViewState extends State<FinanzasAjustesListView> {
  late Future<List<FinanzasAjuste>> _future = _load();
  DateTimeRange? _dateRange;
  String? _cuentaFilter;
  String? _cuentaContableFilter;
  List<CuentaBancaria> _cuentas = <CuentaBancaria>[];
  List<CuentaContable> _cuentasContables = <CuentaContable>[];
  Future<void>? _catalogosFuture;

  @override
  void initState() {
    super.initState();
    _catalogosFuture = _loadCatalogos();
  }

  Future<void> _loadCatalogos() async {
    final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
      CuentaBancaria.getCuentas(),
      CuentaContable.fetchTerminales(),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cuentas = results[0] as List<CuentaBancaria>;
      _cuentasContables = results[1] as List<CuentaContable>;
    });
  }

  Future<List<FinanzasAjuste>> _load() {
    return FinanzasAjuste.fetchAll(
      from: _dateRange?.start,
      to: _dateRange?.end,
      cuentaId: _cuentaFilter,
      cuentaContableId: _cuentaContableFilter,
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
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      await _reload();
    }
  }

  Future<void> _openForm({FinanzasAjuste? ajuste}) async {
    await _catalogosFuture;
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => FinanzasAjusteFormView(
          ajuste: ajuste,
          cuentas: _cuentas,
          cuentasContables: _cuentasContables,
        ),
      ),
    );
    if (changed == true) {
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Ajustes de bancos',
      currentSection: AppSection.finanzasAjustes,
      actions: <Widget>[
        IconButton(
          tooltip: 'Filtrar por fecha',
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range_outlined),
        ),
        IconButton(
          tooltip: 'Actualizar',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.tune_outlined),
      ),
      body: Column(
        children: <Widget>[
          _Filters(
            dateLabel: _dateRangeLabel(),
            onDateTap: _selectDateRange,
            cuentaFilter: _cuentaFilter,
            cuentaContableFilter: _cuentaContableFilter,
            onCuentaChanged: (String? value) async {
              setState(() {
                _cuentaFilter = value;
              });
              await _reload();
            },
            onCuentaContableChanged: (String? value) async {
              setState(() {
                _cuentaContableFilter = value;
              });
              await _reload();
            },
            cuentas: _cuentas,
            cuentasContables: _cuentasContables,
            catalogosFuture: _catalogosFuture,
          ),
          Expanded(
            child: FutureBuilder<List<FinanzasAjuste>>(
              future: _future,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<FinanzasAjuste>> snapshot,
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
                final List<FinanzasAjuste> data =
                    snapshot.data ?? <FinanzasAjuste>[];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin ajustes registrados.'));
                }
                return TableSection<FinanzasAjuste>(
                  items: data,
                  columns: _columns,
                  searchPlaceholder: 'Buscar por descripción o cuentas',
                  searchTextBuilder: (FinanzasAjuste ajuste) =>
                      '${ajuste.descripcion} ${ajuste.cuentaBancariaNombre ?? ''} ${ajuste.cuentaContableNombre ?? ''}',
                  minTableWidth: 1000,
                  onRowTap: (FinanzasAjuste ajuste) =>
                      _openForm(ajuste: ajuste),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TableColumnConfig<FinanzasAjuste>> get _columns {
    return <TableColumnConfig<FinanzasAjuste>>[
      TableColumnConfig<FinanzasAjuste>(
        label: 'Fecha',
        sortAccessor: (FinanzasAjuste ajuste) =>
            ajuste.registradoAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        cellBuilder: (FinanzasAjuste ajuste) =>
            Text(_formatDate(ajuste.registradoAt)),
      ),
      TableColumnConfig<FinanzasAjuste>(
        label: 'Descripción',
        sortAccessor: (FinanzasAjuste ajuste) => ajuste.descripcion,
        cellBuilder: (FinanzasAjuste ajuste) => Text(ajuste.descripcion),
      ),
      TableColumnConfig<FinanzasAjuste>(
        label: 'Cuenta bancaria',
        sortAccessor: (FinanzasAjuste ajuste) =>
            ajuste.cuentaBancariaNombre ?? '',
        cellBuilder: (FinanzasAjuste ajuste) =>
            Text(ajuste.cuentaBancariaNombre ?? 'Sin cuenta'),
      ),
      TableColumnConfig<FinanzasAjuste>(
        label: 'Cuenta contable',
        sortAccessor: (FinanzasAjuste ajuste) =>
            ajuste.cuentaContableCodigo ?? '',
        cellBuilder: (FinanzasAjuste ajuste) =>
            ajuste.cuentaContableNombre == null
                ? const Text('-')
                : Text(
                    '${ajuste.cuentaContableCodigo ?? ''} · ${ajuste.cuentaContableNombre}',
                  ),
      ),
      TableColumnConfig<FinanzasAjuste>(
        label: 'Monto',
        isNumeric: true,
        sortAccessor: (FinanzasAjuste ajuste) => ajuste.monto,
        cellBuilder: (FinanzasAjuste ajuste) =>
            Text('S/ ${ajuste.monto.toStringAsFixed(2)}'),
      ),
      TableColumnConfig<FinanzasAjuste>(
        label: 'Registrado por',
        sortAccessor: (FinanzasAjuste ajuste) =>
            ajuste.registradoPor ?? '',
        cellBuilder: (FinanzasAjuste ajuste) =>
            Text(ajuste.registradoPor ?? '-'),
      ),
    ];
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Rango de fechas';
    }
    final DateTime start = _dateRange!.start;
    final DateTime end = _dateRange!.end;
    return '${_formatDate(start)} · ${_formatDate(end)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }
    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();
    return '$day/$month/$year';
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.dateLabel,
    required this.onDateTap,
    required this.cuentaFilter,
    required this.cuentaContableFilter,
    required this.onCuentaChanged,
    required this.onCuentaContableChanged,
    required this.cuentas,
    required this.cuentasContables,
    this.catalogosFuture,
  });

  final String dateLabel;
  final VoidCallback onDateTap;
  final String? cuentaFilter;
  final String? cuentaContableFilter;
  final ValueChanged<String?> onCuentaChanged;
  final ValueChanged<String?> onCuentaContableChanged;
  final List<CuentaBancaria> cuentas;
  final List<CuentaContable> cuentasContables;
  final Future<void>? catalogosFuture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: onDateTap,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(dateLabel),
          ),
          SizedBox(
            width: 220,
            child: FutureBuilder<void>(
              future: catalogosFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>('aj-cuenta-${cuentaFilter ?? 'all'}'),
                  initialValue: cuentaFilter,
                  decoration: const InputDecoration(labelText: 'Cuenta bancaria'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...cuentas.map(
                      (CuentaBancaria cuenta) => DropdownMenuItem<String?>(
                        value: cuenta.id,
                        child: Text(cuenta.nombre),
                      ),
                    ),
                  ],
                  onChanged: onCuentaChanged,
                );
              },
            ),
          ),
          SizedBox(
            width: 240,
            child: FutureBuilder<void>(
              future: catalogosFuture,
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return DropdownButtonFormField<String?>(
                  key: ValueKey<String>(
                      'aj-contable-${cuentaContableFilter ?? 'all'}'),
                  initialValue: cuentaContableFilter,
                  decoration:
                      const InputDecoration(labelText: 'Cuenta contable'),
                  items: <DropdownMenuItem<String?>>[
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...cuentasContables.map(
                      (CuentaContable cuenta) => DropdownMenuItem<String?>(
                        value: cuenta.id,
                        child: Text('${cuenta.codigo} · ${cuenta.nombre}'),
                      ),
                    ),
                  ],
                  onChanged: onCuentaContableChanged,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
