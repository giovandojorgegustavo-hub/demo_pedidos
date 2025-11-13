import 'package:flutter/material.dart';

import 'package:demo_pedidos/features/bases/presentation/form/bases_form_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/transferencia_detalle_form_view.dart';
import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/models/stock_por_base.dart';
import 'package:demo_pedidos/models/transferencia.dart';
import 'package:demo_pedidos/models/transferencia_detalle.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:demo_pedidos/ui/form/inline_form_table.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';

class TransferenciasFormView extends StatefulWidget {
  const TransferenciasFormView({super.key, this.transferencia});

  final Transferencia? transferencia;

  @override
  State<TransferenciasFormView> createState() =>
      _TransferenciasFormViewState();
}

class _TransferenciasFormViewState extends State<TransferenciasFormView> {
  static const String _newBaseValue = '__new_base__';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<FormFieldState<String>> _baseOrigenFieldKey =
      GlobalKey<FormFieldState<String>>();
  final GlobalKey<FormFieldState<String>> _baseDestinoFieldKey =
      GlobalKey<FormFieldState<String>>();
  final TextEditingController _observacionController = TextEditingController();

  List<LogisticaBase> _bases = <LogisticaBase>[];
  List<_TransferStockOption> _stockOptions = <_TransferStockOption>[];
  Map<String, _TransferStockOption> _stockByProducto =
      <String, _TransferStockOption>{};
  List<TransferenciaDetalle> _detalles = <TransferenciaDetalle>[];

  bool _isLoadingBases = true;
  bool _isLoadingStock = false;
  bool _isLoadingDetalles = false;
  bool _isSaving = false;
  String? _baseOrigenId;
  String? _baseDestinoId;

  bool get _isEditing => widget.transferencia != null;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await _loadBases();
    await _loadStockForOrigen();
    final Transferencia? transferencia = widget.transferencia;
    if (transferencia != null) {
      _observacionController.text = transferencia.observacion ?? '';
      _baseOrigenId = transferencia.idbaseOrigen;
      _baseDestinoId = transferencia.idbaseDestino;
      await _loadStockForOrigen();
      await _loadDetalles();
    }
  }

  Future<void> _loadBases() async {
    setState(() => _isLoadingBases = true);
    try {
      final List<LogisticaBase> bases = await LogisticaBase.getBases();
      if (!mounted) {
        return;
      }
      setState(() {
        _bases = bases;
        _isLoadingBases = false;
        if (_baseOrigenId != null &&
            bases.every((LogisticaBase base) => base.id != _baseOrigenId)) {
          _baseOrigenId = null;
        }
        if (_baseDestinoId != null &&
            bases.every((LogisticaBase base) => base.id != _baseDestinoId)) {
          _baseDestinoId = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingBases = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar las bases: $error')),
      );
    }
  }

  Future<void> _loadStockForOrigen() async {
    final String? baseId = _baseOrigenId;
    if (baseId == null) {
      setState(() {
        _stockOptions = <_TransferStockOption>[];
        _stockByProducto = <String, _TransferStockOption>{};
      });
      return;
    }
    setState(() => _isLoadingStock = true);
    try {
      final List<StockPorBase> stock = await StockPorBase.fetchByBase(baseId);
      if (!mounted) {
        return;
      }
      final List<_TransferStockOption> options = stock
          .where((StockPorBase item) => item.cantidad > 0)
          .map(
            (StockPorBase item) => _TransferStockOption(
              idproducto: item.idproducto,
              nombre: item.productoNombre,
              disponible: item.cantidad,
            ),
          )
          .toList(growable: false)
        ..sort(
          (_TransferStockOption a, _TransferStockOption b) =>
              a.nombre.compareTo(b.nombre),
        );
      setState(() {
        _stockOptions = options;
        _stockByProducto = <String, _TransferStockOption>{
          for (final _TransferStockOption option in options)
            option.idproducto: option,
        };
        _isLoadingStock = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingStock = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el stock: $error')),
      );
    }
  }

  Future<void> _loadDetalles() async {
    final Transferencia? transferencia = widget.transferencia;
    if (transferencia == null) {
      return;
    }
    setState(() => _isLoadingDetalles = true);
    try {
      final List<TransferenciaDetalle> detalles =
          await TransferenciaDetalle.fetchByTransferencia(transferencia.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _detalles = detalles;
        _isLoadingDetalles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingDetalles = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los productos: $error')),
      );
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _openDetalleForm({TransferenciaDetalle? detalle}) async {
    if (_baseOrigenId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la base de origen primero.')),
      );
      return;
    }
    if (_isLoadingStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esperando el stock de la base...')),
      );
      return;
    }
    final List<TransferenciaProductoDisponible> opciones =
        _buildProductoDisponibles(excluir: detalle);
    if (opciones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La base origen no tiene productos disponibles.'),
        ),
      );
      return;
    }
    final TransferenciaDetalleResult? result =
        await Navigator.push<TransferenciaDetalleResult>(
      context,
      MaterialPageRoute<TransferenciaDetalleResult>(
        builder: (_) => TransferenciaDetalleFormView(
          productosDisponibles: opciones,
          detalle: detalle,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    setState(() {
      if (detalle == null) {
        _detalles = <TransferenciaDetalle>[..._detalles, result.detalle];
      } else {
        _detalles = _detalles.map((TransferenciaDetalle item) {
          if (item == detalle) {
            return result.detalle;
          }
          return item;
        }).toList();
      }
    });
  }

  void _removeDetalle(TransferenciaDetalle detalle) {
    setState(() {
      _detalles = _detalles
          .where((TransferenciaDetalle item) => item != detalle)
          .toList();
    });
  }

  List<TransferenciaProductoDisponible> _buildProductoDisponibles({
    TransferenciaDetalle? excluir,
  }) {
    final Map<String, double> restantes =
        _stockRestantePorProducto(excluir: excluir);
    final List<TransferenciaProductoDisponible> opciones =
        <TransferenciaProductoDisponible>[];
    restantes.forEach((String productoId, double disponible) {
      final _TransferStockOption? base = _stockByProducto[productoId];
      if (base == null) {
        return;
      }
      if (disponible <= 0.0001 &&
          (excluir == null || excluir.idproducto != productoId)) {
        return;
      }
      opciones.add(
        TransferenciaProductoDisponible(
          id: productoId,
          nombre: base.nombre,
          disponible: disponible,
        ),
      );
    });
    opciones.sort(
      (TransferenciaProductoDisponible a, TransferenciaProductoDisponible b) =>
          a.nombre.compareTo(b.nombre),
    );
    return opciones;
  }

  Map<String, double> _stockRestantePorProducto({
    TransferenciaDetalle? excluir,
  }) {
    final Map<String, double> restantes = <String, double>{
      for (final _TransferStockOption option in _stockOptions)
        option.idproducto: option.disponible,
    };
    if (excluir != null && !restantes.containsKey(excluir.idproducto)) {
      restantes[excluir.idproducto] = excluir.cantidad;
    }
    for (final TransferenciaDetalle detalle in _detalles) {
      if (excluir != null && detalle == excluir) {
        continue;
      }
      if (!restantes.containsKey(detalle.idproducto)) {
        continue;
      }
      final double nuevoValor =
          (restantes[detalle.idproducto]! - detalle.cantidad)
              .clamp(0, double.infinity) as double;
      restantes[detalle.idproducto] = nuevoValor;
    }
    return restantes;
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_baseOrigenId == null || _baseDestinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona las bases.')),
      );
      return;
    }
    if (_baseOrigenId == _baseDestinoId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las bases deben ser distintas.')),
      );
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto.')),
      );
      return;
    }
    if (!_validateStockBeforeSave()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      String transferenciaId = widget.transferencia?.id ?? '';
      final Transferencia payload = Transferencia(
        id: transferenciaId,
        idbaseOrigen: _baseOrigenId!,
        idbaseDestino: _baseDestinoId!,
        observacion: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        registradoAt: widget.transferencia?.registradoAt,
      );
      if (widget.transferencia == null) {
        transferenciaId = await Transferencia.insert(payload);
      } else {
        await Transferencia.update(payload);
      }
      await TransferenciaDetalle.replaceForTransferencia(
        transferenciaId,
        _detalles.map((TransferenciaDetalle detalle) {
          return TransferenciaDetalle(
            id: detalle.id,
            idtransferencia: transferenciaId,
            idproducto: detalle.idproducto,
            cantidad: detalle.cantidad,
            productoNombre: detalle.productoNombre,
          );
        }).toList(growable: false),
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
      setState(() => _isSaving = false);
    }
  }

  bool _validateStockBeforeSave() {
    final Map<String, double> disponibles = <String, double>{
      for (final _TransferStockOption option in _stockOptions)
        option.idproducto: option.disponible,
    };
    for (final TransferenciaDetalle detalle in _detalles) {
      final double disponible = disponibles[detalle.idproducto] ?? 0;
      if (detalle.cantidad > disponible + 0.0001) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock insuficiente para ${detalle.productoNombre ?? 'el producto'}. '
              'Disponible: ${disponible.toStringAsFixed(2)}',
            ),
          ),
        );
        return false;
      }
      disponibles[detalle.idproducto] = disponible - detalle.cantidad;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar transferencia' : 'Nueva transferencia',
      onSave: () => _onSave(),
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _buildBasesRow(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observación (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoadingDetalles)
              const Center(child: CircularProgressIndicator())
            else ...<Widget>[
              if (_isLoadingStock)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Builder(
                builder: (BuildContext context) {
                  final bool canAddDetalle = !_isSaving &&
                      !_isLoadingDetalles &&
                      !_isLoadingStock &&
                      _baseOrigenId != null &&
                      _stockOptions.isNotEmpty;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      InlineFormTable<TransferenciaDetalle>(
                        title: 'Detalle',
                        items: _detalles,
                        columns: _detalleColumns(),
                        emptyMessage: 'Sin productos registrados.',
                        helperText:
                            'Los productos se descuentan de la base origen y se suman en la base destino.',
                        onAdd: canAddDetalle ? () => _openDetalleForm() : null,
                        onRowTap: (TransferenciaDetalle detalle) =>
                            _openDetalleForm(detalle: detalle),
                      ),
                      if (!canAddDetalle && _stockOptions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'La base origen no tiene stock disponible.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Total ítems: ${_detalles.length}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasesRow() {
    if (_isLoadingBases) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: <Widget>[
        Expanded(
          child: DropdownButtonFormField<String>(
            key: _baseOrigenFieldKey,
            initialValue: _baseOrigenId,
            items: _baseDropdownItems(excludeId: _baseDestinoId),
            onChanged: (String? value) async {
              if (value == _newBaseValue) {
                await _createBaseAndAssign(
                  (String newId) => _baseOrigenId = newId,
                  _baseOrigenFieldKey,
                );
                await _loadStockForOrigen();
                return;
              }
              setState(() {
                _baseOrigenId = value;
                _detalles = <TransferenciaDetalle>[];
                if (_baseDestinoId == value) {
                  _baseDestinoId = null;
                  _baseDestinoFieldKey.currentState?.didChange(null);
                }
              });
              await _loadStockForOrigen();
            },
            decoration: const InputDecoration(
              labelText: 'Base origen',
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty || value == _newBaseValue) {
                return 'Selecciona la base de origen';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<String>(
            key: _baseDestinoFieldKey,
            initialValue: _baseDestinoId,
            items: _baseDropdownItems(excludeId: _baseOrigenId),
            onChanged: (String? value) async {
              if (value == _newBaseValue) {
                await _createBaseAndAssign(
                  (String newId) => _baseDestinoId = newId,
                  _baseDestinoFieldKey,
                );
                return;
              }
              setState(() {
                _baseDestinoId = value;
                if (_baseOrigenId == value) {
                  _baseOrigenId = null;
                  _baseOrigenFieldKey.currentState?.didChange(null);
                  _detalles = <TransferenciaDetalle>[];
                  _loadStockForOrigen();
                }
              });
            },
            decoration: const InputDecoration(
              labelText: 'Base destino',
              border: OutlineInputBorder(),
            ),
            validator: (String? value) {
              if (value == null || value.isEmpty || value == _newBaseValue) {
                return 'Selecciona la base destino';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Future<void> _createBaseAndAssign(
    void Function(String newId) onCreated,
    GlobalKey<FormFieldState<String>> fieldKey,
  ) async {
    final String? newId = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const BasesFormView(),
      ),
    );
    if (newId == null) {
      return;
    }
    await _loadBases();
    if (!mounted) {
      return;
    }
    setState(() {
      onCreated(newId);
    });
    fieldKey.currentState?.didChange(newId);
  }

  List<DropdownMenuItem<String>> _baseDropdownItems({String? excludeId}) {
    final Iterable<LogisticaBase> filtered = excludeId == null
        ? _bases
        : _bases.where((LogisticaBase base) => base.id != excludeId);
    return <DropdownMenuItem<String>>[
      ...filtered.map(
        (LogisticaBase base) => DropdownMenuItem<String>(
          value: base.id,
          child: Text(base.nombre),
        ),
      ),
      const DropdownMenuItem<String>(
        value: _newBaseValue,
        child: Text('➕ Nueva base'),
      ),
    ];
  }

  List<TableColumnConfig<TransferenciaDetalle>> _detalleColumns() {
    return <TableColumnConfig<TransferenciaDetalle>>[
      TableColumnConfig<TransferenciaDetalle>(
        label: 'Producto',
        sortAccessor: (TransferenciaDetalle d) => d.productoNombre ?? '',
        cellBuilder: (TransferenciaDetalle d) =>
            Text(d.productoNombre ?? '-'),
      ),
      TableColumnConfig<TransferenciaDetalle>(
        label: 'Cantidad',
        isNumeric: true,
        sortAccessor: (TransferenciaDetalle d) => d.cantidad,
        cellBuilder: (TransferenciaDetalle d) =>
            Text(d.cantidad.toStringAsFixed(2)),
      ),
      TableColumnConfig<TransferenciaDetalle>(
        label: 'Acciones',
        cellBuilder: (TransferenciaDetalle d) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openDetalleForm(detalle: d),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeDetalle(d),
            ),
          ],
        ),
      ),
    ];
  }
}

class _TransferStockOption {
  const _TransferStockOption({
    required this.idproducto,
    required this.nombre,
    required this.disponible,
  });

  final String idproducto;
  final String nombre;
  final double disponible;
}
