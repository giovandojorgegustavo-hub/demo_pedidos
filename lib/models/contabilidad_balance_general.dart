import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class ContabilidadBalanceGeneral {
  const ContabilidadBalanceGeneral({
    required this.periodo,
    required this.tipo,
    required this.saldo,
  });

  final DateTime periodo;
  final String tipo;
  final double saldo;

  factory ContabilidadBalanceGeneral.fromJson(Map<String, dynamic> json) {
    return ContabilidadBalanceGeneral(
      periodo: DateTime.parse(json['periodo'] as String),
      tipo: json['tipo'] as String,
      saldo: (json['saldo'] as num).toDouble(),
    );
  }

  static Future<List<ContabilidadBalanceGeneral>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? tipo,
  }) async {
    var query = _supabase
        .from('v_finanzas_balance_general')
        .select('periodo,tipo,saldo');

    if (from != null) {
      query = query.gte('periodo', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('periodo', to.toIso8601String());
    }
    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo);
    }

    final List<dynamic> rows = await query.order('periodo', ascending: false);
    return rows
        .map(
          (dynamic row) => ContabilidadBalanceGeneral.fromJson(
              row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
