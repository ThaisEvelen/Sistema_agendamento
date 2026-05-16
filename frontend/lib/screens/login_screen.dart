import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../main.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _carregando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _entrarModoDemo() async {
    setState(() => _carregando = true);
    await _authService.loginDemo();
    if (!mounted) return;
    showChatFab.value = true;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      await _authService.login(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;
      showChatFab.value = true; // ativa o botão do assistente
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: kPrimaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // ── Topo com logo ───────────────────────────────────
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 88, showText: false),
                        const SizedBox(height: 18),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Organiza',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              TextSpan(
                                text: 'AI',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFC4B5FD),
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sua agenda inteligente',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Card do formulário ──────────────────────────────
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Bem-vindo de volta!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Faça login para continuar',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 14),
                            ),
                            const SizedBox(height: 28),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email é obrigatório';
                                }
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Senha
                            TextFormField(
                              controller: _senhaController,
                              obscureText: !_senhaVisivel,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_senhaVisivel
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(
                                      () => _senhaVisivel = !_senhaVisivel),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Senha é obrigatória';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Botão com gradiente
                            _GradientButton(
                              onPressed: _carregando ? null : _login,
                              child: _carregando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Entrar',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),

                            const SizedBox(height: 12),

                            // Botão Modo Demo
                            OutlinedButton.icon(
                              onPressed: _carregando ? null : _entrarModoDemo,
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              label: const Text('Ver demonstração'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPurple,
                                side: const BorderSide(color: kPurple),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                minimumSize:
                                    const Size(double.infinity, 48),
                              ),
                            ),

                            const Spacer(),

                            // Link cadastro
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Não tem conta? ',
                                    style: TextStyle(color: Colors.grey),
                                    children: [
                                      TextSpan(
                                        text: 'Cadastre-se',
                                        style: TextStyle(
                                          color: kPurple,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

// Botão com gradiente reutilizável
class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _GradientButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: onPressed != null ? kPrimaryGradient : null,
        color: onPressed == null ? Colors.grey.shade300 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: kPurple.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
