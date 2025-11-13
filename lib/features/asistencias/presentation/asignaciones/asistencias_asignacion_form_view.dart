import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/asistencia_asignacion.dart';
import 'package:demo_pedidos/models/asistencia_slot.dart';
import 'package:demo_pedidos/models/logistica_base.dart';

const List<String> kDiasSemana = <String>[
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo',
];

const Map<String, String> kDiasLabels = <String, String>{
  'lunes': 'Lunes',
  'martes': 'Martes',
  'miercoles': 'Miércoles',
  'jueves': 'Jueves',
  'viernes': 'Viernes',
  'sabado': 'Sábado',
  'domingo': 'Domingo',
};

class AsistenciasAsignacionFormView extends StatefulWidget {
  const AsistenciasAsignacionFormView({
    super.key,
    this.asignacion,
    required this.bases,
    required this.slots,
  });

  final AsistenciaAsignacion? asignacion;
  final List<LogisticaBase> bases;
  final List<AsistenciaSlot> slots;

  @override
  State<AsistenciasAsignacionFormView> createState() =>
      _AsistenciasAsignacionFormViewState();
}

class _AsistenciasAsignacionFormViewState
    extends State<AsistenciasAsignacionFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _baseId;
  String? _slotId;
  late Set<String> _diasSeleccionados;
  bool _activo = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _baseId = widget.asignacion?.idbase;
    _slotId = widget.asignacion?.idslot;
    _diasSeleccionados =
        widget.asignacion?.diasSemana.toSet() ?? kDiasSemana.toSet();
    _activo = widget.asignacion?.activo ?? true;
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un día.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (widget.asignacion == null) {
        await AsistenciaAsignacion.create(
          idbase: _baseId!,
          idslot: _slotId!,
          diasSemana: _diasSeleccionados.toList(),
          activo: _activo,
        );
      } else {
        await AsistenciaAsignacion.update(
          id: widget.asignacion!.id,
          idbase: _baseId!,
          idslot: _slotId!,
          diasSemana: _diasSeleccionados.toList(),
          activo: _activo,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.asignacion == null || _isDeleting) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar asignación'),
        content: const Text(
          'Esta acción eliminará la asignación de slot para la base seleccionada. ¿Continuar?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) {
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await AsistenciaAsignacion.delete(widget.asignacion!.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool editing = widget.asignacion != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar asignación' : 'Nueva asignación'),
        actions: <Widget>[
          if (editing)
            IconButton(
              tooltip: 'Eliminar',
              onPressed: _isDeleting ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              DropdownButtonFormField<String>(
                key: ValueKey<String>('base-${_baseId ?? 'none'}'),
                initialValue: _baseId,
                decoration: const InputDecoration(labelText: 'Base'),
                items: widget.bases
                    .map(
                      (LogisticaBase base) => DropdownMenuItem<String>(
                        value: base.id,
                        child: Text(base.nombre),
                      ),
                    )
                    .toList(growable: false),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona una base';
                  }
                  return null;
                },
                onChanged: (String? value) {
                  setState(() => _baseId = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey<String>('slot-${_slotId ?? 'none'}'),
                initialValue: _slotId,
                decoration: const InputDecoration(labelText: 'Slot'),
                items: widget.slots
                    .map(
                      (AsistenciaSlot slot) => DropdownMenuItem<String>(
                        value: slot.id,
                        child: Text('${slot.nombre} (${slot.hora.substring(0, 5)})'),
                      ),
                    )
                    .toList(growable: false),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona un slot';
                  }
                  return null;
                },
                onChanged: (String? value) {
                  setState(() => _slotId = value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Días de la semana',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kDiasSemana.map((String dia) {
                  final bool selected = _diasSeleccionados.contains(dia);
                  return FilterChip(
                    selected: selected,
                    label: Text(kDiasLabels[dia] ?? dia),
                    onSelected: (bool value) {
                      setState(() {
                        if (value) {
                          _diasSeleccionados.add(dia);
                        } else {
                          _diasSeleccionados.remove(dia);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                value: _activo,
                title: const Text('Asignación activa'),
                onChanged: (bool value) => setState(() => _activo = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Guardar cambios' : 'Crear asignación'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
