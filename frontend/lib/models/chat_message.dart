class ChatMessage {
  final String texto;
  final bool isUser;
  final String tipo; // INFO | PERGUNTA | SUCESSO | ERRO | CONFIRMACAO
  final List<String> opcoes;
  final DateTime timestamp;

  ChatMessage({
    required this.texto,
    required this.isUser,
    this.tipo = 'INFO',
    this.opcoes = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String texto) => ChatMessage(
        texto: texto,
        isUser: true,
        tipo: 'USER',
      );

  factory ChatMessage.bot(
    String texto, {
    String tipo = 'INFO',
    List<String> opcoes = const [],
  }) =>
      ChatMessage(
        texto: texto,
        isUser: false,
        tipo: tipo,
        opcoes: opcoes,
      );
}

class ChatBotResponse {
  final String resposta;
  final String tipo;
  final List<String> opcoes;

  ChatBotResponse({
    required this.resposta,
    required this.tipo,
    this.opcoes = const [],
  });

  factory ChatBotResponse.fromJson(Map<String, dynamic> json) {
    return ChatBotResponse(
      resposta: json['resposta'] ?? '',
      tipo: json['tipo'] ?? 'INFO',
      opcoes: json['opcoes'] != null
          ? List<String>.from(json['opcoes'])
          : const [],
    );
  }
}
