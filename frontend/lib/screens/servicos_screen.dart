import 'package:flutter/material.dart';
import '../models/servico.dart';
import '../services/servico_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_app_bar.dart';
import 'criar_servico_screen.dart';

class ServicosScreen extends StatefulWidget {
  const ServicosScreen({super.key});

  @override
  State<ServicosScreen> createState() => _ServicosScreenState();
}

class _ServicosScreenState extends State<ServicosScreen> {
  final ServicoService _service = ServicoService();
  List<Servico> _servicos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final lista = await _service.listarTodos();
      setState(() => _servicos = lista);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _alternarStatus(Servico servico) async {
    try {
      if (servico.ativo) {
        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Desativar Serviço'),
            content: Text(
                'Deseja desativar "${servico.nome}"?\nEle não aparecerá para novos agendamentos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Desativar',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirmar != true) return;
        await _service.desativar(servico.id);
      } else {
        await _service.reativar(servico.id);
      }
      await _carregar();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              servico.ativo ? 'Serviço desativado' : 'Serviço reativado'),
          backgroundColor: servico.ativo ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentIndex: 3),
      appBar: const GradientAppBar(title: 'Serviços'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriarServicoScreen()),
          );
          _carregar();
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Serviço'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _servicos.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.build_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Nenhum serviço cadastrado',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _servicos.length,
                    itemBuilder: (context, index) {
                      final servico = _servicos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: servico.ativo
                                ? Colors.green.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: servico.ativo
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Colors.grey.shade200,
                            child: Icon(
                              Icons.build,
                              color: servico.ativo
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  servico.nome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: servico.ativo ? null : Colors.grey,
                                    decoration: servico.ativo
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              Text(
                                servico.precoFormatado,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: servico.ativo
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (servico.descricao != null &&
                                  servico.descricao!.isNotEmpty)
                                Text(servico.descricao!),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.timer,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    servico.duracaoFormatada,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: servico.ativo
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: servico.ativo
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    child: Text(
                                      servico.ativo ? 'Ativo' : 'Inativo',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: servico.ativo
                                            ? Colors.green
                                            : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: servico.ativo,
                            onChanged: (_) => _alternarStatus(servico),
                            activeColor: Colors.green,
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
