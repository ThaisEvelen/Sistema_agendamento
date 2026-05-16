import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dia_bloqueado.dart';
import 'auth_service.dart';

class DiaBloqueadoService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/dias-bloqueados';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR TODOS
  Future<List<DiaBloqueado>> listarTodos() async {
    if (AuthService.demoMode) return [];
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => DiaBloqueado.fromJson(j)).toList();
    }
    throw Exception('Erro ao buscar dias bloqueados');
  }

  // BLOQUEAR
  Future<DiaBloqueado> bloquear(DateTime data, String? motivo) async {
    if (AuthService.demoMode) {
      return DiaBloqueado(id: 99, data: data, motivo: motivo);
    }
    final dataFormatada =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({'data': dataFormatada, 'motivo': motivo}),
    );
    if (response.statusCode == 201) {
      return DiaBloqueado.fromJson(jsonDecode(response.body));
    }
    final erro = jsonDecode(response.body);
    throw Exception(erro['mensagem'] ?? 'Erro ao bloquear dia');
  }

  // DESBLOQUEAR
  Future<void> desbloquear(int id) async {
    if (AuthService.demoMode) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(),
    );
    if (response.statusCode != 204) {
      final erro = jsonDecode(response.body);
      throw Exception(erro['mensagem'] ?? 'Erro ao desbloquear dia');
    }
  }
}
