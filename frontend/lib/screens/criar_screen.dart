import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/servico.dart';
import '../models/cliente.dart';
import '../services/agendamento_service.dart';
import '../services/servico_service.dart';
import '../services/cliente_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';

class CriarScreen extends StatefulWidget {
  const CriarScreen({super.key});

  @override
  State<CriarScreen> createState() => _CriarScreenState();
}

class _CriarScreenState extends State<CriarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeManualController = TextEditingController();
  final AgendamentoService _agendamentoService = AgendamentoService();
  final ServicoService _servicoService = ServicoService();
  final ClienteService _clienteService = ClienteService();

  List<Servico> _servicos = [];
  Servico? _servicoSelecionado;
  DateTime? _dataSelecionada;
  bool _salvando = false;
  bool _carregando = true;

  // Cliente selecionado da agenda (ou null = nome manual)
  Cliente? _clienteSelecionado;
  // Modo: true = selecionar da agenda, false = digitar manualmente
  bool _usarClienteCadastrado = true;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
  }

  @override
  void dispose() {
    _nomeManualController.dispose();
    super.dispose();
  }

  Future<void> _carregarServicos() async {
    try {
      final lista = await _servicoService.listarAtivos();
      setState(() {
        _servicos = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar serviços: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ── Picker de cliente ──────────────────────────────────────────────
  Future<void> _abrirPickerCliente() async {
    final searchCtrl = TextEditingController();
    List<Cliente> todos = [];
    List<Cliente> filtrados = [];
    bool carregando = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Carrega clientes na primeira exibição
          if (carregando && todos.isEmpty) {
            _clienteService.listar().then((lista) {
              if (ctx.mounted) {
                setS(() {
                  todos = lista;
                  filtrados = lista;
                  carregando = false;
                });
              }
            });
          }

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Título + botão novo
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Selecionar Cliente',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _cadastrarNovoClienteRapido();
                          },
                          icon: const Icon(Icons.person_add_alt_1,
                              size: 18),
                          label: const Text('Novo'),
                          style: TextButton.styleFrom(
                              foregroundColor: kPurple),
                        ),
                      ],
                    ),
                  ),
                  // Busca
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextField(
                      controller: searchCtrl,
                      onChanged: (v) => setS(() {
                        filtrados = v.isEmpty
                            ? todos
                            : todos
                                .where((c) => c.nome
                                    .toLowerCase()
                                    .contains(v.toLowerCase()))
                                .toList();
                      }),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome...',
                        prefixIcon: const Icon(Icons.search,
                            color: kPurple),
                        filled: true,
                        fillColor: kPurpleLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  // Lista
                  Expanded(
                    child: carregando
                        ? const Center(
                            child: CircularProgressIndicator())
                        : filtrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline,
                                        size: 48,
                                        color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Text(
                                      todos.isEmpty
                                          ? 'Nenhum cliente cadastrado'
                                          : 'Nenhum resultado',
                                      style: TextStyle(
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                controller: scrollCtrl,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: filtrados.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final c = filtrados[i];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: kPurple,
                                      child: Text(
                                        c.iniciais,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(c.nome,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600)),
                                    subtitle: Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 12,
                                            color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(c.telefone,
                                            style: TextStyle(
                                                color: Colors
                                                    .grey.shade600,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(
                                          () => _clienteSelecionado = c);
                                      Navigator.pop(ctx);
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Cadastrar cliente rápido sem sair da tela
  Future<void> _cadastrarNovoClienteRapido() async {
    final nomeCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final novoCliente = await showDialog<Cliente>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Novo Cliente',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nomeCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obrigatório' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                final c = await _clienteService.criar(
                    nomeCtrl.text.trim(), telCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx, c);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text(
                          e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: kPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );

    if (novoCliente != null) {
      setState(() => _clienteSelecionado = novoCliente);
      // Abre picker para confirmar seleção
    }
  }

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null || !mounted) return;
    final hora = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (hora == null || !mounted) return;
    setState(() {
      _dataSelecionada = DateTime(
          data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    // Validação do nome
    if (_usarClienteCadastrado && _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione um cliente da agenda'),
          backgroundColor: Colors.orange));
      return;
    }
    if (!_usarClienteCadastrado &&
        _nomeManualController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Digite o nome do cliente'),
          backgroundColor: Colors.orange));
      return;
    }
    if (_servicoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione um serviço'),
          backgroundColor: Colors.orange));
      return;
    }
    if (_dataSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Selecione a data e hora'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _salvando = true);
    try {
      await _agendamentoService.criar(
        _usarClienteCadastrado
            ? _clienteSelecionado!.nome
            : _nomeManualController.text.trim(),
        _servicoSelecionado!.id,
        _dataSelecionada!,
        clienteId: _usarClienteCadastrado ? _clienteSelecionado!.id : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Agendamento criado com sucesso!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(title: 'Novo Agendamento'),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Seção Cliente ────────────────────────────────
                    _buildSecaoCliente(),
                    const SizedBox(height: 20),

                    // ── Seletor de Serviço ───────────────────────────
                    const Text('Selecione o Serviço',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (_servicos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Nenhum serviço cadastrado. Cadastre um serviço primeiro.',
                                  style: TextStyle(color: Colors.orange))),
                        ]),
                      )
                    else
                      ..._servicos.map((servico) {
                        final sel = _servicoSelecionado?.id == servico.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _servicoSelecionado = servico),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: sel ? 2 : 1,
                              ),
                              color: sel
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : null,
                            ),
                            child: Row(children: [
                              Icon(
                                sel
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: sel
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(servico.nome,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: sel
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : null)),
                                      if (servico.descricao != null &&
                                          servico.descricao!.isNotEmpty)
                                        Text(servico.descricao!,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                    ]),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.timer,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(servico.duracaoFormatada,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ]),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // ── Data e Hora ──────────────────────────────────
                    OutlinedButton.icon(
                      onPressed: _selecionarDataHora,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _dataSelecionada == null
                            ? 'Selecionar Data e Hora'
                            : DateFormat('dd/MM/yyyy HH:mm')
                                .format(_dataSelecionada!),
                      ),
                      style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 16)),
                    ),

                    if (_dataSelecionada != null &&
                        _servicoSelecionado != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.schedule,
                                color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Término previsto: ${DateFormat('HH:mm').format(_dataSelecionada!.add(Duration(minutes: _servicoSelecionado!.duracaoMinutos)))}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ]),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Botão Salvar ─────────────────────────────────
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
                                )
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
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Text(
                                    'Salvar Agendamento',
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

  // ── Widget seção cliente ─────────────────────────────────────────
  Widget _buildSecaoCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cliente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Toggle: da agenda / manual
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _usarClienteCadastrado = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        _usarClienteCadastrado ? kPrimaryGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_rounded,
                            size: 16,
                            color: _usarClienteCadastrado
                                ? Colors.white
                                : Colors.grey),
                        const SizedBox(width: 6),
                        Text('Da agenda',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _usarClienteCadastrado
                                  ? Colors.white
                                  : Colors.grey,
                            )),
                      ]),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    setState(() => _usarClienteCadastrado = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient:
                        !_usarClienteCadastrado ? kPrimaryGradient : null,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_rounded,
                            size: 16,
                            color: !_usarClienteCadastrado
                                ? Colors.white
                                : Colors.grey),
                        const SizedBox(width: 6),
                        Text('Digitar nome',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: !_usarClienteCadastrado
                                  ? Colors.white
                                  : Colors.grey,
                            )),
                      ]),
                ),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 12),

        // Conteúdo dinâmico baseado no modo
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _usarClienteCadastrado
              ? _buildSeletorCliente()
              : _buildCampoNomeManual(),
        ),
      ],
    );
  }

  Widget _buildSeletorCliente() {
    return GestureDetector(
      key: const ValueKey('picker'),
      onTap: _abrirPickerCliente,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _clienteSelecionado != null
                ? kPurple
                : Colors.grey.shade300,
            width: _clienteSelecionado != null ? 2 : 1,
          ),
          color: _clienteSelecionado != null
              ? kPurpleLight
              : Colors.grey.shade50,
        ),
        child: _clienteSelecionado == null
            ? Row(children: [
                Icon(Icons.people_outline, color: Colors.grey.shade500),
                const SizedBox(width: 12),
                Text('Toque para selecionar um cliente',
                    style: TextStyle(color: Colors.grey.shade500)),
                const Spacer(),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ])
            : Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kPurple,
                  child: Text(_clienteSelecionado!.iniciais,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_clienteSelecionado!.nome,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Row(children: [
                          const Icon(Icons.phone,
                              size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(_clienteSelecionado!.telefone,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600)),
                        ]),
                      ]),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      setState(() => _clienteSelecionado = null),
                  color: Colors.grey,
                ),
              ]),
      ),
    );
  }

  Widget _buildCampoNomeManual() {
    return TextFormField(
      key: const ValueKey('manual'),
      controller: _nomeManualController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Nome do Cliente',
        prefixIcon: Icon(Icons.person_outline),
        border: OutlineInputBorder(),
      ),
    );
  }
}
