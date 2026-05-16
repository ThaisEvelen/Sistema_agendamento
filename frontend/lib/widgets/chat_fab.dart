import 'package:flutter/material.dart';
import '../screens/chatbot_screen.dart';
import '../theme/app_colors.dart';

/// Botão flutuante global do assistente IA.
/// Adicionado via MaterialApp.builder — aparece em todas as telas.
class ChatFab extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const ChatFab({super.key, required this.navigatorKey});

  @override
  State<ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _abrirChat() {
    widget.navigatorKey.currentState?.push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ChatbotScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ChatbotScreen.isActive,
      builder: (_, ativo, __) {
        return AnimatedScale(
          scale: ativo ? 0 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: ativo,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: _abrirChat,
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kPurple.withValues(alpha: 0.50),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: kIndigo.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Anel de brilho interno
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.smart_toy_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
