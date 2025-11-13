import 'package:flutter/material.dart';

import 'package:demo_pedidos/models/logistica_base.dart';
import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';
import 'package:demo_pedidos/ui/standard_data_table.dart';
import 'package:demo_pedidos/ui/table/table_section.dart';

import '../detail/base_detail_view.dart';
import '../form/bases_form_view.dart';

class BasesListView extends StatefulWidget {
  const BasesListView({
    super.key,
    this.currentSection = AppSection.bases,
  });

  final AppSection currentSection;

  @override
  State<BasesListView> createState() => _BasesListViewState();
}

class _BasesListViewState extends State<BasesListView> {
  late Future<List<LogisticaBase>> _future;

  @override
  void initState() {
    super.initState();
    _future = LogisticaBase.getBases();
  }

  Future<void> _reload() async {
    setState(() {
      _future = LogisticaBase.getBases();
    });
    await _future;
  }

  Future<void> _openNuevaBase() async {
    final String? result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const BasesFormView(),
      ),
    );
    if (result != null) {
      _reload();
    }
  }

  Future<void> _openDetalle(LogisticaBase base) async {
    final bool? changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => BaseDetailView(
          baseId: base.id,
          currentSection: widget.currentSection,
        ),
      ),
    );
    if (changed == true) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bases',
      currentSection: widget.currentSection,
      actions: <Widget>[
        IconButton(
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualizar',
        ),
        IconButton(
          onPressed: _openNuevaBase,
          icon: const Icon(Icons.add_location_alt_outlined),
          tooltip: 'Agregar base',
        ),
      ],
      body: FutureBuilder<List<LogisticaBase>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<LogisticaBase>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('No se pudo cargar la lista de bases.'),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _reload,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<LogisticaBase> bases = snapshot.data ?? <LogisticaBase>[];
          if (bases.isEmpty) {
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Text('Aún no registras bases.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _openNuevaBase,
                          child: const Text('Agregar base'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return TableSection<LogisticaBase>(
            items: bases,
            onRefresh: _reload,
            searchTextBuilder: (LogisticaBase base) => base.nombre,
            searchPlaceholder: 'Buscar base',
            onRowTap: (LogisticaBase base) => _openDetalle(base),
            columns: <TableColumnConfig<LogisticaBase>>[
              TableColumnConfig<LogisticaBase>(
                label: 'Nombre',
                sortAccessor: (LogisticaBase base) => base.nombre,
                cellBuilder: (LogisticaBase base) => Text(base.nombre),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNuevaBase,
        child: const Icon(Icons.add),
      ),
    );
  }
}
