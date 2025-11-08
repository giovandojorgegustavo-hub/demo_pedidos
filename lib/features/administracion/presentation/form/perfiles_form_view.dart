import 'package:demo_pedidos/models/perfil.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';

class PerfilesFormView extends StatefulWidget {
  const PerfilesFormView({super.key, required this.perfil});

  final Perfil perfil;

  @override
  State<PerfilesFormView> createState() => _PerfilesFormViewState();
}

class _PerfilesFormViewState extends State<PerfilesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late String _rol;
  late bool _activo;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nombreController =
        TextEditingController(text: widget.perfil.nombre ?? '');
    _rol = widget.perfil.rol;
    _activo = widget.perfil.activo;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final Perfil updated = widget.perfil.copyWith(
      nombre: _nombreController.text.trim().isEmpty
          ? null
          : _nombreController.text.trim(),
      rol: _rol,
      activo: _activo,
    );
    try {
      await Perfil.update(updated);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el usuario: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return FormPageScaffold(
      title: 'Editar usuario',
      isSaving: _isSaving,
      onSave: _handleSave,
      onCancel: () => Navigator.pop(context, false),
      child: Form(
        key: _formKey,
        child: ListView(
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre visible',
                hintText: 'Ej: Ana Pérez',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              initialValue: _rol,
              items: Perfil.availableRoles
                  .map(
                    (String rol) => DropdownMenuItem<String>(
                      value: rol,
                      child: Text(
                        rol[0].toUpperCase() + rol.substring(1),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSaving
                  ? null
                  : (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _rol = value;
                      });
                    },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _activo,
              onChanged: _isSaving
                  ? null
                  : (bool value) {
                      setState(() {
                        _activo = value;
                      });
                    },
              title: const Text('Activo'),
              subtitle: const Text('Controla si puede iniciar sesión'),
            ),
            const SizedBox(height: 16),
            SelectableText(
              'ID: ${widget.perfil.userId}',
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: textTheme.bodySmall?.color?.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
