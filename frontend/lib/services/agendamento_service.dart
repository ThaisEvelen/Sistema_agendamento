import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agendamento.dart';
import 'auth_service.dart';
import 'demo_data.dart';

class AgendamentoService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/agendamentos';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR TODOS
  Future<List<Agendamento>> listarTodos() async {
    if (AuthService.demoMode) return DemoData.agendamentos;
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Agendamento.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar agendamentos');
    }
  }

  // BUSCAR POR ID
  Future<Agendamento> buscarPorId(int id) async {
    if (AuthService.demoMode) {
      return DemoData.agendamentos.firstWhere((a) => a.id == id);
    }
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return Agendamento.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Agendamento não encontrado');
    }
  }

  // CRIAR
  Future<Agendamento> criar(
    String nomeCliente,
    int servicoId,
    DateTime dataHora, {
    int? clienteId,
  }) async {
    if (AuthService.demoMode) {
      final servico = DemoData.servicos.firstWhere(
        (s) => s.id == servicoId,
        orElse: () => DemoData.servicos.first,
      );
      return Agendamento(
        id: 99,
        clienteId: clienteId,
        nomeCliente: nomeCliente,
        servico: servico,
        dataHora: dataHora,
        dataHoraFim: dataHora.add(Duration(minutes: servico.duracaoMinutos)),
        status: 'PENDENTE',
      );
    }
    final body = <String, dynamic>{
      'nomeCliente': nomeCliente,
      'servicoId': servicoId,
      'dataHora': dataHora.toIso8601String(),
    };
    if (clienteId != null) body['clienteId'] = clienteId;

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 201) {
      return Agendamento.fromJson(jsonDecode(response.body));
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao criar agendamento');
    }
  }

  // ATUALIZAR STATUS
  Future<Agendamento> atualizarStatus(int id, String novoStatus) async {
    if (AuthService.demoMode) {
      return DemoData.agendamentos.firstWhere((a) => a.id == id);
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/status?novoStatus=$novoStatus'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return Agendamento.fromJson(jsonDecode(response.body));
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao atualizar status');
    }
  }

  // BUSCAR POR DATA
  Future<List<Agendamento>> buscarPorData(DateTime data) async {
    if (AuthService.demoMode) {
      return DemoData.agendamentos.where((a) =>
        a.dataHora.year == data.year &&
        a.dataHora.month == data.month &&
        a.dataHora.day == data.day,
      ).toList();
    }
    final dataFormatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';
    final response = await http.get(
      Uri.parse('$baseUrl/data?data=$dataFormatada'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Agendamento.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar agendamentos por data');
    }
  }

  // CANCELAR
  Future<void> cancelar(int id) async {
    if (AuthService.demoMode) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao cancelar agendamento');
    }
  }
}
