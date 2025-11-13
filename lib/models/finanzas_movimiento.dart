import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class FinanzasMovimiento {
  const FinanzasMovimiento({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.monto,
    this.idCuentaContable,
    this.cuentaContableCodigo,
    this.cuentaContableNombre,
    this.idCuentaOrigen,
    this.idCuentaDestino,
    this.cuentaBancariaNombre,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String tipo;
  final String descripcion;
  final double monto;
  final String? idCuentaContable;
  final String? cuentaContableCodigo;
  final String? cuentaContableNombre;
  final String? idCuentaOrigen;
  final String? idCuentaDestino;
  final String? cuentaBancariaNombre;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory FinanzasMovimiento.fromJson(Map<String, dynamic> json) {
    return FinanzasMovimiento(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      idCuentaContable: json['idcuenta_contable'] as String?,
      cuentaContableCodigo: json['cuenta_contable_codigo'] as String?,
      cuentaContableNombre: json['cuenta_contable_nombre'] as String?,
      idCuentaOrigen: json['idcuenta_origen'] as String?,
      idCuentaDestino: json['idcuenta_destino'] as String?,
      cuentaBancariaNombre: json['cuenta_bancaria_nombre'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<FinanzasMovimiento>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? tipo,
    String? cuentaContableId,
    String? cuentaBancariaId,
  }) async {
    var query = _supabase
        .from('v_finanzas_movimientos_ingresos_gastos')
        .select(
          'id,tipo,descripcion,monto,idcuenta_contable,cuenta_contable_codigo,cuenta_contable_nombre,idcuenta_origen,idcuenta_destino,cuenta_bancaria_nombre,registrado_at,registrado_por',
        );

    if (from != null) {
      query = query.gte('registrado_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('registrado_at', to.toIso8601String());
    }
    if (tipo != null && tipo.isNotEmpty) {
      query = query.eq('tipo', tipo);
    }
    if (cuentaContableId != null && cuentaContableId.isNotEmpty) {
      query = query.eq('idcuenta_contable', cuentaContableId);
    }
    if (cuentaBancariaId != null && cuentaBancariaId.isNotEmpty) {
      query = query.or(
        'idcuenta_origen.eq.$cuentaBancariaId,idcuenta_destino.eq.$cuentaBancariaId',
      );
    }

    final List<dynamic> rows =
        await query.order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) =>
            FinanzasMovimiento.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> create({
    required String tipo,
    required String descripcion,
    required double monto,
    required String idCuentaContable,
    String? idCuentaBancaria,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'tipo': tipo,
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_contable': idCuentaContable,
      'observacion': observacion,
    };

    if (idCuentaBancaria != null && idCuentaBancaria.isNotEmpty) {
      if (tipo == 'ingreso') {
        payload['idcuenta_destino'] = idCuentaBancaria;
      } else {
        payload['idcuenta_origen'] = idCuentaBancaria;
      }
    }

    payload.removeWhere((String key, dynamic value) => value == null);

    final Map<String, dynamic> inserted = await _supabase
        .from('movimientos_financieros')
        .insert(payload)
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update({
    required String id,
    required String tipo,
    required String descripcion,
    required double monto,
    required String idCuentaContable,
    String? idCuentaBancaria,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'tipo': tipo,
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_contable': idCuentaContable,
      'observacion': observacion,
      'idcuenta_origen': null,
      'idcuenta_destino': null,
    };

    if (idCuentaBancaria != null && idCuentaBancaria.isNotEmpty) {
      if (tipo == 'ingreso') {
        payload['idcuenta_destino'] = idCuentaBancaria;
      } else {
        payload['idcuenta_origen'] = idCuentaBancaria;
      }
    }

    payload.removeWhere((String key, dynamic value) => value == null);

    await _supabase
        .from('movimientos_financieros')
        .update(payload)
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('movimientos_financieros').delete().eq('id', id);
  }
}
