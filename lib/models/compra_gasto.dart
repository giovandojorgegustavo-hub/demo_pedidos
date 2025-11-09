import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

double _toDouble(dynamic value) {
  if (value == null) {
    return 0;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

class CompraGasto {
  const CompraGasto({
    required this.id,
    required this.idcompra,
    this.cuentaContable,
    this.idcuenta,
    required this.monto,
    this.observacion,
    this.cuentaNombre,
    this.registradoAt,
    this.editadoAt,
  });

  final String id;
  final String idcompra;
  final String? cuentaContable;
  final String? idcuenta;
  final double monto;
  final String? observacion;
  final String? cuentaNombre;
  final DateTime? registradoAt;
  final DateTime? editadoAt;

  factory CompraGasto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? cuenta =
        json['cuentas_bancarias'] as Map<String, dynamic>?;
    return CompraGasto(
      id: json['id'] as String,
      idcompra: json['idcompra'] as String,
      cuentaContable: json['cuenta_contable'] as String?,
      idcuenta: json['idcuenta'] as String?,
      monto: _toDouble(json['monto']),
      observacion: json['observacion'] as String?,
      cuentaNombre: json['cuenta_nombre'] as String? ??
          cuenta?['nombre'] as String?,
      registradoAt: _parseDate(json['registrado_at']),
      editadoAt: _parseDate(json['editado_at']),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idcompra': idcompra,
      'cuenta_contable': cuentaContable,
      'idcuenta': idcuenta,
      'monto': monto,
      'observacion': observacion,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'cuenta_contable': cuentaContable,
      'idcuenta': idcuenta,
      'monto': monto,
      'observacion': observacion,
      'editado_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<CompraGasto>> fetchByCompra(String compraId) async {
    final List<dynamic> rows = await _supabase
        .from('compras_gastos')
        .select('id,idcompra,cuenta_contable,idcuenta,monto,observacion,registrado_at,editado_at,cuentas_bancarias(nombre)')
        .eq('idcompra', compraId)
        .order('registrado_at', ascending: false);
    return rows
        .map((dynamic row) => CompraGasto.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<String> insert(CompraGasto gasto) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('compras_gastos')
        .insert(gasto.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(CompraGasto gasto) async {
    await _supabase
        .from('compras_gastos')
        .update(gasto.toUpdateJson())
        .eq('id', gasto.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('compras_gastos').delete().eq('id', id);
  }
}
