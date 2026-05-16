import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth';

  // Chaves para salvar no SharedPreferences
  static const String _tokenKey = 'token';
  static const String _nomeKey = 'nome';
  static const String _emailKey = 'email';
  static const String _roleKey = 'role';

  /// True quando o app está rodando em modo demonstração (sem backend).
  /// Usado pelos serviços para retornar dados falsos em vez de chamar a API.
  static bool demoMode = false;

  // CADASTRO
  Future<void> register(String nome, String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _salvarSessao(data);
    } else {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao cadastrar');
    }
  }

  // LOGIN
  Future<void> login(String email, String senha) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'senha': senha,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _salvarSessao(data);
    } else {
      throw Exception('Email ou senha incorretos');
    }
  }

  // LOGIN DEMO (sem backend — só para demonstração visual)
  Future<void> loginDemo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo-token');
    await prefs.setString(_nomeKey, 'Usuário Demo');
    await prefs.setString(_emailKey, 'demo@organizaai.com');
    await prefs.setString(_roleKey, 'ADMIN');
    demoMode = true;
  }

  // LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Verifica se o usuário está logado
  Future<bool> estaLogado() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == 'demo-token') demoMode = true;
    return token != null;
  }

  // Retorna o token salvo
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Retorna o nome do usuário logado
  Future<String?> getNome() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nomeKey);
  }

  // Salva os dados da sessão no dispositivo
  Future<void> _salvarSessao(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data['token']);
    await prefs.setString(_nomeKey, data['nome']);
    await prefs.setString(_emailKey, data['email']);
    await prefs.setString(_roleKey, data['role']);
  }
}
