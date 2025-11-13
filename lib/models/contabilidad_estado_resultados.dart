import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class ContabilidadEstadoResultados {
  const ContabilidadEstadoResultados({
    required this.periodo,
    required this.totalIngresos,
    required this.totalGastos,
    required this.resultado,
  });

  final DateTime periodo;
  final double totalIngresos;
  final double totalGastos;
  final double resultado;

  factory ContabilidadEstadoResultados.fromJson(Map<String, dynamic> json) {
    return ContabilidadEstadoResultados(
      periodo: DateTime.parse(json['periodo'] as String),
      totalIngresos: (json['total_ingresos'] as num).toDouble(),
      totalGastos: (json['total_gastos'] as num).toDouble(),
      resultado: (json['resultado'] as num).toDouble(),
    );
  }

  static Future<List<ContabilidadEstadoResultados>> fetchAll({
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _supabase
        .from('v_finanzas_estado_resultados')
        .select('periodo,total_ingresos,total_gastos,resultado');

    if (from != null) {
      query = query.gte('periodo', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('periodo', to.toIso8601String());
    }

    final List<dynamic> rows = await query.order('periodo', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              ContabilidadEstadoResultados.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
