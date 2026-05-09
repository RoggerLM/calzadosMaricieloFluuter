
class Categoria{
  final String codigo;
  final String descripcion;

  Categoria({

    required this.codigo,
    required this.descripcion,
    });

  factory Categoria.fromJson(Map<String,dynamic> json){
    return Categoria(
        codigo: json['codigo'] ?? "CAT-000",
        descripcion: json['descripcion'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'descripcion': descripcion,
    };
  }
}