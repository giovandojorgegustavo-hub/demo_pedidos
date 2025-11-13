class BasePackingDraft {
  BasePackingDraft({
    this.id,
    required this.nombre,
    this.activo = true,
  });

  String? id;
  String nombre;
  bool activo;

  BasePackingDraft copy() => BasePackingDraft(
        id: id,
        nombre: nombre,
        activo: activo,
      );
}
