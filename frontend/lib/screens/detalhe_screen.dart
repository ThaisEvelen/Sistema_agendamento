import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agendamento.dart';
import '../services/agendamento_service.dart';
import '../widgets/gradient_app_bar.dart';

class DetalheScreen extends StatefulWidget {
  final Agendamento agendamento;

  const DetalheScreen({super.key, required this.agendamento});

  @override
  State<DetalheScreen> createState() => _DetalheScreenState();
}

class _DetalheScreenState extends State<DetalheScreen> {
  final AgendamentoService _service = AgendamentoService();
  late Agendamento _agendamento;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _agendamento = widget.agendamento;
  }

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

  Future<void> _atualizarStatus(String novoStatus) async {
    setState(() => _carregando = true);

    try {
      final atualizado = await _service.atualizarStatus(_agendamento.id, novoStatus);
      setState(() => _agendamento = atualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status atualizado para $novoStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cancelar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Agendamento'),
        content: const Text('Tem certeza que deseja cancelar este agendamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _carregando = true);

    try {
      await _service.cancelar(_agendamento.id);
      final atualizado = await _service.buscarPorId(_agendamento.id);
      setState(() => _agendamento = atualizado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agendamento cancelado'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy HH:mm').format(_agendamento.dataHora);
    final cancelado = _agendamento.status == 'CANCELADO';

    return Scaffold(
      appBar: const GradientAppBar(title: 'Detalhes'),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card de informações
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoItem(Icons.person, 'Cliente', _agendamento.nomeCliente),
                          const Divider(),
                          _infoItem(Icons.build, 'Serviço', _agendamento.servico.nome),
                          const Divider(),
                          _infoItem(Icons.timer, 'Duração', _agendamento.servico.duracaoFormatada),
                          const Divider(),
                          _infoItem(Icons.calendar_today, 'Início', dataFormatada),
                          const Divider(),
                          _infoItem(Icons.flag, 'Término', DateFormat('dd/MM/yyyy HH:mm').format(_agendamento.dataHoraFim)),
                          const Divider(),
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.grey),
                              const SizedBox(width: 12),
                              const Text('Status: ', style: TextStyle(color: Colors.grey)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _corStatus(_agendamento.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _corStatus(_agendamento.status)),
                                ),
                                child: Text(
                                  _agendamento.status,
                                  style: TextStyle(
                                    color: _corStatus(_agendamento.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de ação (apenas se não estiver cancelado)
                  if (!cancelado) ...[
                    if (_agendamento.status == 'PENDENTE')
                      ElevatedButton.icon(
                        onPressed: () => _atualizarStatus('CONFIRMADO'),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirmar Agendamento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _cancelar,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancelar Agendamento',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],

                  if (cancelado)
                    const Center(
                      child: Text(
                        'Este agendamento foi cancelado',
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
