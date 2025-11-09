import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class StockMovimiento {
  const StockMovimiento({
    required this.idproducto,
    required this.productoNombre,
    required this.cantidad,
    required this.idbase,
    required this.baseNombre,
    required this.tipomov,
    required this.idoperativo,
    required this.registradoAt,
  });

  final String idproducto;
  final String productoNombre;
  final double cantidad;
  final String? idbase;
  final String baseNombre;
  final String tipomov;
  final String idoperativo;
  final DateTime? registradoAt;

  factory StockMovimiento.fromJson(Map<String, dynamic> json) {
    return StockMovimiento(
      idproducto: json['idproducto'] as String,
      productoNombre: (json['producto_nombre'] as String?) ?? 'Producto',
      cantidad: _parseDouble(json['cantidad']),
      idbase: json['idbase'] as String?,
      baseNombre: (json['base_nombre'] as String?) ?? '-',
      tipomov: (json['tipomov'] as String?) ?? 'desconocido',
      idoperativo: (json['idoperativo'] as String?) ?? '',
      registradoAt: _parseDate(json['registrado_at']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static Future<List<StockMovimiento>> fetchLatest({int limit = 500}) async {
    final List<dynamic> data = await _supabase
        .from('v_kardex_operativo')
        .select(
            'idproducto,producto_nombre,cantidad,idbase,base_nombre,tipomov,idoperativo,registrado_at')
        .order('registrado_at', ascending: false)
        .limit(limit);
    return data
        .map((dynamic item) =>
            StockMovimiento.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
