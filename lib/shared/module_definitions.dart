import 'package:flutter/material.dart';

import 'package:demo_pedidos/shared/app_sections.dart';

class ModuleDefinition {
  const ModuleDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.sections,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final List<AppSection> sections;
}

const Map<String, ModuleDefinition> kModuleCatalog = <String, ModuleDefinition>{
  'pedidos': ModuleDefinition(
    id: 'pedidos',
    title: 'Pedidos',
    description: 'Registro, seguimiento y viajes asociados a pedidos.',
    icon: Icons.assignment_outlined,
    sections: <AppSection>[AppSection.pedidos, AppSection.viajes],
  ),
  'operaciones': ModuleDefinition(
    id: 'operaciones',
    title: 'Operaciones',
    description: 'Movimientos logísticos y control de entregas.',
    icon: Icons.local_shipping_outlined,
    sections: <AppSection>[AppSection.movimientos],
  ),
  'almacen': ModuleDefinition(
    id: 'almacen',
    title: 'Almacén',
    description: 'Detalle de viajes y asignaciones en ruta.',
    icon: Icons.inventory_2_outlined,
    sections: <AppSection>[AppSection.viajesDetalle],
  ),
  'bases': ModuleDefinition(
    id: 'bases',
    title: 'Catálogos',
    description: 'Clientes, productos y datos maestros.',
    icon: Icons.library_books_outlined,
    sections: <AppSection>[AppSection.clientes, AppSection.productos],
  ),
  'finanzas': ModuleDefinition(
    id: 'finanzas',
    title: 'Finanzas',
    description: 'Cuentas bancarias y movimientos de dinero.',
    icon: Icons.account_balance_wallet_outlined,
    sections: <AppSection>[AppSection.bancos],
  ),
  'administracion': ModuleDefinition(
    id: 'administracion',
    title: 'Administración',
    description: 'Gestión de usuarios y perfiles internos.',
    icon: Icons.admin_panel_settings_outlined,
    sections: <AppSection>[AppSection.usuarios],
  ),
};

const Map<AppSection, String> kSectionModuleMap = <AppSection, String>{
  AppSection.pedidos: 'pedidos',
  AppSection.viajes: 'pedidos',
  AppSection.movimientos: 'operaciones',
  AppSection.viajesDetalle: 'almacen',
  AppSection.productos: 'bases',
  AppSection.clientes: 'bases',
  AppSection.bancos: 'finanzas',
  AppSection.usuarios: 'administracion',
};
