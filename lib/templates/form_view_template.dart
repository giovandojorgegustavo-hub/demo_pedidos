import 'package:flutter/material.dart';

// TODO: Import your model
// import 'package:demo_pedidos/models/my_model.dart';

// TODO: Replace 'MyModel' with your model name (e.g., Cliente, Producto)
typedef MyModel = ({String id, String name}); // Example model

class FormViewTemplate extends StatefulWidget {
  // TODO: Replace 'MyModel' with your model type
  final MyModel? item;

  const FormViewTemplate({super.key, this.item});

  @override
  State<FormViewTemplate> createState() => _FormViewTemplateState();
}

class _FormViewTemplateState extends State<FormViewTemplate> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // TODO: Create controllers for your form fields
  final TextEditingController _nameController = TextEditingController();

  bool _isSaving = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // TODO: Initialize controllers with item data
      _nameController.text = widget.item!.name;
    }
  }

  @override
  void dispose() {
    // TODO: Dispose your controllers
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // TODO: Create the payload from your controllers
      // ignore: unused_local_variable
      final payload = (
        id: widget.item?.id ?? '',
        name: _nameController.text,
      );

      if (_isEditing) {
        // TODO: Implement your update logic
        // await MyModel.update(payload);
      } else {
        // TODO: Implement your insert logic
        // await MyModel.insert(payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.pop(context, true); // Return true to indicate success
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save item: $error')),
      );
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Update the title
        title: Text(_isEditing ? 'Edit Item' : 'New Item'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // TODO: Add your form fields here
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (String? value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required.';
                          }
                          return null;
                        },
                      ),
                      // Example of another field
                      // const SizedBox(height: 16),
                      // TextFormField(
                      //   ...
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: _FormFooter(
                isSaving: _isSaving,
                onCancel: _isSaving ? null : () => Navigator.pop(context),
                onSave: _isSaving ? null : _onSave,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormFooter extends StatelessWidget {
  const _FormFooter({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback? onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onSave,
              child: Text(isSaving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }
}
