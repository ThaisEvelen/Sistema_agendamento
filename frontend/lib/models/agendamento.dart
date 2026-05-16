import 'servico.dart';

class Agendamento {
  final int id;
  final int? clienteId;
  final String nomeCliente;
  final String? telefoneCliente;
  final Servico servico;
  final DateTime dataHora;
  final DateTime dataHoraFim;
  final String status;

  Agendamento({
    required this.id,
    this.clienteId,
    required this.nomeCliente,
    this.telefoneCliente,
    required this.servico,
    required this.dataHora,
    required this.dataHoraFim,
    required this.status,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      id: json['id'],
      clienteId: json['clienteId'],
      nomeCliente: json['nomeCliente'],
      telefoneCliente: json['telefoneCliente'],
      servico: Servico.fromJson(json['servico']),
      dataHora: DateTime.parse(json['dataHora']),
      dataHoraFim: DateTime.parse(json['dataHoraFim']),
      status: json['status'],
    );
  }
}
