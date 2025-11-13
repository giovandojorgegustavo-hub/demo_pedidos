import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class FinanzasTransferencia {
  const FinanzasTransferencia({
    required this.id,
    required this.descripcion,
    required this.monto,
    required this.idCuentaOrigen,
    required this.idCuentaDestino,
    this.cuentaOrigenNombre,
    this.cuentaDestinoNombre,
    this.observacion,
    this.registradoAt,
    this.registradoPor,
  });

  final String id;
  final String descripcion;
  final double monto;
  final String idCuentaOrigen;
  final String idCuentaDestino;
  final String? cuentaOrigenNombre;
  final String? cuentaDestinoNombre;
  final String? observacion;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory FinanzasTransferencia.fromJson(Map<String, dynamic> json) {
    return FinanzasTransferencia(
      id: json['id'] as String,
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      idCuentaOrigen: json['idcuenta_origen'] as String,
      idCuentaDestino: json['idcuenta_destino'] as String,
      cuentaOrigenNombre: json['cuenta_origen_nombre'] as String?,
      cuentaDestinoNombre: json['cuenta_destino_nombre'] as String?,
      observacion: json['observacion'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<FinanzasTransferencia>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? cuentaOrigenId,
    String? cuentaDestinoId,
  }) async {
    PostgrestFilterBuilder<dynamic> query =
        _supabase.from('v_finanzas_transferencias_dinero')
            as PostgrestFilterBuilder<dynamic>;

    if (from != null) {
      query = query.gte('registrado_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('registrado_at', to.toIso8601String());
    }
    if (cuentaOrigenId != null && cuentaOrigenId.isNotEmpty) {
      query = query.eq('idcuenta_origen', cuentaOrigenId);
    }
    if (cuentaDestinoId != null && cuentaDestinoId.isNotEmpty) {
      query = query.eq('idcuenta_destino', cuentaDestinoId);
    }

    final List<dynamic> rows = await query
        .select(
          'id,descripcion,monto,idcuenta_origen,cuenta_origen_nombre,idcuenta_destino,cuenta_destino_nombre,observacion,registrado_at,registrado_por',
        )
        .order('registrado_at', ascending: false);
    return rows
        .map(
          (dynamic row) =>
              FinanzasTransferencia.fromJson(row as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  static Future<String> create({
    required String descripcion,
    required double monto,
    required String cuentaOrigenId,
    required String cuentaDestinoId,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'tipo': 'transferencia',
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_origen': cuentaOrigenId,
      'idcuenta_destino': cuentaDestinoId,
      'observacion': observacion,
    };

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
    required String cuentaOrigenId,
    required String cuentaDestinoId,
    String? observacion,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'descripcion': descripcion,
      'monto': monto,
      'idcuenta_origen': cuentaOrigenId,
      'idcuenta_destino': cuentaDestinoId,
      'observacion': observacion,
    };

    await _supabase
        .from('movimientos_financieros')
        .update(payload)
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _supabase.from('movimientos_financieros').delete().eq('id', id);
  }
}
