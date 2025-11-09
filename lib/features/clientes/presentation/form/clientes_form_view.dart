import 'package:demo_pedidos/models/cliente.dart';
import 'package:demo_pedidos/ui/form/form_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientesFormView extends StatefulWidget {
  const ClientesFormView({super.key});

  @override
  State<ClientesFormView> createState() => _ClientesFormViewState();
}

class _ClientesFormViewState extends State<ClientesFormView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingReferentes = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<String> _canales = <String>['telegram', 'referido', 'ads', 'qr'];
  String _canal = 'telegram';
  List<Cliente> _clientes = <Cliente>[];
  String? _referidoPorId;

  @override
  void initState() {
    super.initState();
    _loadReferentes();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _loadReferentes() async {
    setState(() {
      _isLoadingReferentes = true;
    });
    try {
      final List<Cliente> clientes = await Cliente.getClientes();
      if (!mounted) {
        return;
      }
      setState(() {
        _clientes = clientes;
        _isLoadingReferentes = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingReferentes = false;
      });
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true || _isSaving) {
      return;
    }
    if (_canal == 'referido' && _referidoPorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona el cliente que refirió a este usuario.'),
        ),
      );
      return;
    }
    final String? userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para registrar.')),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    final String numeroInput = _numeroController.text.trim();
    final bool numeroDuplicado = await Cliente.numeroExists(numeroInput);
    if (numeroDuplicado) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este número ya está registrado para otro cliente.'),
          ),
        );
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    final Cliente payload = Cliente(
      id: '',
      nombre: _nombreController.text.trim(),
      numero: numeroInput,
      canal: _canal,
      referidoPor: _canal == 'referido' ? _referidoPorId : null,
      registradoAt: DateTime.now(),
      registradoPor: userId,
    );

    try {
      final String id = await Cliente.insert(payload);
      if (!mounted) {
        return;
      }
      Navigator.pop(context, id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el cliente: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: 'Nuevo cliente',
      onCancel: _isSaving ? null : () => Navigator.pop(context),
      onSave: _onSave,
      isSaving: _isSaving,
      contentPadding: EdgeInsets.zero,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _canal,
              decoration: const InputDecoration(
                labelText: 'Canal de origen',
                border: OutlineInputBorder(),
              ),
              items: _canales
                  .map(
                    (String canal) => DropdownMenuItem<String>(
                      value: canal,
                      child: Text(canal),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _canal = value;
                  if (_canal != 'referido') {
                    _referidoPorId = null;
                  }
                });
              },
            ),
            if (_canal == 'referido') ...<Widget>[
              const SizedBox(height: 16),
              if (_isLoadingReferentes)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String?>(
                  initialValue: _referidoPorId,
                  decoration: const InputDecoration(
                    labelText: 'Cliente que refirió (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _clientes
                      .map(
                        (Cliente cliente) => DropdownMenuItem<String?>(
                          value: cliente.id,
                          child: Text(cliente.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _referidoPorId = value;
                    });
                  },
                  validator: (String? value) {
                    if (_canal == 'referido' &&
                        (value == null || value.isEmpty)) {
                      return 'Selecciona el cliente que refirió';
                    }
                    return null;
                  },
                ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número de contacto',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa el número';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
