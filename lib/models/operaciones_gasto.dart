import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class OperacionesGasto {
  const OperacionesGasto({
    required this.origen,
    required this.idOperativo,
    required this.descripcion,
    required this.monto,
    this.idBase,
    this.baseNombre,
    this.idProducto,
    this.productoNombre,
    this.idCuenta,
    this.idCuentaContable,
    this.registradoAt,
    this.registradoPor,
  });

  final String origen;
  final String idOperativo;
  final String descripcion;
  final double monto;
  final String? idBase;
  final String? baseNombre;
  final String? idProducto;
  final String? productoNombre;
  final String? idCuenta;
  final String? idCuentaContable;
  final DateTime? registradoAt;
  final String? registradoPor;

  factory OperacionesGasto.fromJson(Map<String, dynamic> json) {
    return OperacionesGasto(
      origen: json['origen'] as String,
      idOperativo: json['idoperativo'] as String,
      descripcion: json['descripcion'] as String,
      monto: (json['monto'] as num).toDouble(),
      idBase: json['idbase'] as String?,
      baseNombre: json['base_nombre'] as String?,
      idProducto: json['idproducto'] as String?,
      productoNombre: json['producto_nombre'] as String?,
      idCuenta: json['idcuenta'] as String?,
      idCuentaContable: json['idcuenta_contable'] as String?,
      registradoAt: json['registrado_at'] == null
          ? null
          : DateTime.tryParse(json['registrado_at'] as String),
      registradoPor: json['registrado_por'] as String?,
    );
  }

  static Future<List<OperacionesGasto>> fetchAll({
    DateTime? from,
    DateTime? to,
    String? origen,
    String? baseId,
  }) async {
    PostgrestFilterBuilder<dynamic> query = _supabase
        .from('v_operaciones_gastos_union')
        .select(
          'origen,idoperativo,descripcion,monto,idbase,base_nombre,idproducto,producto_nombre,idcuenta,idcuenta_contable,registrado_at,registrado_por',
        );

    if (from != null) {
      query = query.gte('registrado_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('registrado_at', to.toIso8601String());
    }
    if (origen != null && origen.isNotEmpty) {
      query = query.eq('origen', origen);
    }
    if (baseId != null && baseId.isNotEmpty) {
      query = query.eq('idbase', baseId);
    }

    final List<dynamic> rows = await query.order(
      'registrado_at',
      ascending: false,
    );
    return rows
        .map((dynamic row) =>
            OperacionesGasto.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }
}
