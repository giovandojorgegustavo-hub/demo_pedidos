import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class ContabilidadBalanceMensual {
  const ContabilidadBalanceMensual({
    required this.periodo,
    required this.idCuentaContable,
    required this.cuentaContableCodigo,
    required this.cuentaContableNombre,
    required this.tipo,
    required this.saldo,
  });

  final DateTime periodo;
  final String idCuentaContable;
  final String cuentaContableCodigo;
  final String cuentaContableNombre;
  final String tipo;
  final double saldo;

  factory ContabilidadBalanceMensual.fromJson(Map<String, dynamic> json) {
    return ContabilidadBalanceMensual(
      periodo: DateTime.parse(json['periodo'] as String),
      idCuentaContable: json['idcuenta_contable'] as String,
      cuentaContableCodigo: json['cuenta_contable_codigo'] as String,
      cuentaContableNombre: json['cuenta_contable_nombre'] as String,
      tipo: json['tipo'] as String,
      saldo: (json['saldo'] as num).toDouble(),
    );
  }

  static Future<List<ContabilidadBalanceMensual>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? tipo,
    String? cuentaContableId,
  }) async {
    var query = _supabase
        .from('v_finanzas_balance_mensual')
        .select(
          'periodo,idcuenta_contable,cuenta_contable_codigo,cuenta_contable_nombre,tipo,saldo',
        );

    if (from != null) {
      query = query.gte('periodo', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('periodo', to.toIso8601String());
    }
    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo);
    }
    if (cuentaContableId != null && cuentaContableId.isNotEmpty) {
      query = query.eq('idcuenta_contable', cuentaContableId);
    }

    final List<dynamic> rows = await query.order('periodo', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              ContabilidadBalanceMensual.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }
}
