import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/servico_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';

class CriarServicoScreen extends StatefulWidget {
  const CriarServicoScreen({super.key});

  @override
  State<CriarServicoScreen> createState() => _CriarServicoScreenState();
}

class _CriarServicoScreenState extends State<CriarServicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final ServicoService _service = ServicoService();

  bool _salvando = false;

  // Duração selecionada em minutos
  int _duracaoSelecionada = 60;

  // Opções de duração disponíveis
  final List<Map<String, dynamic>> _opcoesDuracao = [
    {'minutos': 15, 'label': '15 min'},
    {'minutos': 30, 'label': '30 min'},
    {'minutos': 45, 'label': '45 min'},
    {'minutos': 60, 'label': '1h'},
    {'minutos': 90, 'label': '1h 30min'},
    {'minutos': 120, 'label': '2h'},
    {'minutos': 150, 'label': '2h 30min'},
    {'minutos': 180, 'label': '3h'},
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    try {
      final preco = double.parse(
        _precoController.text.trim().replaceAll(',', '.'),
      );

      await _service.criar(
        _nomeController.text.trim(),
        _descricaoController.text.trim().isEmpty
            ? null
            : _descricaoController.text.trim(),
        _duracaoSelecionada,
        preco,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Serviço criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Novo Serviço'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Campo Nome
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Serviço',
                  prefixIcon: Icon(Icons.build),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo Descrição (opcional)
              TextFormField(
                controller: _descricaoController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Campo Preço
              TextFormField(
                controller: _precoController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Preço (R\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 50,00',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Preço é obrigatório';
                  }
                  final parsed =
                      double.tryParse(value.trim().replaceAll(',', '.'));
                  if (parsed == null || parsed < 0) {
                    return 'Informe um preço válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Seletor de duração
              const Text(
                'Duração do serviço',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Grid de opções de duração
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _opcoesDuracao.length,
                itemBuilder: (context, index) {
                  final opcao = _opcoesDuracao[index];
                  final selecionado = _duracaoSelecionada == opcao['minutos'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _duracaoSelecionada = opcao['minutos']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: selecionado
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selecionado
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          opcao['label'],
                          style: TextStyle(
                            color: selecionado ? Colors.white : Colors.black87,
                            fontWeight: selecionado
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Resumo da duração selecionada
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Duração selecionada: ${_opcoesDuracao.firstWhere((o) => o['minutos'] == _duracaoSelecionada)['label']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Botão Salvar com gradiente
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: _salvando ? null : kPrimaryGradient,
                  color: _salvando ? Colors.grey.shade300 : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: _salvando
                      ? null
                      : [
                          BoxShadow(
                            color: kPurple.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _salvando ? null : _salvar,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _salvando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Salvar Serviço',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
