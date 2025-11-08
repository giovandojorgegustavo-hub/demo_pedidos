import 'package:demo_pedidos/models/movimiento_resumen.dart';
import 'package:demo_pedidos/models/viaje_detalle.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class ViajeDetalleFormResult {
  const ViajeDetalleFormResult({
    required this.idMovimiento,
  });

  final String idMovimiento;
}

class ViajeDetalleFormView extends StatefulWidget {
  const ViajeDetalleFormView({
    super.key,
    required this.viajeId,
    this.detalle,
  });

  final String viajeId;
  final ViajeDetalle? detalle;

  @override
  State<ViajeDetalleFormView> createState() => _ViajeDetalleFormViewState();
}

class _ViajeDetalleFormViewState extends State<ViajeDetalleFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  List<MovimientoResumen> _movimientos = <MovimientoResumen>[];
  String? _selectedMovimientoId;

  @override
  void initState() {
    super.initState();
    _loadMovimientos();
  }

  Future<void> _loadMovimientos() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final List<MovimientoResumen> movimientos =
          await MovimientoResumen.fetchAll();
      final Set<String> asignados =
          await ViajeDetalle.movimientosAsignados();

      final String? actual = widget.detalle?.idMovimiento;
      final List<MovimientoResumen> disponibles = movimientos.where(
        (MovimientoResumen mov) =>
            mov.id == actual || !asignados.contains(mov.id),
      ).toList()
        ..sort(
          (MovimientoResumen a, MovimientoResumen b) =>
              b.fecha.compareTo(a.fecha),
        );

      if (!mounted) {
        return;
      }

      setState(() {
        _movimientos = disponibles;
        _selectedMovimientoId =
            widget.detalle?.idMovimiento ?? (disponibles.isNotEmpty ? disponibles.first.id : null);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar los movimientos: $error')),
      );
    }
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    final String? idMovimiento = _selectedMovimientoId;
    if (idMovimiento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un movimiento')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    Navigator.pop(
      context,
      ViajeDetalleFormResult(idMovimiento: idMovimiento),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ViajeDetalle? detalle = widget.detalle;
    return FormPageScaffold(
      title: detalle == null ? 'Agregar movimiento' : 'Editar movimiento',
      onCancel: () => Navigator.pop(context),
      onSave: _handleSave,
      isSaving: _isSaving,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (_isLoading)
              const LinearProgressIndicator(minHeight: 2),
            DropdownButtonFormField<String>(
              value: _selectedMovimientoId,
              items: _movimientos
                  .map(
                    (MovimientoResumen mov) => DropdownMenuItem<String>(
                      value: mov.id,
                      child: Text(
                        '${mov.clienteNombre} • ${_formatFechaHora(mov.fecha)}',
                      ),
                    ),
                  )
                  .toList(growable: false),
              decoration: const InputDecoration(
                labelText: 'Movimiento',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'Selecciona un movimiento';
                }
                return null;
              },
              onChanged: detalle == null
                  ? (String? value) {
                      setState(() {
                        _selectedMovimientoId = value;
                      });
                    }
                  : null,
            ),
            const SizedBox(height: 16),
            if (detalle != null || _selectedMovimientoId != null)
              _MovimientoPreview(
                movimiento: detalle == null
                    ? _movimientos
                        .firstWhere(
                          (MovimientoResumen item) =>
                              item.id == _selectedMovimientoId,
                          orElse: () => _movimientos.isEmpty
                              ? _emptyMovimientoResumen()
                              : _movimientos.first,
                        )
                    : _movimientoDesdeDetalle(detalle),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFechaHora(DateTime fecha) {
    final String day = fecha.day.toString().padLeft(2, '0');
    final String month = fecha.month.toString().padLeft(2, '0');
    final String hour = fecha.hour.toString().padLeft(2, '0');
    final String minute = fecha.minute.toString().padLeft(2, '0');
    return '$day/$month/${fecha.year} $hour:$minute';
  }
}

class _MovimientoPreview extends StatelessWidget {
  const _MovimientoPreview({
    required this.movimiento,
  });

  final MovimientoResumen movimiento;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              movimiento.clienteNombre,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _line('Contacto', movimiento.contactoNumero ?? '-'),
            _line('Provincia', movimiento.esProvincia ? 'Sí' : 'No'),
            if (movimiento.esProvincia)
              _line('Destino', movimiento.provinciaDestino ?? '-')
            else
              _line('Dirección', movimiento.direccion ?? 'Sin dirección'),
            if (!movimiento.esProvincia)
              _line('Referencia', movimiento.direccionReferencia ?? '-'),
            if (movimiento.baseNombre != null)
              _line('Base', movimiento.baseNombre!),
            _line(
              'Observación',
              (movimiento.observacion?.trim().isNotEmpty ?? false)
                  ? movimiento.observacion!.trim()
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

MovimientoResumen _emptyMovimientoResumen() => MovimientoResumen(
      id: '',
      idPedido: '',
      fecha: DateTime.now(),
      clienteNombre: '-',
      esProvincia: false,
      estadoTexto: 'pendiente',
      estadoCodigo: 0,
    );

MovimientoResumen _movimientoDesdeDetalle(ViajeDetalle detalle) {
  return MovimientoResumen(
    id: detalle.idMovimiento,
    idPedido: '',
    fecha: detalle.createdAt,
    clienteNombre: detalle.clienteNombre ?? '-',
    clienteNumero: detalle.contactoNumero,
    esProvincia: detalle.esProvincia,
    provinciaDestino: detalle.provinciaDestino,
    direccion: detalle.direccionTexto,
    direccionReferencia: detalle.direccionReferencia,
    baseNombre: detalle.baseNombre,
    estadoTexto: detalle.entregado ? 'terminado' : 'pendiente',
    estadoCodigo: detalle.entregado ? 2 : 1,
  );
}
