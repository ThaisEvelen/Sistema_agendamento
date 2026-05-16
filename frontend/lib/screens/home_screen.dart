import 'package:flutter/material.dart';
import '../models/agendamento.dart';
import '../services/agendamento_service.dart';
import '../services/auth_service.dart';
import '../widgets/agendamento_card.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';
import 'criar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AgendamentoService _agendamentoService = AgendamentoService();
  final AuthService _authService = AuthService();

  List<Agendamento> _agendamentos = [];
  bool _carregando = true;
  String? _erro;
  String _nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final nome = await _authService.getNome();
    setState(() => _nomeUsuario = nome ?? '');
    await _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await _agendamentoService.listarTodos();
      setState(() {
        _agendamentos = lista;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro =
            'Erro ao carregar agendamentos.\nVerifique se o servidor está rodando.';
        _carregando = false;
      });
    }
  }

  // Estatísticas rápidas
  int get _pendentes =>
      _agendamentos.where((a) => a.status == 'PENDENTE').length;
  int get _confirmados =>
      _agendamentos.where((a) => a.status == 'CONFIRMADO').length;
  int get _cancelados =>
      _agendamentos.where((a) => a.status == 'CANCELADO').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentIndex: 0),
      appBar: GradientAppBar(
        title: 'Agendamentos',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarAgendamentos,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriarScreen()),
          );
          _carregarAgendamentos();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo Agendamento',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade400),
              ),
              const SizedBox(height: 20),
              Text(_erro!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _carregarAgendamentos,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: kPurple,
      onRefresh: _carregarAgendamentos,
      child: CustomScrollView(
        slivers: [
          // ── Banner de boas-vindas + stats ──────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Lista de agendamentos ───────────────────────────────
          if (_agendamentos.isEmpty)
            SliverFillRemaining(child: _buildEmpty())
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AgendamentoCard(
                    agendamento: _agendamentos[index],
                    onAtualizar: _carregarAgendamentos,
                  ),
                  childCount: _agendamentos.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final primeiroNome = _nomeUsuario.split(' ').first;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kPrimaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPurple.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saudação
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $primeiroNome! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_agendamentos.length} agendamento${_agendamentos.length != 1 ? 's' : ''} no total',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 15),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 28),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chips de status
          Row(
            children: [
              _statChip('Pendentes', _pendentes, Colors.orange),
              const SizedBox(width: 8),
              _statChip('Confirmados', _confirmados, Colors.greenAccent),
              const SizedBox(width: 8),
              _statChip('Cancelados', _cancelados, Colors.red.shade200),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: cor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kPurpleLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_note_rounded,
                size: 52, color: kPurple),
          ),
          const SizedBox(height: 20),
          const Text(
            'Nenhum agendamento ainda',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Novo Agendamento" para começar',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
