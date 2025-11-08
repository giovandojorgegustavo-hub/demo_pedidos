import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient _supabase = Supabase.instance.client;

class CargoCliente {
  const CargoCliente({
    required this.id,
    required this.idpedido,
    required this.concepto,
    required this.monto,
    this.createdAt,
  });

  final String id;
  final String idpedido;
  final String concepto;
  final double monto;
  final DateTime? createdAt;

  factory CargoCliente.fromJson(Map<String, dynamic> json) {
    final dynamic montoValue = json['monto'];
    final dynamic createdValue = json['created_at'] ?? json['registrado_at'];
    return CargoCliente(
      id: json['id'] as String,
      idpedido: json['idpedido'] as String,
      concepto: json['concepto'] as String,
      monto: montoValue is num
          ? montoValue.toDouble()
          : double.tryParse('$montoValue') ?? 0,
      createdAt: createdValue is String
          ? DateTime.tryParse(createdValue)
          : (createdValue is DateTime ? createdValue : null),
    );
  }

  CargoCliente copyWith({
    String? id,
    String? idpedido,
    String? concepto,
    double? monto,
    DateTime? createdAt,
  }) {
    return CargoCliente(
      id: id ?? this.id,
      idpedido: idpedido ?? this.idpedido,
      concepto: concepto ?? this.concepto,
      monto: monto ?? this.monto,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id.isNotEmpty) 'id': id,
      'idpedido': idpedido,
      'concepto': concepto,
      'monto': monto,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return <String, dynamic>{
      'idpedido': idpedido,
      'concepto': concepto,
      'monto': monto,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'concepto': concepto,
      'monto': monto,
    };
  }

  static Future<List<CargoCliente>> getByPedido(String pedidoId) async {
    final List<dynamic> data = await _supabase
        .from('cargos_cliente')
        .select('id,idpedido,concepto,monto,created_at:registrado_at')
        .eq('idpedido', pedidoId)
        .order('registrado_at', ascending: false);
    return data
        .map((dynamic item) =>
            CargoCliente.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<String> insert(CargoCliente cargo) async {
    final Map<String, dynamic> inserted = await _supabase
        .from('cargos_cliente')
        .insert(cargo.toInsertJson())
        .select('id')
        .single();
    return inserted['id'] as String;
  }

  static Future<void> update(CargoCliente cargo) async {
    await _supabase
        .from('cargos_cliente')
        .update(cargo.toUpdateJson())
        .eq('id', cargo.id);
  }

  static Future<void> deleteById(String id) async {
    await _supabase.from('cargos_cliente').delete().eq('id', id);
  }
}
