import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _carregando = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    try {
      await _authService.register(
        _nomeController.text.trim(),
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;
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
          child: Column(
            children: [
              // ── Topo ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Row(
                  children: [
                    // Botão voltar
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Criar Conta',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Preencha para se cadastrar',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Card do formulário ──────────────────────────────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Nome
                          TextFormField(
                            controller: _nomeController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nome é obrigatório';
                              }
                              if (v.trim().length < 3) {
                                return 'Mínimo 3 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

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
                              if (v.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirmar Senha
                          TextFormField(
                            controller: _confirmarSenhaController,
                            obscureText: !_confirmarSenhaVisivel,
                            decoration: InputDecoration(
                              labelText: 'Confirmar senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_confirmarSenhaVisivel
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(() =>
                                    _confirmarSenhaVisivel =
                                        !_confirmarSenhaVisivel),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Confirmação obrigatória';
                              }
                              if (v != _senhaController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Botão gradiente
                          _GradientButton(
                            onPressed: _carregando ? null : _cadastrar,
                            child: _carregando
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Criar conta',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                          const SizedBox(height: 20),

                          // Link login
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text.rich(
                                TextSpan(
                                  text: 'Já tem conta? ',
                                  style: TextStyle(color: Colors.grey),
                                  children: [
                                    TextSpan(
                                      text: 'Faça login',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
