import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:demo_pedidos/features/administracion/presentation/list/perfiles_list_view.dart';
import 'package:demo_pedidos/features/clientes/presentation/list/clientes_list_view.dart';
import 'package:demo_pedidos/features/cuentas/presentation/list/cuentas_list_view.dart';
import 'package:demo_pedidos/features/pedidos/presentation/list/pedidos_list_view.dart';
import 'package:demo_pedidos/features/viajes/presentation/list/viaje_detalles_list_view.dart';
import 'package:demo_pedidos/features/operaciones/presentation/operaciones_dashboard_view.dart';
import 'package:demo_pedidos/services/module_access_service.dart';
import 'package:demo_pedidos/shared/module_definitions.dart';

class ModulesDashboardView extends StatefulWidget {
  const ModulesDashboardView({super.key});

  @override
  State<ModulesDashboardView> createState() => _ModulesDashboardViewState();
}

class _ModulesDashboardViewState extends State<ModulesDashboardView> {
  late Future<Set<String>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = ModuleAccessService().loadModulesForCurrentUser();
  }

  void _reload() {
    setState(() {
      _modulesFuture = ModuleAccessService().loadModulesForCurrentUser();
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _openModule(String moduleId) {
    Widget builder() {
      switch (moduleId) {
        case 'pedidos':
          return const PedidosListView();
        case 'operaciones':
          return const OperacionesDashboardView();
        case 'almacen':
          return const ViajeDetallesListView();
        case 'bases':
          return const ClientesListView();
        case 'finanzas':
          return const CuentasListView();
        case 'administracion':
          return const PerfilesListView();
        default:
          return const PedidosListView();
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => builder()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tus módulos'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Set<String>>(
        future: _modulesFuture,
        builder: (BuildContext context, AsyncSnapshot<Set<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _DashboardMessage(
              icon: Icons.error_outline,
              title: 'No se pudieron cargar los módulos',
              message: '${snapshot.error}',
              onRetry: _reload,
            );
          }
          final Set<String> modules = snapshot.data ?? <String>{};
          if (modules.isEmpty) {
            return _DashboardMessage(
              icon: Icons.help_outline,
              title: 'Sin módulos asignados',
              message:
                  'Tu usuario todavía no tiene módulos configurados. Solicita acceso a un administrador.',
              onRetry: _reload,
            );
          }

          final List<ModuleDefinition> cards = modules
              .map((String id) => kModuleCatalog[id])
              .whereType<ModuleDefinition>()
              .toList()
            ..sort((ModuleDefinition a, ModuleDefinition b) =>
                a.title.compareTo(b.title));

          return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.of(context).size.width;
              final bool isDesktop = width >= 1100;
              final bool isTablet = width >= 600 && width < 1100;
              final int columns = isDesktop ? 3 : 2;
              final double aspectRatio = isDesktop
                  ? 5 / 3
                  : isTablet
                      ? 4 / 3
                      : 0.85; // tarjetas más altas en móviles
              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final ModuleDefinition module = cards[index];
                    return _ModuleCard(
                      definition: module,
                      onTap: () => _openModule(module.id),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.definition,
    required this.onTap,
  });

  final ModuleDefinition definition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final ThemeData theme = Theme.of(context);
        final bool compact = constraints.maxWidth < 180;
        final TextStyle titleStyle = compact
            ? theme.textTheme.titleMedium!
                .copyWith(fontWeight: FontWeight.w600)
            : theme.textTheme.titleLarge!;
        final TextStyle bodyStyle =
            theme.textTheme.bodyMedium ?? const TextStyle();
        final bool showDescription =
            !compact && definition.description.trim().isNotEmpty;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    definition.icon,
                    size: compact ? 26 : 32,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    definition.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 8),
                  if (showDescription)
                    Expanded(
                      child: Text(
                        definition.description,
                        maxLines: compact ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: bodyStyle,
                      ),
                    )
                  else
                    const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: onTap,
                      child: const Text('Ingresar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon,
                size: 48, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
