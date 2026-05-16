import '../models/agendamento.dart';
import '../models/cliente.dart';
import '../models/servico.dart';

/// Dados falsos usados quando o app roda em modo demonstração (sem backend).
class DemoData {
  // ── Serviços ──────────────────────────────────────────────────────
  static final List<Servico> servicos = [
    Servico(id: 1, nome: 'Corte Feminino', descricao: 'Corte e finalização', duracaoMinutos: 60, duracaoFormatada: '1h', preco: 80, ativo: true),
    Servico(id: 2, nome: 'Escova Progressiva', descricao: 'Progressiva completa', duracaoMinutos: 180, duracaoFormatada: '3h', preco: 250, ativo: true),
    Servico(id: 3, nome: 'Coloração', descricao: 'Tintura e hidratação', duracaoMinutos: 120, duracaoFormatada: '2h', preco: 150, ativo: true),
    Servico(id: 4, nome: 'Manicure', descricao: 'Unhas das mãos', duracaoMinutos: 45, duracaoFormatada: '45min', preco: 35, ativo: true),
    Servico(id: 5, nome: 'Pedicure', descricao: 'Unhas dos pés', duracaoMinutos: 50, duracaoFormatada: '50min', preco: 40, ativo: true),
    Servico(id: 6, nome: 'Hidratação Capilar', descricao: 'Tratamento intensivo', duracaoMinutos: 60, duracaoFormatada: '1h', preco: 90, ativo: true),
  ];

  // ── Clientes ──────────────────────────────────────────────────────
  static final List<Cliente> clientes = [
    Cliente(id: 1, nome: 'Ana Lima', telefone: '(11) 98765-4321'),
    Cliente(id: 2, nome: 'Beatriz Santos', telefone: '(11) 91234-5678'),
    Cliente(id: 3, nome: 'Carla Oliveira', telefone: '(21) 99876-5432'),
    Cliente(id: 4, nome: 'Diana Ferreira', telefone: '(31) 98888-1111'),
    Cliente(id: 5, nome: 'Eduarda Costa', telefone: '(41) 97777-2222'),
  ];

  // ── Agendamentos ─────────────────────────────────────────────────
  static List<Agendamento> get agendamentos {
    final hoje = DateTime.now();
    final d = (DateTime dt, int h, int m) => DateTime(dt.year, dt.month, dt.day, h, m);

    return [
      Agendamento(
        id: 1,
        clienteId: 1,
        nomeCliente: 'Ana Lima',
        telefoneCliente: '(11) 98765-4321',
        servico: servicos[0],
        dataHora: d(hoje, 9, 0),
        dataHoraFim: d(hoje, 10, 0),
        status: 'CONFIRMADO',
      ),
      Agendamento(
        id: 2,
        clienteId: 2,
        nomeCliente: 'Beatriz Santos',
        telefoneCliente: '(11) 91234-5678',
        servico: servicos[3],
        dataHora: d(hoje, 10, 30),
        dataHoraFim: d(hoje, 11, 15),
        status: 'PENDENTE',
      ),
      Agendamento(
        id: 3,
        clienteId: 3,
        nomeCliente: 'Carla Oliveira',
        telefoneCliente: '(21) 99876-5432',
        servico: servicos[2],
        dataHora: d(hoje, 14, 0),
        dataHoraFim: d(hoje, 16, 0),
        status: 'PENDENTE',
      ),
      Agendamento(
        id: 4,
        clienteId: 4,
        nomeCliente: 'Diana Ferreira',
        telefoneCliente: '(31) 98888-1111',
        servico: servicos[1],
        dataHora: d(hoje.add(const Duration(days: 1)), 9, 0),
        dataHoraFim: d(hoje.add(const Duration(days: 1)), 12, 0),
        status: 'CONFIRMADO',
      ),
      Agendamento(
        id: 5,
        clienteId: 5,
        nomeCliente: 'Eduarda Costa',
        telefoneCliente: '(41) 97777-2222',
        servico: servicos[4],
        dataHora: d(hoje.add(const Duration(days: 1)), 14, 0),
        dataHoraFim: d(hoje.add(const Duration(days: 1)), 14, 50),
        status: 'PENDENTE',
      ),
      Agendamento(
        id: 6,
        clienteId: 1,
        nomeCliente: 'Ana Lima',
        telefoneCliente: '(11) 98765-4321',
        servico: servicos[5],
        dataHora: d(hoje.subtract(const Duration(days: 2)), 11, 0),
        dataHoraFim: d(hoje.subtract(const Duration(days: 2)), 12, 0),
        status: 'CANCELADO',
      ),
    ];
  }
}
