import 'package:demo_pedidos/features/viajes/presentation/shared/viaje_detalle_form_view.dart';
import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/viaje.dart';
import 'package:demo_pedidos/models/viaje_detalle.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/detail_inline_section.dart';
import 'package:demo_pedidos/ui/table/detail_row_actions.dart';
import 'package:flutter/material.dart';

class ViajeFormView extends StatefulWidget {
  const ViajeFormView({
    super.key,
    this.viaje,
  });

  final Viaje? viaje;

  @override
  State<ViajeFormView> createState() => _ViajeFormViewState();
}

class _ViajeFormViewState extends State<ViajeFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _numLlamadasController;
  late TextEditingController _numWspController;
  late TextEditingController _numPagoController;
  late TextEditingController _linkController;
  late TextEditingController _montoController;

  late DateTime _fecha;
  late TimeOfDay _hora;

  bool _isSaving = false;
  bool _isLoadingDetalles = false;
  List<_DetalleDraft> _detalles = <_DetalleDraft>[];
  List<ViajeDetalle> _detallesOriginales = <ViajeDetalle>[];

  Viaje? get _viaje => widget.viaje;
  bool get _isEditing => _viaje != null;

  @override
  void initState() {
    super.initState();
    final Viaje? viaje = _viaje;
    _nombreController =
        TextEditingController(text: viaje?.nombreMotorizado ?? '');
    _numLlamadasController =
        TextEditingController(text: viaje?.numLlamadas ?? '');
    _numWspController = TextEditingController(text: viaje?.numWsp ?? '');
    _numPagoController = TextEditingController(text: viaje?.numPago ?? '');
    _linkController = TextEditingController(text: viaje?.link ?? '');
    _montoController =
        TextEditingController(text: viaje?.monto?.toStringAsFixed(2) ?? '');

    final DateTime baseFecha = viaje?.registradoAt ?? DateTime.now();
    _fecha = DateTime(baseFecha.year, baseFecha.month, baseFecha.day);
    _hora = TimeOfDay(hour: baseFecha.hour, minute: baseFecha.minute);

    if (_isEditing) {
      _loadDetallesIniciales();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numLlamadasController.dispose();
    _numWspController.dispose();
    _numPagoController.dispose();
    _linkController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _loadDetallesIniciales() async {
    setState(() {
      _isLoadingDetalles = true;
    });
    try {
      final List<ViajeDetalle> detalles =
          await ViajeDetalle.getByViaje(_viaje!.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _detallesOriginales = detalles;
        _detalles = detalles
            .map((ViajeDetalle detalle) => _DetalleDraft.fromDetalle(detalle))
            .toList(growable: true);
        _isLoadingDetalles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingDetalles = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el detalle: $error')),
      );
    }
  }

  Future<void> _pickFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fecha = picked;
      });
    }
  }

  Future<void> _pickHora() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _hora);
    if (picked != null) {
      setState(() {
        _hora = picked;
      });
    }
  }

  String _formatFecha() {
    final String day = _fecha.day.toString().padLeft(2, '0');
    final String month = _fecha.month.toString().padLeft(2, '0');
    return '$day/$month/${_fecha.year}';
  }

  String _formatHora() =>
      '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}';

  Future<void> _openDetalleDraftForm({_DetalleDraft? draft, int? index}) async {
    if (_isSaving) {
      return;
    }
    final ViajeDetalle? detallePlaceholder =
        draft == null ? null : draft.toViajeDetalle(_viaje?.id ?? '__draft__');
    final ViajeDetalleFormResult? result =
        await Navigator.push<ViajeDetalleFormResult>(
      context,
      MaterialPageRoute<ViajeDetalleFormResult>(
        builder: (_) => ViajeDetalleFormView(
          viajeId: _viaje?.id ?? '__draft__',
          detalle: detallePlaceholder,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    final String movimientoId = result.idMovimiento;
    if (_detalles.any(
      (_DetalleDraft item) =>
          item.idMovimiento == movimientoId &&
          (draft == null || item.idMovimiento != draft.idMovimiento),
    )) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El movimiento ya está agregado.')),
      );
      return;
    }

    try {
      final MovimientoResumen? movimiento =
          await MovimientoResumen.fetchById(movimientoId);
      if (movimiento == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Movimiento no disponible.')),
          );
        }
        return;
      }
      final _DetalleDraft draftResult = _DetalleDraft.fromMovimiento(movimiento)
          .copyWith(detalleId: draft?.detalleId);
      if (!mounted) {
        return;
      }
      setState(() {
        if (index != null) {
          _detalles[index] = draftResult;
        } else {
          _detalles.add(draftResult);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar el movimiento: $error')),
      );
    }
  }

  void _removeDetalle(_DetalleDraft item) {
    setState(() {
      _detalles.remove(item);
    });
  }

  List<TableColumnConfig<_DetalleDraft>> _detalleColumns() {
    return <TableColumnConfig<_DetalleDraft>>[
      TableColumnConfig<_DetalleDraft>(
        label: 'Cliente',
        sortAccessor: (_DetalleDraft item) => item.clienteNombre,
        cellBuilder: (_DetalleDraft item) => Text(item.clienteNombre),
      ),
      TableColumnConfig<_DetalleDraft>(
        label: 'Contacto',
        sortAccessor: (_DetalleDraft item) => item.contacto ?? '',
        cellBuilder: (_DetalleDraft item) => Text(item.contacto ?? '-'),
      ),
      TableColumnConfig<_DetalleDraft>(
        label: 'Dirección / Destino',
        sortAccessor: (_DetalleDraft item) =>
            item.esProvincia ? item.destino ?? '' : item.direccion ?? '',
        cellBuilder: (_DetalleDraft item) => Text(item.esProvincia
            ? (item.destino ?? 'Provincia')
            : (item.direccion ?? 'Sin dirección')),
      ),
      TableColumnConfig<_DetalleDraft>(
        label: 'Acciones',
        cellBuilder: (_DetalleDraft item) => DetailRowActions(
          onEdit: () {
            final int index = _detalles.indexOf(item);
            if (index >= 0) {
              _openDetalleDraftForm(draft: item, index: index);
            }
          },
          onDelete: _isSaving ? null : () => _removeDetalle(item),
        ),
      ),
    ];
  }

  Future<void> _persistDetalles(String viajeId) async {
    if (_isEditing) {
      final Map<String, ViajeDetalle> originales = <String, ViajeDetalle>{
        for (final ViajeDetalle detalle in _detallesOriginales)
          detalle.idMovimiento: detalle,
      };
      final Set<String> actuales =
          _detalles.map((_DetalleDraft item) => item.idMovimiento).toSet();

      for (final ViajeDetalle detalle in _detallesOriginales) {
        if (!actuales.contains(detalle.idMovimiento)) {
          await ViajeDetalle.delete(detalle.id);
        }
      }

      for (final _DetalleDraft draft in _detalles) {
        if (!originales.containsKey(draft.idMovimiento)) {
          await ViajeDetalle.insert(
            idViaje: viajeId,
            idMovimiento: draft.idMovimiento,
          );
        }
      }
    } else {
      for (final _DetalleDraft draft in _detalles) {
        await ViajeDetalle.insert(
          idViaje: viajeId,
          idMovimiento: draft.idMovimiento,
        );
      }
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta registrar el detalle del viaje.'),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    double? monto;
    if (_montoController.text.trim().isNotEmpty) {
      monto =
          double.tryParse(_montoController.text.trim().replaceAll(',', '.'));
      if (monto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Monto inválido')),
        );
        setState(() {
          _isSaving = false;
        });
        return;
      }
    }

    final DateTime registradoAt = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final Viaje payload = Viaje(
      id: _viaje?.id ?? '',
      nombreMotorizado: _nombreController.text.trim(),
      numLlamadas: _numLlamadasController.text.trim(),
      numPago: _numPagoController.text.trim(),
      link: _linkController.text.trim(),
      numWsp: _numWspController.text.trim().isEmpty
          ? null
          : _numWspController.text.trim(),
      monto: monto,
      registradoAt: registradoAt,
      editadoAt: _viaje?.editadoAt,
      totalItems: _viaje?.totalItems ?? 0,
      pendientes: _viaje?.pendientes ?? 0,
      estadoTexto: _viaje?.estadoTexto,
      estadoCodigo: _viaje?.estadoCodigo,
    );

    try {
      if (_isEditing) {
        await Viaje.update(payload.copyWith(id: _viaje!.id));
        await _persistDetalles(_viaje!.id);
      } else {
        final String viajeId = await Viaje.insert(payload);
        await _persistDetalles(viajeId);
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar el viaje: $error'),
        ),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: _isEditing ? 'Editar viaje' : 'Registrar viaje',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del motorizado',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre del motorizado';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numWspController,
              decoration: const InputDecoration(
                labelText: 'Número de WhatsApp',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numLlamadasController,
              decoration: const InputDecoration(
                labelText: 'Número de llamadas',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el número de llamadas';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numPagoController,
              decoration: const InputDecoration(
                labelText: 'Número de pagos (Yape / Plin)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el número de pago';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Link de seguimiento',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el link del viaje';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _montoController,
              decoration: const InputDecoration(
                labelText: 'Monto estimado (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            if (_isLoadingDetalles) const LinearProgressIndicator(minHeight: 2),
            if (_isLoadingDetalles) const SizedBox(height: 12),
            DetailInlineSection<_DetalleDraft>(
              title: 'Movimientos del viaje',
              items: _detalles,
              columns: _detalleColumns(),
              minTableWidth: 680,
              emptyMessage: _isLoadingDetalles
                  ? 'Cargando...'
                  : 'Sin movimientos asignados.',
              onAdd: _isSaving || _isLoadingDetalles
                  ? null
                  : () => _openDetalleDraftForm(),
              showTableHeader: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFecha,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text('Fecha: ${_formatFecha()}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickHora,
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('Hora: ${_formatHora()}'),
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

class _DetalleDraft {
  const _DetalleDraft({
    this.detalleId,
    required this.idMovimiento,
    required this.clienteNombre,
    this.contacto,
    this.direccion,
    this.destino,
    this.esProvincia = false,
  });

  final String? detalleId;
  final String idMovimiento;
  final String clienteNombre;
  final String? contacto;
  final String? direccion;
  final String? destino;
  final bool esProvincia;

  _DetalleDraft copyWith({
    String? detalleId,
    String? idMovimiento,
    String? clienteNombre,
    String? contacto,
    String? direccion,
    String? destino,
    bool? esProvincia,
  }) {
    return _DetalleDraft(
      detalleId: detalleId ?? this.detalleId,
      idMovimiento: idMovimiento ?? this.idMovimiento,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      contacto: contacto ?? this.contacto,
      direccion: direccion ?? this.direccion,
      destino: destino ?? this.destino,
      esProvincia: esProvincia ?? this.esProvincia,
    );
  }

  factory _DetalleDraft.fromMovimiento(MovimientoResumen mov) {
    return _DetalleDraft(
      idMovimiento: mov.id,
      clienteNombre: mov.clienteNombre,
      contacto: mov.contactoNumero ?? mov.clienteNumero,
      direccion: mov.esProvincia ? null : mov.direccion,
      destino: mov.esProvincia ? mov.provinciaDestino : null,
      esProvincia: mov.esProvincia,
    );
  }

  factory _DetalleDraft.fromDetalle(ViajeDetalle detalle) {
    return _DetalleDraft(
      detalleId: detalle.id,
      idMovimiento: detalle.idMovimiento,
      clienteNombre: detalle.clienteNombre ?? '-',
      contacto: detalle.contactoNumero,
      direccion: detalle.esProvincia ? null : detalle.direccionTexto,
      destino: detalle.esProvincia ? detalle.provinciaDestino : null,
      esProvincia: detalle.esProvincia,
    );
  }

  ViajeDetalle toViajeDetalle(String viajeId) {
    return ViajeDetalle(
      id: detalleId ?? '',
      idViaje: viajeId,
      idMovimiento: idMovimiento,
      createdAt: DateTime.now(),
      clienteNombre: clienteNombre,
      contactoNumero: contacto,
      direccionTexto: esProvincia ? null : direccion,
      direccionReferencia: null,
      esProvincia: esProvincia,
      provinciaDestino: esProvincia ? destino : null,
      provinciaDestinatario: null,
      provinciaDni: null,
      baseNombre: null,
    );
  }
}
