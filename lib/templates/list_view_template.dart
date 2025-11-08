import 'package:demo_pedidos/shared/app_sections.dart';

import 'package:flutter/material.dart';

// TODO: Import your model, detail view, and form view
// import 'package:demo_pedidos/models/my_model.dart';
// import 'package:demo_pedidos/features/my_feature/presentation/detail/my_model_detail_view.dart';
// import 'package:demo_pedidos/features/my_feature/presentation/form/my_model_form_view.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

// TODO: Replace 'MyModel' with your model name (e.g., Cliente, Producto)
typedef MyModel = ({String id, String name}); // Example model

class ListViewTemplate extends StatefulWidget {
  const ListViewTemplate({super.key});

  @override
  State<ListViewTemplate> createState() => _ListViewTemplateState();
}

class _ListViewTemplateState extends State<ListViewTemplate> {
  // TODO: Replace 'MyModel' with your model type
  late Future<List<MyModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _loadData();
    });
    try {
      await _future;
    } catch (_) {
      // Error is handled by the FutureBuilder
    }
  }

  // TODO: Implement your data loading logic
  Future<List<MyModel>> _loadData() async {
    // Example implementation:
    // final List<MyModel> items = await MyModel.getAll();
    // return items;
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return [
      (id: '1', name: 'Item 1'),
      (id: '2', name: 'Item 2'),
    ];
  }

  // TODO: Define the columns for your table
  List<TableColumnConfig<MyModel>> get _columns {
    return <TableColumnConfig<MyModel>>[
      TableColumnConfig<MyModel>(
        label: 'ID',
        sortAccessor: (MyModel item) => item.id,
        cellBuilder: (MyModel item) => Text(item.id),
      ),
      TableColumnConfig<MyModel>(
        label: 'Name',
        sortAccessor: (MyModel item) => item.name,
        cellBuilder: (MyModel item) => Text(item.name),
      ),
    ];
  }

  // TODO: Define the filters for your table
  List<TableFilterConfig<MyModel>> get _filters {
    return <TableFilterConfig<MyModel>>[
      // Example filter:
      // TableFilterConfig<MyModel>(
      //   label: 'Status',
      //   options: <TableFilterOption<MyModel>>[
      //     const TableFilterOption<MyModel>(label: 'All', isDefault: true),
      //     TableFilterOption<MyModel>(
      //       label: 'Active',
      //       predicate: (MyModel item) => item.isActive,
      //     ),
      //   ],
      // ),
    ];
  }

  // TODO: Navigate to the detail view for the selected item
  void _openDetail(MyModel item) {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute<void>(
    //     builder: (_) => MyModelDetailView(itemId: item.id),
    //   ),
    // ).then((_) => _reload());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to detail for ${item.name}')),
    );
  }

  // TODO: Navigate to the form view to create a new item
  void _openCreate() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute<void>(
    //     builder: (_) => const MyModelFormView(),
    //   ),
    // ).then((Object? result) {
    //   if (result == true) {
    //     _reload();
    //   }
    // });
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to create form')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      // TODO: Update the title and current section
      title: 'List of Items',
      currentSection: AppSection.pedidos, // Example section
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: FutureBuilder<List<MyModel>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<MyModel>> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Could not load the list.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<MyModel> items = snap.data ?? <MyModel>[];

          return TableSection<MyModel>(
            items: items,
            columns: _columns,
            onRowTap: _openDetail,
            onRefresh: _reload,
            filters: _filters,
            // TODO: Define the search text builder
            searchTextBuilder: (MyModel item) => item.name,
            searchPlaceholder: 'Search by name',
            emptyMessage: 'No items found.',
            noResultsMessage: 'No items match the selected filters.',
            minTableWidth: 600,
            dense: true,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
    );
  }
}
