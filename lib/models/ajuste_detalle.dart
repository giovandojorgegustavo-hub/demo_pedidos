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

class AjusteDetalle {
  const AjusteDetalle({
    this.id,
    required this.idajuste,
    required this.idproducto,
    required this.cantidad,
    this.cantidadSistema,
    this.cantidadReal,
    this.productoNombre,
  });

  final String? id;
  final String idajuste;
  final String idproducto;
  final double cantidad;
  final double? cantidadSistema;
  final double? cantidadReal;
  final String? productoNombre;

  factory AjusteDetalle.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? productoJson =
        json['productos'] as Map<String, dynamic>?;
    final dynamic productoNombreRaw = json['producto_nombre'];
    String? productoNombre;
    if (productoNombreRaw is String) {
      productoNombre = productoNombreRaw;
    } else if (productoNombreRaw is Map<String, dynamic>) {
      final dynamic nombre = productoNombreRaw['nombre'];
      if (nombre is String) {
        productoNombre = nombre;
      }
    }
    productoNombre ??= productoJson?['nombre'] as String?;
    return AjusteDetalle(
      id: json['id'] as String?,
      idajuste: json['idajuste'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      cantidadSistema: json['cantidad_sistema'] == null
          ? null
          : _toDouble(json['cantidad_sistema']),
      cantidadReal: json['cantidad_real'] == null
          ? null
          : _toDouble(json['cantidad_real']),
      productoNombre: productoNombre,
    );
  }

  static Future<List<AjusteDetalle>> fetchByAjuste(String ajusteId) async {
    final List<dynamic> rows = await _supabase
        .from('ajustes_detalle')
        .select(
          'id,idajuste,idproducto,cantidad,cantidad_sistema,cantidad_real,producto_nombre:productos(nombre)',
        )
        .eq('idajuste', ajusteId)
        .order('registrado_at');
    return rows
        .map((dynamic row) =>
            AjusteDetalle.fromJson(row as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Future<void> replaceForAjuste(
    String ajusteId,
    List<AjusteDetalle> detalles,
  ) async {
    await _supabase
        .from('ajustes_detalle')
        .delete()
        .eq('idajuste', ajusteId);
    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map(
          (AjusteDetalle detalle) => <String, dynamic>{
            'idajuste': ajusteId,
            'idproducto': detalle.idproducto,
            'cantidad': detalle.cantidad,
            'cantidad_sistema': detalle.cantidadSistema,
            'cantidad_real': detalle.cantidadReal,
          },
        )
        .toList(growable: false);
    await _supabase.from('ajustes_detalle').insert(payload);
  }
}
