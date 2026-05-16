import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/app_drawer.dart';
import '../theme/app_colors.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final ClienteService _service = ClienteService();
  final _searchController = TextEditingController();

  List<Cliente> _clientes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregar({String? busca}) async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar(nome: busca);
      if (mounted) setState(() => _clientes = lista);
    } catch (e) {
      if (mounted) {
        _snack('Erro ao carregar clientes: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: cor),
    );
  }

  // ── Dialogo Criar/Editar ─────────────────────────────────────────
  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final nomeCtrl = TextEditingController(text: cliente?.nome ?? '');
    final telefoneCtrl = TextEditingController(text: cliente?.telefone ?? '');
    final formKey = GlobalKey<FormState>();
    bool salvando = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            cliente == null ? 'Novo Cliente' : 'Editar Cliente',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: telefoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _TelefoneFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Telefone / WhatsApp',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    hintText: '(00) 00000-0000',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Telefone é obrigatório';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: salvando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => salvando = true);
                      try {
                        if (cliente == null) {
                          await _service.criar(
                            nomeCtrl.text.trim(),
                            telefoneCtrl.text.trim(),
                          );
                        } else {
                          await _service.atualizar(
                            cliente.id,
                            nomeCtrl.text.trim(),
                            telefoneCtrl.text.trim(),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        _carregar();
                      } catch (e) {
                        if (ctx.mounted) {
                          _snack(
                              e.toString().replaceAll('Exception: ', ''),
                              Colors.red);
                          Navigator.pop(ctx);
                        }
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: kPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(cliente == null ? 'Cadastrar' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmar exclusão ───────────────────────────────────────────
  Future<void> _confirmarExclusao(Cliente cliente) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir Cliente'),
        content: Text(
          'Deseja excluir ${cliente.nome}?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.deletar(cliente.id);
      _carregar();
      _snack('${cliente.nome} removido', Colors.green);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Clientes',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _carregar();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentIndex: 4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Novo Cliente'),
        backgroundColor: kPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ── Barra de busca ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => _carregar(busca: v.trim().isEmpty ? null : v),
              decoration: InputDecoration(
                hintText: 'Buscar cliente por nome...',
                prefixIcon:
                    const Icon(Icons.search, color: kPurple),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _carregar();
                        },
                      )
                    : null,
                filled: true,
                fillColor: kPurpleLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),

          // ── Contador ───────────────────────────────────────────
          if (!_carregando)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${_clientes.length} cliente${_clientes.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

          // ── Lista ──────────────────────────────────────────────
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _clientes.isEmpty
                    ? _buildVazio()
                    : RefreshIndicator(
                        onRefresh: () => _carregar(),
                        color: kPurple,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _clientes.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              _buildCard(_clientes[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Cliente cliente) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: kPrimaryGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              cliente.iniciais,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          cliente.nome,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.phone, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              cliente.telefone,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: kPurple, size: 20),
              onPressed: () => _abrirFormulario(cliente: cliente),
              tooltip: 'Editar',
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmarExclusao(cliente),
              tooltip: 'Excluir',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: kPurpleLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline,
                size: 56, color: kPurple.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isEmpty
                ? 'Nenhum cliente cadastrado'
                : 'Nenhum cliente encontrado',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Toque em "Novo Cliente" para começar'
                : 'Tente outro nome na busca',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Formatador de telefone ─────────────────────────────────────────
class _TelefoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (i == 7) buf.write('-');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
