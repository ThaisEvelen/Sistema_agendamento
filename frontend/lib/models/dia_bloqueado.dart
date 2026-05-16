class DiaBloqueado {
  final int id;
  final DateTime data;
  final String? motivo;

  DiaBloqueado({required this.id, required this.data, this.motivo});

  factory DiaBloqueado.fromJson(Map<String, dynamic> json) {
    return DiaBloqueado(
      id: json['id'],
      data: DateTime.parse(json['data']),
      motivo: json['motivo'],
    );
  }
}
