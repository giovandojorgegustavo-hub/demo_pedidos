import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class StockPorBase {
  const StockPorBase({
    required this.idbase,
    required this.baseNombre,
    required this.idproducto,
    required this.productoNombre,
    required this.cantidad,
  });

  final String? idbase;
  final String baseNombre;
  final String idproducto;
  final String productoNombre;
  final double cantidad;

  factory StockPorBase.fromJson(Map<String, dynamic> json) {
    return StockPorBase(
      idbase: json['idbase'] as String?,
      baseNombre: (json['base_nombre'] as String?) ?? '-',
      idproducto: json['idproducto'] as String,
      productoNombre: (json['producto_nombre'] as String?) ?? 'Producto',
      cantidad: _parseDouble(json['cantidad']),
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

  static Future<List<StockPorBase>> fetchAll() async {
    final List<dynamic> data = await _supabase
        .from('v_stock_por_base')
        .select('idbase,base_nombre,idproducto,producto_nombre,cantidad');
    return data
        .map((dynamic item) =>
            StockPorBase.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
