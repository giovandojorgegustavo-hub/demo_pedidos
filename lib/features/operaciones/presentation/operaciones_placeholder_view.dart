import 'package:flutter/material.dart';

import 'package:demo_pedidos/shared/app_sections.dart';
import 'package:demo_pedidos/ui/page_scaffold.dart';

class OperacionesComprasView extends StatelessWidget {
  const OperacionesComprasView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OperacionesPlaceholderView(
      section: AppSection.operacionesCompras,
      title: 'Compras',
      description:
          'Muy pronto podrás registrar y monitorear tus órdenes de compra.',
    );
  }
}

class OperacionesTransferenciasView extends StatelessWidget {
  const OperacionesTransferenciasView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OperacionesPlaceholderView(
      section: AppSection.operacionesTransferencias,
      title: 'Transferencias',
      description:
          'Aquí verás los traslados entre bases y el estado de cada envío.',
    );
  }
}

class OperacionesFabricacionView extends StatelessWidget {
  const OperacionesFabricacionView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OperacionesPlaceholderView(
      section: AppSection.operacionesFabricacion,
      title: 'Fabricación',
      description:
          'En esta sección quedarán los procesos de producción y consumo.',
    );
  }
}

class OperacionesAjustesView extends StatelessWidget {
  const OperacionesAjustesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _OperacionesPlaceholderView(
      section: AppSection.operacionesAjustes,
      title: 'Ajustes',
      description:
          'Gestiona ajustes de inventario y regularizaciones desde aquí.',
    );
  }
}

class _OperacionesPlaceholderView extends StatelessWidget {
  const _OperacionesPlaceholderView({
    required this.section,
    required this.title,
    required this.description,
  });

  final AppSection section;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: title,
      currentSection: section,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 16),
              Text(
                'En construcción',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
