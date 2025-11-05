import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class DetalleMovimiento {
  const DetalleMovimiento({
    this.id,
    this.idmovimiento,
    required this.idproducto,
    required this.cantidad,
    this.productoNombre,
  });

  final String? id;
  final String? idmovimiento;
  final String idproducto;
  final double cantidad;
  final String? productoNombre;

  factory DetalleMovimiento.fromJson(Map<String, dynamic> json) {
    final dynamic cantidadValue = json['cantidad'];
    final Map<String, dynamic>? producto =
        json['productos'] as Map<String, dynamic>?;
    return DetalleMovimiento(
      id: json['id'] as String?,
      idmovimiento: json['idmovimiento'] as String?,
      idproducto: json['idproducto'] as String,
      cantidad: cantidadValue is num
          ? cantidadValue.toDouble()
          : double.tryParse('$cantidadValue') ?? 0,
      productoNombre: producto?['nombre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'idproducto': idproducto,
      'cantidad': cantidad,
    };
  }

  static Future<List<DetalleMovimiento>> getByMovimiento(
      String movimientoId) async {
    final List<dynamic> data = await _supabase
        .from('detallemovimientopedidos')
        .select('id,idmovimiento,idproducto,cantidad,productos(nombre)')
        .eq('idmovimiento', movimientoId)
        .order('created_at');
    return data
        .map(
          (dynamic item) =>
              DetalleMovimiento.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static Future<void> replaceForMovimiento(
    String movimientoId,
    List<DetalleMovimiento> detalles,
  ) async {
    await _supabase
        .from('detallemovimientopedidos')
        .delete()
        .eq('idmovimiento', movimientoId);

    if (detalles.isEmpty) {
      return;
    }
    final List<Map<String, dynamic>> payload = detalles
        .map((DetalleMovimiento detalle) {
          final Map<String, dynamic> json = detalle.toJson();
          json
            ..remove('id')
            ..remove('idmovimiento');
          json['idmovimiento'] = movimientoId;
          return json;
        })
        .toList();
    await _supabase.from('detallemovimientopedidos').insert(payload);
  }
}
