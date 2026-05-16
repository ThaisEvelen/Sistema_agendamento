import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/servico.dart';
import 'auth_service.dart';
import 'demo_data.dart';

class ServicoService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/servicos';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR ATIVOS
  Future<List<Servico>> listarAtivos() async {
    if (AuthService.demoMode) {
      return DemoData.servicos.where((s) => s.ativo).toList();
    }
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Servico.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar serviços');
    }
  }

  // LISTAR TODOS (inclusive inativos)
  Future<List<Servico>> listarTodos() async {
    if (AuthService.demoMode) return DemoData.servicos;
    final response = await http.get(
      Uri.parse('$baseUrl/todos'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Servico.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar serviços');
    }
  }

  // CRIAR
  Future<Servico> criar(String nome, String? descricao, int duracaoMinutos, double preco) async {
    if (AuthService.demoMode) {
      return Servico(
        id: 99,
        nome: nome,
        descricao: descricao,
        duracaoMinutos: duracaoMinutos,
        duracaoFormatada: '${duracaoMinutos}min',
        preco: preco,
        ativo: true,
      );
    }
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({
        'nome': nome,
        'descricao': descricao,
        'duracaoMinutos': duracaoMinutos,
        'preco': preco,
      }),
    );
    if (response.statusCode == 201) {
      return Servico.fromJson(jsonDecode(response.body));
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao criar serviço');
    }
  }

  // DESATIVAR
  Future<void> desativar(int id) async {
    if (AuthService.demoMode) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao desativar serviço');
    }
  }

  // REATIVAR
  Future<Servico> reativar(int id) async {
    if (AuthService.demoMode) {
      return DemoData.servicos.firstWhere((s) => s.id == id);
    }
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/reativar'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      return Servico.fromJson(jsonDecode(response.body));
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao reativar serviço');
    }
  }
}
