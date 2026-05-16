import 'package:flutter/material.dart';
import '../models/servico.dart';
import '../services/servico_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';
import 'criar_screen.dart';

class OrcamentoScreen extends StatefulWidget {
  const OrcamentoScreen({super.key});

  @override
  State<OrcamentoScreen> createState() => _OrcamentoScreenState();
}

class _OrcamentoScreenState extends State<OrcamentoScreen> {
  final ServicoService _service = ServicoService();

  List<Servico> _servicos = [];
  final Set<int> _selecionados = {}; // ids dos serviços selecionados
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  Future<void> _carregarServicos() async {
    try {
      final lista = await _service.listarAtivos();
      setState(() {
        _servicos = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Serviços que estão selecionados
  List<Servico> get _servicosSelecionados =>
      _servicos.where((s) => _selecionados.contains(s.id)).toList();

  // Total em reais
  double get _totalPreco =>
      _servicosSelecionados.fold(0.0, (soma, s) => soma + s.preco);

  // Total em minutos
  int get _totalMinutos =>
      _servicosSelecionados.fold(0, (soma, s) => soma + s.duracaoMinutos);

  // Duração total formatada
  String get _duracaoTotalFormatada {
    if (_totalMinutos < 60) return '$_totalMinutos min';
    final h = _totalMinutos ~/ 60;
    final m = _totalMinutos % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }

  // Preço formatado
  String get _precoFormatado =>
      'R\$ ${_totalPreco.toStringAsFixed(2).replaceAll('.', ',')}';

  void _limpar() {
    setState(() => _selecionados.clear());
  }

  @override
  Widget build(BuildContext context) {
    final temSelecao = _selecionados.isNotEmpty;

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 2),
      appBar: GradientAppBar(
        title: 'Orçamento',
        actions: [
          if (temSelecao)
            TextButton.icon(
              onPressed: _limpar,
              icon: const Icon(Icons.clear_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Limpar',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _servicos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_circle_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum serviço cadastrado',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Instrução
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.5),
                      child: Text(
                        'Selecione os serviços para montar o orçamento',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    // Lista de serviços
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        itemCount: _servicos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final servico = _servicos[index];
                          final selecionado =
                              _selecionados.contains(servico.id);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (selecionado) {
                                  _selecionados.remove(servico.id);
                                } else {
                                  _selecionados.add(servico.id);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selecionado
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: selecionado ? 2 : 1,
                                ),
                                color: selecionado
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withOpacity(0.4)
                                    : null,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: selecionado
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade200,
                                  child: Icon(
                                    selecionado
                                        ? Icons.check
                                        : Icons.build_outlined,
                                    color: selecionado
                                        ? Colors.white
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  servico.nome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selecionado
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  servico.descricao ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      servico.precoFormatado,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: selecionado
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.timer,
                                            size: 12, color: Colors.grey[600]),
                                        const SizedBox(width: 2),
                                        Text(
                                          servico.duracaoFormatada,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Painel de resumo (só aparece se tiver algo selecionado)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: temSelecao
                          ? _buildResumo(context)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildResumo(BuildContext context) {
    return Container(
      key: const ValueKey('resumo'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título
          Row(
            children: [
              Icon(Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Resumo do Orçamento',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista dos itens selecionados
          ..._servicosSelecionados.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(s.nome,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      s.precoFormatado,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )),

          const Divider(height: 20),

          // Totais
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Tempo total: $_duracaoTotalFormatada',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              Text(
                _precoFormatado,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Botão Agendar
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CriarScreen()),
              );
            },
            icon: const Icon(Icons.calendar_today),
            label: const Text('Agendar agora',
                style: TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
