import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class Pago {
  const Pago({
    required this.id,
    required this.idpedido,
    required this.monto,
    required this.fechapago,
    this.idcuenta,
    this.cuentaNombre,
    this.fecharegistro,
  });

  final String id;
  final String idpedido;
  final double monto;
  final DateTime fechapago;
  final DateTime? fecharegistro;
  final String? idcuenta;
  final String? cuentaNombre;

  factory Pago.fromJson(Map<String, dynamic> json) {
    final dynamic montoValue = json['monto'];
    final dynamic pagoValue = json['fechapago'];
    final dynamic registroValue = json['fecharegistro'];
    final Map<String, dynamic>? cuenta =
        json['cuentas_bancarias'] as Map<String, dynamic>?;
    return Pago(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      monto:
          montoValue is num ? montoValue.toDouble() : double.tryParse('$montoValue') ?? 0,
      fechapago: pagoValue is String
          ? DateTime.parse(pagoValue)
          : (pagoValue is DateTime ? pagoValue : DateTime.now()),
      fecharegistro: registroValue == null
          ? null
          : (registroValue is String
              ? DateTime.tryParse(registroValue)
              : (registroValue is DateTime ? registroValue : null)),
      idcuenta: json['idcuenta'] as String?,
      cuentaNombre: cuenta?['nombre'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idpedido': idpedido,
      'monto': monto,
      'fechapago': fechapago.toIso8601String(),
      'idcuenta': idcuenta,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'monto': monto,
      'fechapago': fechapago.toIso8601String(),
      'idcuenta': idcuenta,
    };
  }

  static Future<List<Pago>> getByPedido(String pedidoId) async {
    final List<dynamic> data = await _supabase
        .from('pagos')
        .select(
          'id,idpedido,monto,fechapago,fecharegistro,idcuenta,cuentas_bancarias(nombre)',
        )
        .eq('idpedido', pedidoId)
        .order('fechapago', ascending: false);
    return data
        .map((dynamic item) => Pago.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<String> insert(Pago pago) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('pagos')
        .insert(pago.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('pagos').delete().eq('id', id);
  }

  static Future<void> update(Pago pago) async {
    await _supabase
        .from('pagos')
        .update(pago.toUpdateJson())
        .eq('id', pago.id);
  }
}
