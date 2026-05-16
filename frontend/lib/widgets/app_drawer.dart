import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/orcamento_screen.dart';
import '../screens/servicos_screen.dart';
import '../screens/clientes_screen.dart';
import '../screens/login_screen.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatefulWidget {
  final int currentIndex;

  const AppDrawer({super.key, required this.currentIndex});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    final nome = await _authService.getNome();
    if (mounted) {
      setState(() {
        _nomeUsuario = nome ?? 'Usuário';
        // Iniciais para o avatar
      });
    }
  }

  String get _iniciais {
    if (_nomeUsuario.isEmpty) return '?';
    final partes = _nomeUsuario.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
    }
    return _nomeUsuario[0].toUpperCase();
  }

  void _navegar(BuildContext context, int index) {
    Navigator.pop(context);
    if (index == widget.currentIndex) return;

    final telas = [
      const HomeScreen(),
      const CalendarScreen(),
      const OrcamentoScreen(),
      const ServicosScreen(),
      const ClientesScreen(),
    ];

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => telas[index],
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 220),
      ),
      (route) => false,
    );
  }

  Future<void> _logout(BuildContext context) async {
    // Captura o Navigator ANTES de fechar o drawer (antes de qualquer await)
    final nav = Navigator.of(context);

    // Fecha o drawer
    nav.pop();

    // Mostra o diálogo de confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Limpa a sessão e oculta o FAB do assistente
    await _authService.logout();
    showChatFab.value = false;

    // Navega para login removendo todo o histórico de navegação
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // ── Cabeçalho com gradiente ──────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 20,
              20,
              28,
            ),
            decoration: const BoxDecoration(
              gradient: kPrimaryGradient,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar com iniciais
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white38, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _iniciais,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  _nomeUsuario.isEmpty ? '...' : _nomeUsuario,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Tag "OrganizaAI"
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded,
                          color: Colors.white70, size: 13),
                      SizedBox(width: 4),
                      Text(
                        'OrganizaAI',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Itens de navegação ───────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              children: [
                _buildItem(context,
                    index: 0,
                    icon: Icons.list_alt_outlined,
                    iconSelecionado: Icons.list_alt_rounded,
                    label: 'Agendamentos'),
                _buildItem(context,
                    index: 1,
                    icon: Icons.calendar_month_outlined,
                    iconSelecionado: Icons.calendar_month_rounded,
                    label: 'Calendário'),
                _buildItem(context,
                    index: 2,
                    icon: Icons.receipt_long_outlined,
                    iconSelecionado: Icons.receipt_long_rounded,
                    label: 'Orçamento'),
                _buildItem(context,
                    index: 3,
                    icon: Icons.build_outlined,
                    iconSelecionado: Icons.build_rounded,
                    label: 'Serviços'),
                _buildItem(context,
                    index: 4,
                    icon: Icons.people_outline,
                    iconSelecionado: Icons.people_rounded,
                    label: 'Clientes'),
              ],
            ),
          ),

          // ── Rodapé ───────────────────────────────────────────────
          Divider(color: Colors.grey.shade200, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Colors.red, size: 20),
              ),
              title: const Text(
                'Sair',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData iconSelecionado,
    required String label,
  }) {
    final selecionado = widget.currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        gradient: selecionado ? kPrimaryGradient : null,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Icon(
          selecionado ? iconSelecionado : icon,
          color: selecionado ? Colors.white : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.grey.shade800,
            fontWeight:
                selecionado ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
        onTap: () => _navegar(context, index),
      ),
    );
  }
}
