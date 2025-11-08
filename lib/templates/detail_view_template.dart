import 'package:flutter/material.dart';
import 'package:demo_pedidos/shared/app_sections.dart';

// TODO: Import your models, form views, etc.
// import 'package:demo_pedidos/models/my_model.dart';
// import 'package:demo_pedidos/features/my_feature/presentation/form/my_model_form_view.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

// TODO: Replace 'MyModel' and 'RelatedModel' with your model names
typedef MyModel = ({String id, String name, String description}); // Example model
typedef RelatedModel = ({String id, String name}); // Example related model

class DetailViewTemplate extends StatefulWidget {
  final String itemId;

  const DetailViewTemplate({super.key, required this.itemId});

  @override
  State<DetailViewTemplate> createState() => _DetailViewTemplateState();
}

class _DetailViewTemplateState extends State<DetailViewTemplate> {
  late Future<void> _future;

  // TODO: Replace with your model types
  MyModel? _item;
  List<RelatedModel> _relatedItems = [];

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _loadData() async {
    // TODO: Implement your data loading logic
    // _item = await MyModel.getById(widget.itemId);
    // _relatedItems = await RelatedModel.getByParentId(widget.itemId);

    // Example implementation:
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    _item = (id: widget.itemId, name: 'Item ${widget.itemId}', description: 'This is a description for the item.');
    _relatedItems = [
      (id: '1', name: 'Related Item 1'),
      (id: '2', name: 'Related Item 2'),
    ];

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshData() {
    setState(() {
      _future = _loadData();
    });
    return _future;
  }

  // TODO: Implement your delete logic
  Future<void> _deleteItem() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });
      try {
        // await MyModel.deleteById(widget.itemId);
        if (!mounted) return;
        Navigator.pop(context, true); // Return true to indicate success
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete item: $error')),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // TODO: Navigate to the form view to edit the item
  Future<void> _openEditForm() async {
    if (_item == null) return;
    // final bool? updated = await Navigator.push<bool>(
    //   context,
    //   MaterialPageRoute<bool>(
    //     builder: (_) => FormViewTemplate(item: _item),
    //   ),
    // );
    // if (updated == true) {
    //   _refreshData();
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to edit form')),
    );
  }

  // TODO: Navigate to the form view to add a related item
  Future<void> _openAddRelatedItemForm() async {
    // final bool? created = await Navigator.push<bool>(
    //   context,
    //   MaterialPageRoute<bool>(
    //     builder: (_) => RelatedItemFormView(),
    //   ),
    // );
    // if (created == true) {
    //   _refreshData();
    // }
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to add related item form')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      // TODO: Update title and current section
      title: 'Item Detail',
      currentSection: AppSection.pedidos,
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: FutureBuilder<void>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || _item == null) {
            return Center(child: Text('Error: ${snapshot.error ?? 'Item not found'}'));
          }

          final item = _item!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(item),
                const SizedBox(height: 16),
                _buildRelatedItemsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(MyModel item) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.name, style: theme.textTheme.titleLarge),
                ),
                TextButton.icon(
                  onPressed: _openEditForm,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isDeleting ? null : _deleteItem,
                  icon: _isDeleting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline),
                  label: Text(_isDeleting ? 'Deleting...' : 'Delete'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // TODO: Display your item's fields
            Text('ID: ${item.id}'),
            const SizedBox(height: 8),
            Text('Description: ${item.description}'),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedItemsSection() {
    // TODO: Define columns for the related items table
    final columns = <TableColumnConfig<RelatedModel>>[
      TableColumnConfig<RelatedModel>(
        label: 'ID',
        sortAccessor: (item) => item.id,
        cellBuilder: (item) => Text(item.id),
      ),
      TableColumnConfig<RelatedModel>(
        label: 'Name',
        sortAccessor: (item) => item.name,
        cellBuilder: (item) => Text(item.name),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  // TODO: Update title
                  child: Text('Related Items (${_relatedItems.length})', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: _openAddRelatedItemForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TableSection<RelatedModel>(
              items: _relatedItems,
              columns: columns,
              dense: true,
              emptyMessage: 'No related items found.',
            ),
          ],
        ),
      ),
    );
  }
}
