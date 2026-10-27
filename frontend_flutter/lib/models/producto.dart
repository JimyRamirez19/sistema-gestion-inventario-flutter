class Producto {
  final int id;
  final String nombre;
  final String codigo;
  final String? descripcion;
  final double precio;
  final int cantidad;
  final String categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.codigo,
    this.descripcion,
    required this.precio,
    required this.cantidad,
    required this.categoria,
  });

  double get valorTotal => precio * cantidad;
  bool get isOutOfStock => cantidad <= 0;
  bool get isLowStock => cantidad > 0 && cantidad <= 5;

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      nombre: json['nombre']?.toString() ?? '',
      codigo: json['codigo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      precio: json['precio'] != null ? (json['precio'] as num).toDouble() : 0.0,
      cantidad: json['cantidad'] != null ? (json['cantidad'] as num).toInt() : 0,
      categoria: json['categoria']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };
  }

  Map<String, dynamic> toRequestPayload() {
    return {
      'nombre': nombre.trim(),
      'codigo': codigo.trim(),
      'descripcion': (descripcion != null && descripcion!.trim().isNotEmpty) ? descripcion!.trim() : null,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria.trim(),
    };
  }

  Producto copyWith({
    int? id,
    String? nombre,
    String? codigo,
    String? descripcion,
    double? precio,
    int? cantidad,
    String? categoria,
  }) {
    return Producto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      descripcion: descripcion ?? this.descripcion,
      precio: precio ?? this.precio,
      cantidad: cantidad ?? this.cantidad,
      categoria: categoria ?? this.categoria,
    );
  }
}
