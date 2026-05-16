import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chatbot_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  /// Controla se a tela está ativa — usado pelo ChatFab para se esconder
  static final isActive = ValueNotifier<bool>(false);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller    = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final _chatService   = ChatbotService();
  final _focusNode     = FocusNode();

  final List<ChatMessage> _msgs = [];
  bool _carregando = false;

  static const _msgBoasVindas =
      'Ola! Sou o assistente do OrganizaAI.\n\n'
      'Posso te ajudar a:\n'
      '- Marcar um horario\n'
      '- Ver agendamentos do dia\n'
      '- Verificar disponibilidade\n\n'
      'Exemplo: "marcar a Maria para corte amanha as 14h"';

  @override
  void initState() {
    super.initState();
    ChatbotScreen.isActive.value = true; // FAB some enquanto esta tela está aberta
    _msgs.add(ChatMessage.bot(
      _msgBoasVindas,
      tipo: 'INFO',
      opcoes: ['Ver agendamentos hoje', 'Verificar disponibilidade'],
    ));
  }

  @override
  void dispose() {
    ChatbotScreen.isActive.value = false; // FAB volta ao fechar
    _controller.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Enviar mensagem ───────────────────────────────────────────────
  Future<void> _enviar([String? textoFixo]) async {
    final texto = (textoFixo ?? _controller.text).trim();
    if (texto.isEmpty || _carregando) return;

    setState(() {
      _msgs.add(ChatMessage.user(texto));
      _carregando = true;
    });

    if (textoFixo == null) _controller.clear();
    _scrollToBottom();

    try {
      final resp = await _chatService.enviar(texto);
      if (!mounted) return;
      setState(() {
        _msgs.add(ChatMessage.bot(
          resp.resposta,
          tipo: resp.tipo,
          opcoes: resp.opcoes,
        ));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.add(ChatMessage.bot(
          'Erro de conexao. Verifique se o servidor esta rodando.',
          tipo: 'ERRO',
        ));
        _carregando = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Assistente IA',
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Fechar',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _carregando ? Colors.orange : Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _carregando ? 'digitando...' : 'online',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Lista de mensagens ─────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFFF3F0FF),
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                itemCount: _msgs.length,
                itemBuilder: (_, i) => _buildMensagem(_msgs[i], i),
              ),
            ),
          ),

          // ── Indicador "digitando..." ───────────────────────────
          if (_carregando) _buildTypingIndicator(),

          // ── Botões de resposta rápida ──────────────────────────
          if (!_carregando && _msgs.isNotEmpty && _msgs.last.opcoes.isNotEmpty)
            _buildQuickReplies(_msgs.last.opcoes),

          // ── Barra de entrada ───────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Bolha de mensagem ─────────────────────────────────────────────
  Widget _buildMensagem(ChatMessage msg, int index) {
    if (msg.isUser) return _buildBolhaUsuario(msg);
    return _buildBolhaBot(msg, index);
  }

  Widget _buildBolhaUsuario(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: kPrimaryGradient,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(18),
                  topRight:    Radius.circular(18),
                  bottomLeft:  Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kPurple.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.texto,
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, height: 1.4),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('HH:mm').format(msg.timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBolhaBot(ChatMessage msg, int index) {
    final cor = _corTipo(msg.tipo);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar do bot
          Container(
            width: 32, height: 32,
            margin: const EdgeInsets.only(right: 8, bottom: 2),
            decoration: const BoxDecoration(
              gradient: kPrimaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
            ),
          ),

          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft:     Radius.circular(4),
                  topRight:    Radius.circular(18),
                  bottomLeft:  Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: msg.tipo == 'SUCESSO' || msg.tipo == 'ERRO'
                    ? Border.all(color: cor.withValues(alpha: 0.35), width: 1.5)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone de tipo na primeira mensagem não-INFO
                  if (msg.tipo != 'INFO' && msg.tipo != 'PERGUNTA' && msg.tipo != 'USER')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconesTipo(msg.tipo), color: cor, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            _labelTipo(msg.tipo),
                            style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Texto principal
                  Text(
                    msg.texto,
                    style: const TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      DateFormat('HH:mm').format(msg.timestamp),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Indicador "digitando..." ──────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Container(
      color: const Color(0xFFF3F0FF),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: kPrimaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(
              children: List.generate(3, (i) => _dot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (_, v, __) => Container(
        width: 7, height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: kPurple.withValues(alpha: 0.3 + 0.7 * v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  // ── Botões de resposta rápida ─────────────────────────────────────
  Widget _buildQuickReplies(List<String> opcoes) {
    return Container(
      color: const Color(0xFFF3F0FF),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: opcoes.map((op) {
          final isPositivo = op.toLowerCase().contains('sim') ||
              op.toLowerCase().contains('confirmar') ||
              op.toLowerCase().contains('marcar');
          return InkWell(
            onTap: () => _enviar(op),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isPositivo ? kPrimaryGradient : null,
                color: isPositivo ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPositivo ? Colors.transparent : kPurple,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                op,
                style: TextStyle(
                  color: isPositivo ? Colors.white : kPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Barra de entrada ──────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma mensagem...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _enviar(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Botão enviar
            GestureDetector(
              onTap: _carregando ? null : _enviar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: _carregando ? null : kPrimaryGradient,
                  color: _carregando ? Colors.grey.shade300 : null,
                  shape: BoxShape.circle,
                  boxShadow: _carregando ? null : [
                    BoxShadow(
                      color: kPurple.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: _carregando ? Colors.grey : Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers de estilo por tipo ────────────────────────────────────
  Color _corTipo(String tipo) {
    switch (tipo) {
      case 'SUCESSO':      return Colors.green.shade600;
      case 'ERRO':         return Colors.red.shade600;
      case 'CONFIRMACAO':  return kPurple;
      case 'PERGUNTA':     return Colors.orange.shade700;
      default:             return Colors.grey.shade600;
    }
  }

  IconData _iconesTipo(String tipo) {
    switch (tipo) {
      case 'SUCESSO':      return Icons.check_circle_rounded;
      case 'ERRO':         return Icons.error_rounded;
      case 'CONFIRMACAO':  return Icons.help_rounded;
      case 'PERGUNTA':     return Icons.help_outline_rounded;
      default:             return Icons.info_rounded;
    }
  }

  String _labelTipo(String tipo) {
    switch (tipo) {
      case 'SUCESSO':      return 'Sucesso';
      case 'ERRO':         return 'Erro';
      case 'CONFIRMACAO':  return 'Confirmação';
      case 'PERGUNTA':     return 'Pergunta';
      default:             return '';
    }
  }
}
