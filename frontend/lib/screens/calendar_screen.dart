import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/agendamento.dart';
import '../models/dia_bloqueado.dart';
import '../models/horario_bloqueado.dart';
import '../services/agendamento_service.dart';
import '../services/dia_bloqueado_service.dart';
import '../services/horario_bloqueado_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/gradient_app_bar.dart';
import '../theme/app_colors.dart';
import 'criar_screen.dart';
import 'detalhe_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final AgendamentoService _service = AgendamentoService();
  final DiaBloqueadoService _diaBloqueadoService = DiaBloqueadoService();
  final HorarioBloqueadoService _horarioBloqueadoService =
      HorarioBloqueadoService();

  DateTime _diaSelecionado = DateTime.now();
  DateTime _diaFocado = DateTime.now();
  List<Agendamento> _agendamentosDoDia = [];
  List<DiaBloqueado> _diasBloqueados = [];
  List<HorarioBloqueado> _horariosBloqueadosDoDia = [];
  bool _carregando = false;
  CalendarFormat _formato = CalendarFormat.week;

  final List<int> _horarios = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  @override
  void initState() {
    super.initState();
    _carregarTudo(_diaSelecionado);
  }

  Future<void> _carregarTudo(DateTime dia) async {
    setState(() => _carregando = true);
    try {
      final resultados = await Future.wait([
        _service.buscarPorData(dia),
        _diaBloqueadoService.listarTodos(),
        _horarioBloqueadoService.listarPorData(dia),
      ]);
      setState(() {
        _agendamentosDoDia = resultados[0] as List<Agendamento>;
        _diasBloqueados = resultados[1] as List<DiaBloqueado>;
        _horariosBloqueadosDoDia = resultados[2] as List<HorarioBloqueado>;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _carregarAgendamentosDoDia(DateTime dia) async {
    setState(() => _carregando = true);
    try {
      final agendamentos = await _service.buscarPorData(dia);
      final horariosBloqueados =
          await _horarioBloqueadoService.listarPorData(dia);
      setState(() {
        _agendamentosDoDia = agendamentos;
        _horariosBloqueadosDoDia = horariosBloqueados;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Retorna o HorarioBloqueado para uma hora, ou null se livre
  HorarioBloqueado? _horarioBloqueadoNaHora(int hora) {
    try {
      return _horariosBloqueadosDoDia.firstWhere((h) => h.hora == hora);
    } catch (_) {
      return null;
    }
  }

  // ── Bloquear horário ─────────────────────────────────────────────
  Future<void> _bloquearHorario(int hora) async {
    final motivoController = TextEditingController();
    final horaTexto = '${hora.toString().padLeft(2, '0')}:00';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Bloquear horário'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$horaTexto — ${DateFormat("dd/MM/yyyy", 'pt_BR').format(_diaSelecionado)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ex: Almoço, Reunião...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _horarioBloqueadoService.bloquear(
        _diaSelecionado,
        hora,
        motivoController.text.trim().isEmpty
            ? null
            : motivoController.text.trim(),
      );
      await _carregarAgendamentosDoDia(_diaSelecionado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Horário $horaTexto bloqueado'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Desbloquear horário ──────────────────────────────────────────
  Future<void> _desbloquearHorario(HorarioBloqueado bloqueio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: kPurple),
            SizedBox(width: 8),
            Text('Desbloquear horário'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${bloqueio.horaTexto} — ${DateFormat("dd/MM/yyyy", 'pt_BR').format(_diaSelecionado)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (bloqueio.motivo != null) ...[
                const SizedBox(height: 6),
                Text('Motivo: ${bloqueio.motivo}',
                    style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 8),
              const Text('Deseja liberar este horário?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _horarioBloqueadoService.desbloquear(bloqueio.id);
      await _carregarAgendamentosDoDia(_diaSelecionado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Horário desbloqueado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Retorna o DiaBloqueado para um dia, ou null se livre
  DiaBloqueado? _bloqueioNoDia(DateTime dia) {
    try {
      return _diasBloqueados.firstWhere(
        (d) =>
            d.data.year == dia.year &&
            d.data.month == dia.month &&
            d.data.day == dia.day,
      );
    } catch (_) {
      return null;
    }
  }

  bool get _diaSelecionadoBloqueado =>
      _bloqueioNoDia(_diaSelecionado) != null;

  // ── Bloquear dia ────────────────────────────────────────────────
  Future<void> _bloquearDia() async {
    final motivoController = TextEditingController();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Bloquear dia'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat("EEEE, dd 'de' MMMM", 'pt_BR')
                    .format(_diaSelecionado),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ex: Férias, Feriado, Folga...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),
            ],
          ),
        ),
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
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _diaBloqueadoService.bloquear(
        _diaSelecionado,
        motivoController.text.trim().isEmpty
            ? null
            : motivoController.text.trim(),
      );
      await _carregarTudo(_diaSelecionado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dia bloqueado com sucesso'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ── Desbloquear dia ──────────────────────────────────────────────
  Future<void> _desbloquearDia() async {
    final bloqueio = _bloqueioNoDia(_diaSelecionado);
    if (bloqueio == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: kPurple),
            SizedBox(width: 8),
            Text('Desbloquear dia'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat("EEEE, dd 'de' MMMM", 'pt_BR')
                    .format(_diaSelecionado),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (bloqueio.motivo != null) ...[
                const SizedBox(height: 8),
                Text('Motivo: ${bloqueio.motivo}',
                    style: const TextStyle(color: Colors.grey)),
              ],
              const SizedBox(height: 8),
              const Text('Deseja liberar este dia para agendamentos?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _diaBloqueadoService.desbloquear(bloqueio.id);
      await _carregarTudo(_diaSelecionado);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dia desbloqueado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Agendamento? _agendamentoNoHorario(int hora) {
    try {
      return _agendamentosDoDia.firstWhere(
        (a) {
          if (a.status == 'CANCELADO') return false;
          final inicioSlot = DateTime(
            _diaSelecionado.year,
            _diaSelecionado.month,
            _diaSelecionado.day,
            hora,
          );
          return a.dataHora.isBefore(inicioSlot.add(const Duration(hours: 1))) &&
              a.dataHoraFim.isAfter(inicioSlot);
        },
      );
    } catch (_) {
      return null;
    }
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'CONFIRMADO':
        return Colors.green;
      case 'CANCELADO':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloqueio = _bloqueioNoDia(_diaSelecionado);

    return Scaffold(
      drawer: const AppDrawer(currentIndex: 1),
      appBar: GradientAppBar(
        title: 'Calendário',
        actions: [
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Hoje',
            onPressed: () {
              setState(() {
                _diaSelecionado = DateTime.now();
                _diaFocado = DateTime.now();
              });
              _carregarTudo(DateTime.now());
            },
          ),
        ],
      ),
      floatingActionButton: _diaSelecionadoBloqueado
          ? null // sem FAB em dia bloqueado
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CriarScreen()),
                );
                _carregarAgendamentosDoDia(_diaSelecionado);
              },
              icon: const Icon(Icons.add),
              label: const Text('Novo Agendamento'),
            ),
      body: Column(
        children: [
          // ── Calendário ─────────────────────────────────────────
          TableCalendar(
            locale: 'pt_BR',
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _diaFocado,
            selectedDayPredicate: (day) => isSameDay(_diaSelecionado, day),
            calendarFormat: _formato,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mês',
              CalendarFormat.week: 'Semana',
            },
            onFormatChanged: (f) => setState(() => _formato = f),
            onDaySelected: (diaSelecionado, diaFocado) {
              setState(() {
                _diaSelecionado = diaSelecionado;
                _diaFocado = diaFocado;
              });
              _carregarTudo(diaSelecionado);
            },
            // Marcador vermelho em dias bloqueados
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, _) {
                if (_bloqueioNoDia(day) != null) {
                  return Positioned(
                    bottom: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: _diaSelecionadoBloqueado
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(
                    color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(8),
              ),
              formatButtonTextStyle: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Cabeçalho do dia ────────────────────────────────────
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _diaSelecionadoBloqueado
                    ? [
                        Colors.red.withOpacity(0.08),
                        Colors.red.withOpacity(0.03),
                      ]
                    : [
                        kPurple.withOpacity(0.08),
                        kIndigo.withOpacity(0.04),
                      ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: _diaSelecionadoBloqueado
                      ? Colors.red.withOpacity(0.2)
                      : kPurple.withOpacity(0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                // Ícone do dia
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: _diaSelecionadoBloqueado
                        ? const LinearGradient(
                            colors: [Colors.red, Color(0xFFE53935)])
                        : kPrimaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _diaSelecionadoBloqueado
                        ? Icons.block_rounded
                        : Icons.event_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat("EEEE, dd 'de' MMMM", 'pt_BR')
                            .format(_diaSelecionado),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _diaSelecionadoBloqueado
                              ? Colors.red
                              : kPurple,
                        ),
                      ),
                      if (bloqueio?.motivo != null)
                        Text(
                          bloqueio!.motivo!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.red),
                        ),
                    ],
                  ),
                ),
                // Botão bloquear / desbloquear
                TextButton.icon(
                  onPressed: _diaSelecionadoBloqueado
                      ? _desbloquearDia
                      : _bloquearDia,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: Size.zero,
                  ),
                  icon: Icon(
                    _diaSelecionadoBloqueado
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    size: 15,
                    color: _diaSelecionadoBloqueado ? kPurple : Colors.red,
                  ),
                  label: Text(
                    _diaSelecionadoBloqueado ? 'Desbloquear' : 'Bloquear',
                    style: TextStyle(
                      fontSize: 12,
                      color: _diaSelecionadoBloqueado ? kPurple : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Conteúdo ────────────────────────────────────────────
          Expanded(
            child: _carregando
                ? const Center(child: CircularProgressIndicator())
                : _diaSelecionadoBloqueado
                    ? _buildDiaBloqueadoView(bloqueio!)
                    : _buildListaHorarios(),
          ),
        ],
      ),
    );
  }

  // Vista de dia bloqueado
  Widget _buildDiaBloqueadoView(DiaBloqueado bloqueio) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_rounded,
                  size: 56, color: Colors.red),
            ),
            const SizedBox(height: 20),
            const Text(
              'Dia bloqueado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (bloqueio.motivo != null) ...[
              const SizedBox(height: 8),
              Text(
                bloqueio.motivo!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Nenhum agendamento pode ser\nfeito neste dia.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: _desbloquearDia,
              icon: const Icon(Icons.lock_open_rounded, color: kPurple),
              label: const Text('Desbloquear este dia',
                  style: TextStyle(color: kPurple)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kPurple),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lista normal de horários
  Widget _buildListaHorarios() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      dragStartBehavior: DragStartBehavior.down,
      itemCount: _horarios.length,
      separatorBuilder: (_, index) {
        if (index + 1 < _horarios.length) {
          final nextHora = _horarios[index + 1];
          final nextAgendamento = _agendamentoNoHorario(nextHora);
          if (nextAgendamento != null &&
              nextAgendamento.dataHora.hour != nextHora) {
            return const SizedBox.shrink();
          }
        }
        return const SizedBox(height: 8);
      },
      itemBuilder: (context, index) {
        final hora = _horarios[index];
        final agendamento = _agendamentoNoHorario(hora);
        final horarioBloqueado = _horarioBloqueadoNaHora(hora);

        // Slot de continuação de agendamento: ocultar
        if (agendamento != null && agendamento.dataHora.hour != hora) {
          return const SizedBox.shrink();
        }

        // Horário bloqueado
        if (horarioBloqueado != null) {
          return _buildHorarioBloqueadoTile(hora, horarioBloqueado);
        }

        final ocupado = agendamento != null;
        return _buildHorarioTile(hora, agendamento, ocupado);
      },
    );
  }

  // Tile para horário bloqueado
  Widget _buildHorarioBloqueadoTile(int hora, HorarioBloqueado bloqueio) {
    final horaTexto = '${hora.toString().padLeft(2, '0')}:00';
    final horaFimTexto = '${(hora + 1).toString().padLeft(2, '0')}:00';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
        color: Colors.orange.withOpacity(0.06),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, color: Colors.orange, size: 16),
            const SizedBox(height: 2),
            Text(
              horaTexto,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              horaFimTexto,
              style: TextStyle(
                  fontSize: 10, color: Colors.orange.withOpacity(0.7)),
            ),
          ],
        ),
        title: const Text(
          'Bloqueado',
          style: TextStyle(
              color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        subtitle: bloqueio.motivo != null
            ? Text(bloqueio.motivo!,
                style: TextStyle(color: Colors.orange.shade700))
            : const Text('Horário indisponível',
                style: TextStyle(color: Colors.orange)),
        trailing: IconButton(
          icon: const Icon(Icons.lock_open_rounded,
              color: Colors.orange, size: 20),
          tooltip: 'Desbloquear',
          onPressed: () => _desbloquearHorario(bloqueio),
        ),
      ),
    );
  }

  Widget _buildHorarioTile(int hora, Agendamento? agendamento, bool ocupado) {
    final horaTexto = '${hora.toString().padLeft(2, '0')}:00';
    final horaFimTexto = ocupado
        ? '${agendamento!.dataHoraFim.hour.toString().padLeft(2, '0')}:${agendamento.dataHoraFim.minute.toString().padLeft(2, '0')}'
        : '${(hora + 1).toString().padLeft(2, '0')}:00';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ocupado
              ? _corStatus(agendamento!.status).withOpacity(0.5)
              : Colors.green.withOpacity(0.4),
        ),
        color: ocupado
            ? _corStatus(agendamento!.status).withOpacity(0.05)
            : Colors.green.withOpacity(0.05),
      ),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ocupado ? Icons.circle : Icons.circle_outlined,
              color: ocupado ? _corStatus(agendamento!.status) : Colors.green,
              size: 12,
            ),
            const SizedBox(height: 2),
            Text(
              horaTexto,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color:
                    ocupado ? _corStatus(agendamento!.status) : Colors.green,
              ),
            ),
            Text(
              horaFimTexto,
              style: TextStyle(
                fontSize: 10,
                color: ocupado
                    ? _corStatus(agendamento!.status).withOpacity(0.7)
                    : Colors.green.withOpacity(0.7),
              ),
            ),
          ],
        ),
        title: ocupado
            ? Text(agendamento!.nomeCliente,
                style: const TextStyle(fontWeight: FontWeight.bold))
            : const Text('Disponível',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.w500)),
        subtitle: ocupado
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (agendamento!.telefoneCliente != null)
                    Row(children: [
                      const Icon(Icons.phone, size: 11, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(agendamento.telefoneCliente!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ]),
                  Row(children: [
                    Flexible(child: Text(agendamento.servico.nome)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            _corStatus(agendamento.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _corStatus(agendamento.status)),
                      ),
                      child: Text(
                        agendamento.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: _corStatus(agendamento.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),
                ],
              )
            : const Text('Toque para agendar'),
        trailing: ocupado
            ? const Icon(Icons.arrow_forward_ios, size: 14)
            // Slot livre: botão de agendar + cadeado para bloquear
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.lock_outline,
                        color: Colors.orange, size: 20),
                    tooltip: 'Bloquear horário',
                    onPressed: () => _bloquearHorario(hora),
                  ),
                  const Icon(Icons.add_circle_outline,
                      color: Colors.green, size: 20),
                ],
              ),
        onTap: () async {
          if (ocupado) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetalheScreen(agendamento: agendamento!),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CriarScreen()),
            );
          }
          _carregarAgendamentosDoDia(_diaSelecionado);
        },
      ),
    );
  }
}
