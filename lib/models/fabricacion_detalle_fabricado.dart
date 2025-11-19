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

class FabricacionDetalleFabricado {
  const FabricacionDetalleFabricado({
    this.id,
    required this.idfabricacion,
    required this.idproducto,
    required this.cantidad,
    this.productoNombre,
    this.costoUnitario = 0,
    this.costoTotal = 0,
  });

  final String? id;
  final String idfabricacion;
  final String idproducto;
  final double cantidad;
  final String? productoNombre;
  final double costoUnitario;
  final double costoTotal;

  FabricacionDetalleFabricado copyWith({
    String? id,
    String? idfabricacion,
    String? idproducto,
    double? cantidad,
    String? productoNombre,
    double? costoUnitario,
    double? costoTotal,
  }) {
    return FabricacionDetalleFabricado(
      id: id ?? this.id,
      idfabricacion: idfabricacion ?? this.idfabricacion,
      idproducto: idproducto ?? this.idproducto,
      cantidad: cantidad ?? this.cantidad,
      productoNombre: productoNombre ?? this.productoNombre,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      costoTotal: costoTotal ?? this.costoTotal,
    );
  }

  factory FabricacionDetalleFabricado.fromJson(Map<String, dynamic> json) {
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
    return FabricacionDetalleFabricado(
      id: json['id'] as String?,
      idfabricacion: json['idfabricacion'] as String,
      idproducto: json['idproducto'] as String,
      cantidad: _toDouble(json['cantidad']),
      productoNombre: productoNombre,
      costoUnitario: _toDouble(json['costo_unitario']),
      costoTotal: _toDouble(json['costo_total']),
    );
  }

  static Future<List<FabricacionDetalleFabricado>> fetchByFabricacion(
    String fabricacionId,
  ) async {
    final List<dynamic> rows = await _supabase
        .from('fabricacion_det_fabricado')
        .select(
          'id,idfabricacion,idproducto,cantidad,costo_unitario,costo_total,producto_nombre:productos(nombre)',
        )
        .eq('idfabricacion', fabricacionId)
        .order('registrado_at');
    return rows
        .map((dynamic row) => FabricacionDetalleFabricado.fromJson(
              row as Map<String, dynamic>,
            ))
        .toList(growable: false);
  }

  static Future<void> replaceForFabricacion(
    String fabricacionId,
    List<FabricacionDetalleFabricado> detalles,
  ) async {
    await _supabase
        .from('fabricacion_det_fabricado')
        .delete()
        .eq('idfabricacion', fabricacionId);
    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map(
          (FabricacionDetalleFabricado detalle) => <String, dynamic>{
            'idfabricacion': fabricacionId,
            'idproducto': detalle.idproducto,
            'cantidad': detalle.cantidad,
            'costo_unitario': detalle.costoUnitario,
            'costo_total': detalle.costoTotal,
          },
        )
        .toList(growable: false);
    await _supabase.from('fabricacion_det_fabricado').insert(payload);
  }
}
