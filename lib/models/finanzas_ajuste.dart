import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class FinanzasAjuste {
  const FinanzasAjuste({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.idCuentaContable,
    this.cuentaContableCodigo,
    this.cuentaContableNombre,
    this.idCuentaBancaria,
    this.cuentaBancariaNombre,
    this.observacion,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String descripcion;
  final double monto;
  final String idCuentaContable;
  final String? cuentaContableCodigo;
  final String? cuentaContableNombre;
  final String? idCuentaBancaria;
  final String? cuentaBancariaNombre;
  final String? observacion;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory FinanzasAjuste.fromJson(Map<String, dynamic> json) {
    return FinanzasAjuste(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      idCuentaContable: json['idcuenta_contable'] as String,
      cuentaContableCodigo: json['cuenta_contable_codigo'] as String?,
      cuentaContableNombre: json['cuenta_contable_nombre'] as String?,
      idCuentaBancaria: json['idcuenta_origen'] as String? ??
          json['idcuenta_destino'] as String?,
      cuentaBancariaNombre: json['cuenta_bancaria_nombre'] as String?,
      observacion: json['observacion'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<FinanzasAjuste>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? cuentaId,
    String? cuentaContableId,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_finanzas_ajustes_dinero')
            as PostgrestFilterBuilder<dynamic>;

    if (from != null) {
      query = query.gte('registrado_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('registrado_at', to.toIso8601String());
    }
    if (cuentaId != null && cuentaId.isNotEmpty) {
      query = query.or(
        'idcuenta_origen.eq.$cuentaId,idcuenta_destino.eq.$cuentaId',
      );
    }
    if (cuentaContableId != null && cuentaContableId.isNotEmpty) {
      query = query.eq('idcuenta_contable', cuentaContableId);
    }

    final List<dynamic> rows = await query
        .select(
          'id,descripcion,monto,idcuenta_contable,cuenta_contable_codigo,cuenta_contable_nombre,idcuenta_destino,idcuenta_origen,cuenta_bancaria_nombre,observacion,registrado_at,registrado_por',
        )
        .order('registrado_at', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              FinanzasAjuste.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<String> create({
    required String descripcion,
    required double monto,
    required String cuentaContableId,
    String? cuentaBancariaId,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'tipo': 'ajuste',
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_contable': cuentaContableId,
      'observacion': observacion,
    };
    if (cuentaBancariaId != null && cuentaBancariaId.isNotEmpty) {
      payload['idcuenta_origen'] = cuentaBancariaId;
    }

    final Map<String, dynamic> inserted = await _supabase
        .from('movimientos_financieros')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String descripcion,
    required double monto,
    required String cuentaContableId,
    String? cuentaBancariaId,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_contable': cuentaContableId,
      'observacion': observacion,
      'idcuenta_origen': null,
      'idcuenta_destino': null,
    };
    if (cuentaBancariaId != null && cuentaBancariaId.isNotEmpty) {
      payload['idcuenta_origen'] = cuentaBancariaId;
    }

    await _supabase
        .from('movimientos_financieros')
        .update(payload)
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('movimientos_financieros').delete().eq('id', id);
  }
}
