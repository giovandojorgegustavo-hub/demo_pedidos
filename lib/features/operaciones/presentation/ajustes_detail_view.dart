import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/operaciones/presentation/ajustes_form_view.dart';
import 'package:demo_pedidos/models/ajuste.dart';
import 'package:demo_pedidos/models/ajuste_detalle.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

class AjustesDetailView extends StatefulWidget {
  const AjustesDetailView({
    super.key,
    required this.ajusteId,
    this.currentSection = AppSection.operacionesAjustes,
  });

  final String ajusteId;
  final AppSection currentSection;

  @override
  State<AjustesDetailView> createState() => _AjustesDetailViewState();
}

class _AjustesDetailViewState extends State<AjustesDetailView> {
  late Future<void> _future = _load();
  Ajuste? _ajuste;
  String? _baseNombre;
  List<AjusteDetalle> _detalles = <AjusteDetalle>[];
  bool _hasChanges = false;

  Future<void> _load() async {
    final Ajuste? ajuste = await Ajuste.fetchById(widget.ajusteId);
    LogisticaBase? base;
    List<AjusteDetalle> detalles = <AjusteDetalle>[];
    if (ajuste != null) {
      base = await LogisticaBase.getById(ajuste.idbase);
      detalles = await AjusteDetalle.fetchByAjuste(ajuste.id);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _ajuste = ajuste;
      _baseNombre = base?.nombre;
      _detalles = detalles;
    });
  }

  Future<void> _reload() {
    final Future<void> future = _load();
    setState(() {
      _future = future;
    });
    return future;
  }

  Future<void> _edit() async {
    final Ajuste? ajuste = _ajuste;
    if (ajuste == null) {
      return;
    }
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AjustesFormView(ajuste: ajuste),
      ),
    );
    if (changed == true) {
      _hasChanges = true;
      await _reload();
    }
  }

  void _handlePop() {
    Navigator.pop(context, _hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic _) {
        if (didPop) {
          return;
        }
        _handlePop();
      },
      child: PageScaffold(
        title: 'Detalle de ajuste',
        currentSection: widget.currentSection,
        actions: <Widget>[
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
          IconButton(
            onPressed: _ajuste == null ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar',
          ),
        ],
        floatingActionButton: FloatingActionButton(
          onPressed: _ajuste == null ? null : _edit,
          tooltip: 'Editar ajuste',
          child: const Icon(Icons.edit),
        ),
        body: FutureBuilder<void>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_ajuste == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No se encontró este ajuste.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _handlePop,
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _summaryRow('Base', _baseNombre ?? '-'),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Fecha',
                          _formatDate(_ajuste?.registradoAt),
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          'Observación',
                          _ajuste?.observacion ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Movimientos registrados',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TableSection<AjusteDetalle>(
                          items: _detalles,
                          shrinkWrap: true,
                          columns: <TableColumnConfig<AjusteDetalle>>[
                            TableColumnConfig<AjusteDetalle>(
                              label: 'Producto',
                              sortAccessor: (AjusteDetalle detalle) =>
                                  detalle.productoNombre ?? '',
                              cellBuilder: (AjusteDetalle detalle) =>
                                  Text(detalle.productoNombre ?? '-'),
                            ),
                            TableColumnConfig<AjusteDetalle>(
                              label: 'Sistema',
                              isNumeric: true,
                              sortAccessor: (AjusteDetalle detalle) =>
                                  detalle.cantidadSistema ?? 0,
                              cellBuilder: (AjusteDetalle detalle) => Text(
                                _formatNumber(detalle.cantidadSistema),
                              ),
                            ),
                            TableColumnConfig<AjusteDetalle>(
                              label: 'Real',
                              isNumeric: true,
                              sortAccessor: (AjusteDetalle detalle) =>
                                  _realCantidad(detalle) ?? 0,
                              cellBuilder: (AjusteDetalle detalle) => Text(
                                _formatNumber(_realCantidad(detalle)),
                              ),
                            ),
                            TableColumnConfig<AjusteDetalle>(
                              label: 'Ajuste',
                              isNumeric: true,
                              sortAccessor: (AjusteDetalle detalle) =>
                                  detalle.cantidad,
                              cellBuilder: (AjusteDetalle detalle) => Text(
                                detalle.cantidad.toStringAsFixed(2),
                              ),
                            ),
                          ],
                          emptyMessage: 'Sin productos ajustados.',
                          searchPlaceholder: 'Buscar producto',
                          searchTextBuilder: (AjusteDetalle detalle) =>
                              detalle.productoNombre ?? '',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
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

  double? _realCantidad(AjusteDetalle detalle) {
    if (detalle.cantidadReal != null) {
      return detalle.cantidadReal;
    }
    if (detalle.cantidadSistema != null) {
      return detalle.cantidadSistema! + detalle.cantidad;
    }
    return null;
  }

  String _formatNumber(double? value) {
    if (value == null) {
      return '-';
    }
    return value.toStringAsFixed(2);
  }
}
