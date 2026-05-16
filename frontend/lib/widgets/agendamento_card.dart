import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agendamento.dart';
import '../screens/detalhe_screen.dart';

class AgendamentoCard extends StatelessWidget {
  final Agendamento agendamento;
  final VoidCallback onAtualizar;

  const AgendamentoCard({
    super.key,
    required this.agendamento,
    required this.onAtualizar,
  });

  // Define a cor do status
  Color _corStatus(String status) {
    switch (status) {
      case 'CONFIRMADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Define o ícone do status
  IconData _iconeStatus(String status) {
    switch (status) {
      case 'CONFIRMADO':
        return Icons.check_circle;
      case 'CANCELADO':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(agendamento.dataHora);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          _iconeStatus(agendamento.status),
          color: _corStatus(agendamento.status),
          size: 36,
        ),
        title: Text(
          agendamento.nomeCliente,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (agendamento.telefoneCliente != null)
              Row(children: [
                const Icon(Icons.phone, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(agendamento.telefoneCliente!,
                    style: const TextStyle(fontSize: 13)),
              ]),
            Text('Serviço: ${agendamento.servico.nome}'),
            Text('Duração: ${agendamento.servico.duracaoFormatada}'),
            Text('Data: $dataFormatada'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _corStatus(agendamento.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _corStatus(agendamento.status)),
              ),
              child: Text(
                agendamento.status,
                style: TextStyle(
                  color: _corStatus(agendamento.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalheScreen(agendamento: agendamento),
            ),
          );
          onAtualizar();
        },
      ),
    );
  }
}
