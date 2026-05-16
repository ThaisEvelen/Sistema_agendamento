import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cliente.dart';
import 'auth_service.dart';
import 'demo_data.dart';

class ClienteService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/clientes';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR TODOS (ou buscar por nome)
  Future<List<Cliente>> listar({String? nome}) async {
    if (AuthService.demoMode) {
      if (nome != null && nome.isNotEmpty) {
        final q = nome.toLowerCase();
        return DemoData.clientes
            .where((c) => c.nome.toLowerCase().contains(q))
            .toList();
      }
      return DemoData.clientes;
    }
    final uri = nome != null && nome.isNotEmpty
        ? Uri.parse('$baseUrl?nome=${Uri.encodeComponent(nome)}')
        : Uri.parse(baseUrl);
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => Cliente.fromJson(j)).toList();
    }
    throw Exception('Erro ao buscar clientes');
  }

  // CRIAR
  Future<Cliente> criar(String nome, String telefone) async {
    if (AuthService.demoMode) {
      return Cliente(id: 99, nome: nome, telefone: telefone);
    }
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({'nome': nome, 'telefone': telefone}),
    );
    if (response.statusCode == 201) {
      return Cliente.fromJson(jsonDecode(response.body));
    }
    final erro = jsonDecode(response.body);
    throw Exception(erro['mensagem'] ?? 'Erro ao cadastrar cliente');
  }

  // ATUALIZAR
  Future<Cliente> atualizar(int id, String nome, String telefone) async {
    if (AuthService.demoMode) {
      return Cliente(id: id, nome: nome, telefone: telefone);
    }
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
      body: jsonEncode({'nome': nome, 'telefone': telefone}),
    );
    if (response.statusCode == 200) {
      return Cliente.fromJson(jsonDecode(response.body));
    }
    final erro = jsonDecode(response.body);
    throw Exception(erro['mensagem'] ?? 'Erro ao atualizar cliente');
  }

  // DELETAR
  Future<void> deletar(int id) async {
    if (AuthService.demoMode) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao deletar cliente');
    }
  }
}
