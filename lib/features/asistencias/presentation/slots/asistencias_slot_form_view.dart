import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/asistencia_slot.dart';

class AsistenciasSlotFormView extends StatefulWidget {
  const AsistenciasSlotFormView({
    super.key,
    this.slot,
  });

  final AsistenciaSlot? slot;

  @override
  State<AsistenciasSlotFormView> createState() =>
      _AsistenciasSlotFormViewState();
}

class _AsistenciasSlotFormViewState extends State<AsistenciasSlotFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  TimeOfDay? _time;
  bool _activo = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.slot?.nombre ?? '');
    _descripcionCtrl =
        TextEditingController(text: widget.slot?.descripcion ?? '');
    if (widget.slot != null) {
      final List<String> parts = widget.slot!.hora.split(':');
      _time = TimeOfDay(
        hour: int.tryParse(parts.elementAt(0)) ?? 0,
        minute: int.tryParse(parts.elementAt(1)) ?? 0,
      );
      _activo = widget.slot!.activo;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay initial = _time ?? const TimeOfDay(hour: 11, minute: 30);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final String hh = _time!.hour.toString().padLeft(2, '0');
    final String mm = _time!.minute.toString().padLeft(2, '0');
    final String timeStr = '$hh:$mm:00';
    try {
      if (widget.slot == null) {
        await AsistenciaSlot.create(
          nombre: _nombreCtrl.text.trim(),
          hora: timeStr,
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
          activo: _activo,
        );
      } else {
        await AsistenciaSlot.update(
          id: widget.slot!.id,
          nombre: _nombreCtrl.text.trim(),
          hora: timeStr,
          descripcion: _descripcionCtrl.text.trim().isEmpty
              ? null
              : _descripcionCtrl.text.trim(),
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
    if (widget.slot == null || _isDeleting) {
      return;
    }
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Eliminar slot'),
        content: const Text(
          'Esta acción eliminará el slot de asistencia. ¿Continuar?',
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
      await AsistenciaSlot.delete(widget.slot!.id);
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
    final bool editing = widget.slot != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar slot' : 'Nuevo slot'),
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
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (String? value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora'),
                subtitle: Text(
                  _time == null
                      ? 'Selecciona la hora'
                      : _time!.format(context),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: _pickTime,
                ),
              ),
              if (_time == null)
                const Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    'Selecciona una hora válida',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _activo,
                title: const Text('Slot activo'),
                onChanged: (bool value) => setState(() => _activo = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isSaving || _time == null) ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(editing ? 'Guardar cambios' : 'Crear slot'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
