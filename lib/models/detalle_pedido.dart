class DetallePedido {
  const DetallePedido({
    this.id,
    required this.idproducto,
    required this.cantidad,
    required this.precioventa,
  });

  final String? id;
  final String idproducto;
  final double cantidad;
  final double precioventa;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'idproducto': idproducto,
      'cantidad': cantidad,
      'precioventa': precioventa,
    };
  }

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    final dynamic cantidadValue = json['cantidad'];
    final dynamic precioValue = json['precioventa'];
    return DetallePedido(
      id: json['id'] as String?,
      idproducto: json['idproducto'] as String,
      cantidad: cantidadValue is num
          ? cantidadValue.toDouble()
          : double.tryParse('$cantidadValue') ?? 0,
      precioventa: precioValue is num
          ? precioValue.toDouble()
          : double.tryParse('$precioValue') ?? 0,
    );
  }
}
