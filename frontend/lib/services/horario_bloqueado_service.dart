import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/horario_bloqueado.dart';
import 'auth_service.dart';

class HorarioBloqueadoService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/horarios-bloqueados';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // LISTAR por data
  Future<List<HorarioBloqueado>> listarPorData(DateTime data) async {
    if (AuthService.demoMode) return [];
    final dataStr =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    final response = await http.get(
      Uri.parse('$baseUrl?data=$dataStr'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((j) => HorarioBloqueado.fromJson(j)).toList();
    }
    throw Exception('Erro ao buscar horários bloqueados');
  }

  // BLOQUEAR
  Future<HorarioBloqueado> bloquear(
      DateTime data, int hora, String? motivo) async {
    if (AuthService.demoMode) {
      return HorarioBloqueado(
        id: 99, data: data, hora: hora,
        horaTexto: '${hora.toString().padLeft(2, '0')}:00',
        motivo: motivo,
      );
    }
    final dataStr =
        '${data.year}-${data.month.toString().padLeft(2, '0')}-${data.day.toString().padLeft(2, '0')}';

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(),
      body: jsonEncode({'data': dataStr, 'hora': hora, 'motivo': motivo}),
    );
    if (response.statusCode == 201) {
      return HorarioBloqueado.fromJson(jsonDecode(response.body));
    }
    final erro = jsonDecode(response.body);
    throw Exception(erro['mensagem'] ?? 'Erro ao bloquear horário');
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
      throw Exception(erro['mensagem'] ?? 'Erro ao desbloquear horário');
    }
  }
}
