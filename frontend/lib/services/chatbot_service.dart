import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import 'auth_service.dart';

class ChatbotService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/chatbot';
  static const String _sessaoId = 'mobile-session';

  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<ChatBotResponse> enviar(String mensagem) async {
    final response = await http.post(
      Uri.parse('$baseUrl/mensagem'),
      headers: await _headers(),
      body: jsonEncode({
        'mensagem': mensagem,
        'sessaoId': _sessaoId,
      }),
    );

    if (response.statusCode == 200) {
      return ChatBotResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Erro ao comunicar com o assistente');
  }
}
