import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/chatbot_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';
import 'widgets/app_logo.dart';
import 'widgets/chat_fab.dart';

/// Chave global para navegar de qualquer ponto do app (ex: ChatFab)
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Controla visibilidade do ChatFab — false no splash/login, true quando logado
final ValueNotifier<bool> showChatFab = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  // Barra de status transparente para o gradiente aparecer por baixo
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const OrganizaAiApp());
}

class OrganizaAiApp extends StatelessWidget {
  const OrganizaAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrganizaAI',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: _buildTheme(),
      home: const SplashScreen(),

      // Overlay global: botão do assistente IA aparece em TODAS as telas
      builder: (context, child) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;
        return Stack(
          children: [
            child!,
            // Oculta o FAB nas telas de login e splash (sem token)
            ValueListenableBuilder<bool>(
              valueListenable: showChatFab,
              builder: (_, mostrar, __) {
                if (!mostrar) return const SizedBox.shrink();
                return Positioned(
                  bottom: 20 + bottomPadding,
                  left: 18,
                  child: ChatFab(navigatorKey: appNavigatorKey),
                );
              },
            ),
          ],
        );
      },
    );
  }

  ThemeData _buildTheme() {
    final base = ColorScheme.fromSeed(
      seedColor: kPurple,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: base,
      useMaterial3: true,

      // Cards
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: kPurple.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),

      // Inputs arredondados e com fundo suave
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade600),
        prefixIconColor: kPurple,
      ),

      // Botões elevados com bordas arredondadas
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),

      // FAB arredondado
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
        shape: StadiumBorder(),
        elevation: 4,
      ),

      // Chips com cantos arredondados
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Dividers mais suaves
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
    );
  }
}

// ─── Splash ────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _verificarLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verificarLogin() async {
    final authService = AuthService();
    await Future.delayed(const Duration(milliseconds: 1200));
    final logado = await authService.estaLogado();

    if (!mounted) return;

    // Mostra o FAB só quando o usuário está logado
    showChatFab.value = logado;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            logado ? const HomeScreen() : const LoginScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo principal
                  const AppLogo(size: 110, showText: false),
                  const SizedBox(height: 28),

                  // Nome do app
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Organiza',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'AI',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC4B5FD),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sua agenda inteligente',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.75),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white.withValues(alpha: 0.65),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
