import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/agendamento.dart';
import 'auth_service.dart';

class AgendamentoService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/agendamentos';
  final AuthService _authService = AuthService();

  // Monta o header com o token JWT
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR TODOS
  Future<List<Agendamento>> listarTodos() async {
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
