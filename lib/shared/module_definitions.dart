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
    sections: <AppSection>[
      AppSection.pedidos,
      AppSection.movimientos,
      AppSection.viajes,
      AppSection.viajesDetalle,
    ],
  ),
  'operaciones': ModuleDefinition(
    id: 'operaciones',
    title: 'Operaciones',
    description: 'Stock, compras y movimientos de inventario.',
    icon: Icons.local_shipping_outlined,
    sections: <AppSection>[
      AppSection.operacionesStock,
      AppSection.operacionesHistorial,
      AppSection.operacionesCompras,
      AppSection.operacionesTransferencias,
      AppSection.operacionesFabricacion,
      AppSection.operacionesAjustes,
      AppSection.operacionesGastos,
      AppSection.proveedores,
      AppSection.operacionesBases,
      AppSection.operacionesProductos,
    ],
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
    sections: <AppSection>[
      AppSection.bases,
      AppSection.clientes,
      AppSection.productos,
    ],
  ),
  'finanzas': ModuleDefinition(
    id: 'finanzas',
    title: 'Finanzas',
    description: 'Cuentas bancarias y movimientos de dinero.',
    icon: Icons.account_balance_wallet_outlined,
    sections: <AppSection>[
      AppSection.finanzasPagos,
      AppSection.finanzasGastos,
      AppSection.finanzasGastosOperativos,
      AppSection.finanzasCuentas,
      AppSection.finanzasGastosPedidos,
      AppSection.finanzasTransferencias,
      AppSection.finanzasAjustes,
      AppSection.bancos,
    ],
  ),
  'administracion': ModuleDefinition(
    id: 'administracion',
    title: 'Administración',
    description: 'Gestión de usuarios y perfiles internos.',
    icon: Icons.admin_panel_settings_outlined,
    sections: <AppSection>[AppSection.usuarios],
  ),
  'contabilidad': ModuleDefinition(
    id: 'contabilidad',
    title: 'Contabilidad',
    description: 'Reportes financieros consolidados.',
    icon: Icons.bar_chart_outlined,
    sections: <AppSection>[
      AppSection.contabilidadBalanceMensual,
      AppSection.contabilidadEstadoResultados,
      AppSection.contabilidadBalanceGeneral,
    ],
  ),
  'reportes': ModuleDefinition(
    id: 'reportes',
    title: 'Reportes',
    description: 'Ganancias y KPIs operativos.',
    icon: Icons.query_stats_outlined,
    sections: <AppSection>[
      AppSection.reportesGananciaDiaria,
      AppSection.reportesGananciaMensual,
      AppSection.reportesGananciaClientes,
      AppSection.reportesGananciaBases,
    ],
  ),
  'asistencias': ModuleDefinition(
    id: 'asistencias',
    title: 'Asistencias',
    description: 'Slots, asignaciones y control de asistencias.',
    icon: Icons.schedule_outlined,
    sections: <AppSection>[
      AppSection.asistenciasSlots,
      AppSection.asistenciasBaseSlots,
      AppSection.asistenciasMarcar,
      AppSection.asistenciasHistorial,
    ],
  ),
  'comunicaciones': ModuleDefinition(
    id: 'comunicaciones',
    title: 'Comunicaciones',
    description: 'Incidencias y comunicaciones internas.',
    icon: Icons.report_problem_outlined,
    sections: <AppSection>[
      AppSection.comunicacionesIncidentes,
      AppSection.comunicacionesInternas,
    ],
  ),
};

const Map<AppSection, String> kSectionModuleMap = <AppSection, String>{
  AppSection.pedidos: 'pedidos',
  AppSection.movimientos: 'pedidos',
  AppSection.viajes: 'pedidos',
  AppSection.viajesDetalle: 'almacen',
  AppSection.operacionesStock: 'operaciones',
  AppSection.operacionesHistorial: 'operaciones',
  AppSection.operacionesCompras: 'operaciones',
  AppSection.operacionesTransferencias: 'operaciones',
  AppSection.operacionesFabricacion: 'operaciones',
  AppSection.operacionesAjustes: 'operaciones',
  AppSection.operacionesGastos: 'operaciones',
  AppSection.operacionesBases: 'operaciones',
  AppSection.operacionesProductos: 'operaciones',
  AppSection.proveedores: 'operaciones',
  AppSection.productos: 'bases',
  AppSection.bases: 'bases',
  AppSection.clientes: 'bases',
  AppSection.bancos: 'finanzas',
  AppSection.finanzasPagos: 'finanzas',
  AppSection.finanzasGastos: 'finanzas',
  AppSection.finanzasCuentas: 'finanzas',
  AppSection.finanzasGastosOperativos: 'finanzas',
  AppSection.finanzasGastosPedidos: 'finanzas',
  AppSection.finanzasTransferencias: 'finanzas',
  AppSection.finanzasAjustes: 'finanzas',
  AppSection.contabilidadBalanceMensual: 'contabilidad',
  AppSection.contabilidadEstadoResultados: 'contabilidad',
  AppSection.contabilidadBalanceGeneral: 'contabilidad',
  AppSection.reportesGananciaDiaria: 'reportes',
  AppSection.reportesGananciaMensual: 'reportes',
  AppSection.reportesGananciaClientes: 'reportes',
  AppSection.reportesGananciaBases: 'reportes',
  AppSection.asistenciasSlots: 'asistencias',
  AppSection.asistenciasBaseSlots: 'asistencias',
  AppSection.asistenciasMarcar: 'asistencias',
  AppSection.asistenciasHistorial: 'asistencias',
  AppSection.comunicacionesIncidentes: 'comunicaciones',
  AppSection.comunicacionesInternas: 'comunicaciones',
  AppSection.usuarios: 'administracion',
};
