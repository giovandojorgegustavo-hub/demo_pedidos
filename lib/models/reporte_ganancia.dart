import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString()) ?? 0;
}

class ReporteGananciaDiaria {
  const ReporteGananciaDiaria({
    required this.fecha,
    required this.pedidos,
    required this.totalVenta,
    required this.totalCosto,
    required this.ganancia,
    required this.margen,
  });

  final DateTime fecha;
  final int pedidos;
  final double totalVenta;
  final double totalCosto;
  final double ganancia;
  final double margen;

  factory ReporteGananciaDiaria.fromJson(Map<String, dynamic> json) {
    return ReporteGananciaDiaria(
      fecha: DateTime.parse(json['fecha'] as String),
      pedidos: _toInt(json['pedidos']),
      totalVenta: _toDouble(json['total_venta']),
      totalCosto: _toDouble(json['total_costo']),
      ganancia: _toDouble(json['ganancia']),
      margen: _toDouble(json['margen_porcentaje']),
    );
  }

  static Future<List<ReporteGananciaDiaria>> fetch({
    DateTime? from,
    DateTime? to,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_reportes_ganancia_diaria').select(
              'fecha,pedidos,total_venta,total_costo,ganancia,margen_porcentaje',
            );

    if (from != null) {
      query = query.gte('fecha', _formatDate(from));
    }
    if (to != null) {
      query = query.lte('fecha', _formatDate(to));
    }

    final List<dynamic> rows = await query.order('fecha', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              ReporteGananciaDiaria.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

class ReporteGananciaMensual {
  const ReporteGananciaMensual({
    required this.periodo,
    required this.pedidos,
    required this.totalVenta,
    required this.totalCosto,
    required this.ganancia,
    required this.margen,
  });

  final DateTime periodo;
  final int pedidos;
  final double totalVenta;
  final double totalCosto;
  final double ganancia;
  final double margen;

  factory ReporteGananciaMensual.fromJson(Map<String, dynamic> json) {
    return ReporteGananciaMensual(
      periodo: DateTime.parse(json['periodo'] as String),
      pedidos: _toInt(json['pedidos']),
      totalVenta: _toDouble(json['total_venta']),
      totalCosto: _toDouble(json['total_costo']),
      ganancia: _toDouble(json['ganancia']),
      margen: _toDouble(json['margen_porcentaje']),
    );
  }

  static Future<List<ReporteGananciaMensual>> fetch({
    DateTime? from,
    DateTime? to,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_reportes_ganancia_mensual').select(
              'periodo,pedidos,total_venta,total_costo,ganancia,margen_porcentaje',
            );

    if (from != null) {
      query = query.gte('periodo', _formatDate(from));
    }
    if (to != null) {
      query = query.lte('periodo', _formatDate(to));
    }

    final List<dynamic> rows = await query.order('periodo', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              ReporteGananciaMensual.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}

class ReporteGananciaClienteMensual {
  const ReporteGananciaClienteMensual({
    required this.periodo,
    required this.clienteId,
    required this.clienteNombre,
    required this.pedidos,
    required this.totalVenta,
    required this.totalCosto,
    required this.ganancia,
    required this.margen,
  });

  final DateTime periodo;
  final String? clienteId;
  final String? clienteNombre;
  final int pedidos;
  final double totalVenta;
  final double totalCosto;
  final double ganancia;
  final double margen;

  factory ReporteGananciaClienteMensual.fromJson(Map<String, dynamic> json) {
    return ReporteGananciaClienteMensual(
      periodo: DateTime.parse(json['periodo'] as String),
      clienteId: json['idcliente'] as String?,
      clienteNombre: json['cliente_nombre'] as String?,
      pedidos: _toInt(json['pedidos']),
      totalVenta: _toDouble(json['total_venta']),
      totalCosto: _toDouble(json['total_costo']),
      ganancia: _toDouble(json['ganancia']),
      margen: _toDouble(json['margen_porcentaje']),
    );
  }

  static Future<List<ReporteGananciaClienteMensual>> fetch({
    DateTime? from,
    DateTime? to,
    String? clienteId,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_reportes_ganancia_mensual_clientes').select(
              'periodo,idcliente,cliente_nombre,pedidos,total_venta,total_costo,ganancia,margen_porcentaje',
            );

    if (from != null) {
      query = query.gte('periodo', _formatDate(from));
    }
    if (to != null) {
      query = query.lte('periodo', _formatDate(to));
    }
    if (clienteId != null && clienteId.isNotEmpty) {
      query = query.eq('idcliente', clienteId);
    }

    final List<dynamic> rows = await query
        .order('periodo', ascending: false)
        .order('cliente_nombre', ascending: true);
    return rows
        .map(
          (dynamic row) => ReporteGananciaClienteMensual.fromJson(
            row as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }
}

class ReporteGananciaBaseMensual {
  const ReporteGananciaBaseMensual({
    required this.periodo,
    required this.baseId,
    required this.baseNombre,
    required this.pedidos,
    required this.totalVenta,
    required this.totalCosto,
    required this.ganancia,
    required this.margen,
  });

  final DateTime periodo;
  final String? baseId;
  final String? baseNombre;
  final int pedidos;
  final double totalVenta;
  final double totalCosto;
  final double ganancia;
  final double margen;

  factory ReporteGananciaBaseMensual.fromJson(Map<String, dynamic> json) {
    return ReporteGananciaBaseMensual(
      periodo: DateTime.parse(json['periodo'] as String),
      baseId: json['idbase'] as String?,
      baseNombre: json['base_nombre'] as String?,
      pedidos: _toInt(json['pedidos']),
      totalVenta: _toDouble(json['total_venta']),
      totalCosto: _toDouble(json['total_costo']),
      ganancia: _toDouble(json['ganancia']),
      margen: _toDouble(json['margen_porcentaje']),
    );
  }

  static Future<List<ReporteGananciaBaseMensual>> fetch({
    DateTime? from,
    DateTime? to,
    String? baseId,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_reportes_ganancia_mensual_bases').select(
              'periodo,idbase,base_nombre,pedidos,total_venta,total_costo,ganancia,margen_porcentaje',
            );

    if (from != null) {
      query = query.gte('periodo', _formatDate(from));
    }
    if (to != null) {
      query = query.lte('periodo', _formatDate(to));
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }

    final List<dynamic> rows = await query
        .order('periodo', ascending: false)
        .order('base_nombre', ascending: true);
    return rows
        .map(
          (dynamic row) =>
              ReporteGananciaBaseMensual.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
