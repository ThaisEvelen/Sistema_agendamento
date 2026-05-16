class HorarioBloqueado {
  final int id;
  final DateTime data;
  final int hora;
  final String horaTexto; // "14:00"
  final String? motivo;

  HorarioBloqueado({
    required this.id,
    required this.data,
    required this.hora,
    required this.horaTexto,
    this.motivo,
  });

  factory HorarioBloqueado.fromJson(Map<String, dynamic> json) {
    return HorarioBloqueado(
      id: json['id'],
      data: DateTime.parse(json['data']),
      hora: json['hora'],
      horaTexto: json['horaTexto'],
      motivo: json['motivo'],
    );
  }
}
