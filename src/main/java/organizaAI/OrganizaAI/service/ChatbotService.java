package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import organizaAI.OrganizaAI.dto.chat.ChatResponse;
import organizaAI.OrganizaAI.entity.Agendamento;
import organizaAI.OrganizaAI.entity.Cliente;
import organizaAI.OrganizaAI.entity.Servico;
import organizaAI.OrganizaAI.repository.*;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ChatbotService {

    private final AgendamentoRepository agendamentoRepository;
    private final ServicoRepository servicoRepository;
    private final ClienteRepository clienteRepository;
    private final DiaBloqueadoRepository diaBloqueadoRepository;
    private final HorarioBloqueadoRepository horarioBloqueadoRepository;

    private static final Locale PT_BR = new Locale("pt", "BR");

    // ── Estado de conversa por sessão ─────────────────────────────────
    private final Map<String, ConversationState> sessions = new ConcurrentHashMap<>();

    private static class ConversationState {
        boolean aguardandoConfirmacao = false;
        boolean aguardandoCliente     = false;
        boolean aguardandoServico     = false;
        boolean aguardandoData        = false;
        boolean aguardandoHora        = false;

        Cliente  cliente;
        Servico  servico;
        LocalDate data;
        Integer  hora;

        // Horário pendente de confirmação
        LocalDateTime pendingInicio;

        void reset() {
            aguardandoConfirmacao = aguardandoCliente = aguardandoServico =
            aguardandoData = aguardandoHora = false;
            cliente = null; servico = null; data = null; hora = null;
            pendingInicio = null;
        }
    }

    // ── Ponto de entrada ──────────────────────────────────────────────
    public ChatResponse processar(String sessaoId, String mensagem) {
        ConversationState state = sessions.computeIfAbsent(sessaoId, k -> new ConversationState());
        String msg = mensagem.toLowerCase(PT_BR).trim();

        // Cancelar fluxo atual
        if (containsAny(msg, "cancela", "esquece", "recomeça", "reinicia", "sair", "menu")) {
            state.reset();
            return ChatResponse.info(msgBoasVindas());
        }

        // Despacha para o estado atual da conversa
        if (state.aguardandoConfirmacao) return handleConfirmacao(state, msg);
        if (state.aguardandoCliente)     return handleRespostaCliente(state, mensagem, msg);
        if (state.aguardandoServico)     return handleRespostaServico(state, mensagem, msg);
        if (state.aguardandoData)        return handleRespostaData(state, msg);
        if (state.aguardandoHora)        return handleRespostaHora(state, msg);

        // Detecta intenção principal
        if (containsAny(msg, "marca", "agendar", "agenda ", "marcar", "quero marcar",
                         "quero agendar", "precisa marcar", "marque")) {
            return handleAgendar(state, mensagem, msg);
        }
        if (containsAny(msg, "disponív", "livre", "tem horário", "tem vaga", "verificar",
                         "quando tem", "quando pode")) {
            return handleVerificarDisponibilidade(state, mensagem, msg);
        }
        if (containsAny(msg, "ver agenda", "lista", "mostra", "quais agend", "agendamentos",
                         "hoje tem", "tem hoje", "agenda de")) {
            return handleListar(msg);
        }
        if (containsAny(msg, "oi", "olá", "ola", "bom dia", "boa tarde", "boa noite", "hey", "salve")) {
            return ChatResponse.info(msgBoasVindas());
        }
        if (containsAny(msg, "ajuda", "help", "o que você", "o que voce", "como usar")) {
            return ChatResponse.info(msgAjuda());
        }

        return ChatResponse.info("Não entendi 😅 Posso te ajudar a:\n\n"
            + "• Marcar um horário — \"marcar a Maria para corte amanhã às 14h\"\n"
            + "• Ver agendamentos — \"agendamentos de hoje\"\n"
            + "• Verificar disponibilidade — \"tem horário livre amanhã às 15h?\"");
    }

    // ── Fluxo de agendamento ──────────────────────────────────────────
    private ChatResponse handleAgendar(ConversationState state, String original, String msg) {
        // Extrai o máximo de informações da mensagem
        Cliente  cliente = extrairCliente(original);
        Servico  servico = extrairServico(original);
        LocalDate data   = extrairData(msg);
        Integer  hora    = extrairHora(msg);

        if (cliente != null) state.cliente = cliente;
        if (servico != null) state.servico  = servico;
        if (data    != null) state.data     = data;
        if (hora    != null) state.hora     = hora;

        return continuarFluxo(state, original);
    }

    private ChatResponse continuarFluxo(ConversationState state, String ctx) {
        if (state.cliente == null) {
            state.aguardandoCliente = true;
            return ChatResponse.pergunta("Para quem é o agendamento?\nDigite o nome da cliente:");
        }
        if (state.servico == null) {
            state.aguardandoServico = true;
            List<Servico> servicos = servicoRepository.findByAtivoTrue();
            String lista = servicos.stream()
                .map(s -> "• " + s.getNome() + " (" + formatDuracao(s.getDuracaoMinutos()) + ")")
                .collect(Collectors.joining("\n"));
            return ChatResponse.pergunta("Qual serviço?\n\n" + lista);
        }
        if (state.data == null) {
            state.aguardandoData = true;
            return ChatResponse.pergunta("Para qual data?\nEx: hoje, amanhã, segunda, dia 20...");
        }
        if (state.hora == null) {
            state.aguardandoHora = true;
            return ChatResponse.pergunta("Qual horário?\nEx: 9h, 14h, 15:30...");
        }
        return tentarAgendar(state);
    }

    // ── Respostas às perguntas ────────────────────────────────────────
    private ChatResponse handleRespostaCliente(ConversationState state, String original, String msg) {
        state.aguardandoCliente = false;

        List<Cliente> encontrados = clienteRepository
            .findByNomeContainingIgnoreCaseOrderByNomeAsc(original.trim());

        if (encontrados.isEmpty()) {
            // Tenta só o primeiro nome
            String primeiroNome = original.trim().split("\\s+")[0];
            encontrados = clienteRepository
                .findByNomeContainingIgnoreCaseOrderByNomeAsc(primeiroNome);
        }

        if (encontrados.isEmpty()) {
            state.aguardandoCliente = true;
            return ChatResponse.pergunta("Não encontrei nenhuma cliente com esse nome 😕\n"
                + "Cadastre ela na tela de Clientes ou tente outro nome:");
        }

        if (encontrados.size() == 1) {
            state.cliente = encontrados.get(0);
        } else {
            // Múltiplas correspondências — pega a mais próxima do nome digitado
            String normalizado = original.trim().toLowerCase(PT_BR);
            state.cliente = encontrados.stream()
                .min(Comparator.comparingInt(c -> levenshtein(c.getNome().toLowerCase(PT_BR), normalizado)))
                .orElse(encontrados.get(0));
        }

        return continuarFluxo(state, original);
    }

    private ChatResponse handleRespostaServico(ConversationState state, String original, String msg) {
        state.aguardandoServico = false;
        Servico servico = extrairServico(original);

        if (servico == null) {
            state.aguardandoServico = true;
            String lista = servicoRepository.findByAtivoTrue().stream()
                .map(s -> "• " + s.getNome())
                .collect(Collectors.joining("\n"));
            return ChatResponse.pergunta("Não encontrei esse serviço. Escolha um da lista:\n\n" + lista);
        }

        state.servico = servico;
        return continuarFluxo(state, original);
    }

    private ChatResponse handleRespostaData(ConversationState state, String msg) {
        state.aguardandoData = false;
        LocalDate data = extrairData(msg);

        if (data == null) {
            state.aguardandoData = true;
            return ChatResponse.pergunta("Não entendi a data 😕\nTente: hoje, amanhã, segunda, dia 20, 15/06...");
        }

        state.data = data;
        return continuarFluxo(state, msg);
    }

    private ChatResponse handleRespostaHora(ConversationState state, String msg) {
        state.aguardandoHora = false;
        Integer hora = extrairHora(msg);

        if (hora == null) {
            state.aguardandoHora = true;
            return ChatResponse.pergunta("Não entendi o horário 😕\nTente: 9h, 14h, 15:30...");
        }

        state.hora = hora;
        return tentarAgendar(state);
    }

    // ── Verificar disponibilidade ─────────────────────────────────────
    private ChatResponse handleVerificarDisponibilidade(ConversationState state, String original, String msg) {
        LocalDate data  = extrairData(msg);
        Integer   hora  = extrairHora(msg);
        Servico servico = extrairServico(original);

        if (data == null) data = LocalDate.now();

        // Se não especificou serviço, usa o de menor duração (60 min padrão)
        if (servico == null) {
            servico = servicoRepository.findByAtivoTrue().stream()
                .min(Comparator.comparingInt(Servico::getDuracaoMinutos))
                .orElse(null);
        }

        if (hora != null && servico != null) {
            LocalDateTime inicio = data.atTime(hora, 0);
            LocalDateTime fim    = inicio.plusMinutes(servico.getDuracaoMinutos());

            if (slotDisponivel(data, inicio, fim)) {
                return ChatResponse.sucesso(String.format(
                    "Horario livre!\n\nData: %s as %02d:00\nServico: %s (%s)\n\nDeseja marcar um agendamento?",
                    formatData(data), hora, servico.getNome(), formatDuracao(servico.getDuracaoMinutos())));
            } else {
                LocalDateTime proximo = encontrarProximoSlot(inicio.plusHours(1), servico);
                String sugestao = proximo != null
                    ? String.format("\n\nProximo disponivel: %s as %02d:00\nDeseja marcar para esse horario?",
                        formatData(proximo.toLocalDate()), proximo.getHour())
                    : "\n\nNao encontrei horarios disponiveis nos proximos 30 dias.";
                return ChatResponse.info(String.format(
                    "Horario das %02d:00 em %s esta ocupado.%s", hora, formatData(data), sugestao));
            }
        }

        // Mostra disponibilidade do dia inteiro
        if (servico != null) {
            return mostrarDisponibilidadeDia(data, servico);
        }

        return ChatResponse.info("Me diga a data e hora para verificar.\nEx: \"tem horario livre amanha as 15h?\"");
    }

    // ── Listar agendamentos ───────────────────────────────────────────
    private ChatResponse handleListar(String msg) {
        LocalDate data = extrairData(msg);
        if (data == null) data = LocalDate.now();

        LocalDateTime inicio = data.atStartOfDay();
        LocalDateTime fim    = data.atTime(23, 59, 59);
        List<Agendamento> lista = agendamentoRepository.findByDataHoraBetweenOrderByDataHoraAsc(inicio, fim);

        if (lista.isEmpty()) {
            return ChatResponse.info("Nenhum agendamento para " + formatData(data) + ".");
        }

        StringBuilder sb = new StringBuilder();
        sb.append("Agendamentos de ").append(formatData(data))
          .append(" (").append(lista.size()).append("):\n\n");

        for (Agendamento a : lista) {
            String icone = switch (a.getStatus()) {
                case CONFIRMADO -> "V";
                case CANCELADO  -> "X";
                default          -> "...";
            };
            sb.append(String.format("[%s] %02d:00 - %02d:00 | %s (%s)\n",
                icone,
                a.getDataHora().getHour(),
                a.getDataHoraFim().getHour(),
                a.getNomeCliente(),
                a.getServico().getNome()));
        }

        return ChatResponse.info(sb.toString().trim());
    }

    // ── Disponibilidade do dia completo ───────────────────────────────
    private ChatResponse mostrarDisponibilidadeDia(LocalDate data, Servico servico) {
        if (diaBloqueadoRepository.existsByData(data)) {
            return ChatResponse.info(formatData(data) + " esta bloqueado para agendamentos.");
        }

        List<Integer> horasBloqueadas = horarioBloqueadoRepository.findHorasByData(data);
        StringBuilder sb = new StringBuilder();
        sb.append("Disponibilidade de ").append(formatData(data))
          .append(" (").append(servico.getNome()).append("):\n\n");

        for (int h = 8; h <= 18; h++) {
            LocalDateTime ini = data.atTime(h, 0);
            LocalDateTime fim = ini.plusMinutes(servico.getDuracaoMinutos());
            if (fim.getHour() > 19) break;

            if (horasBloqueadas.contains(h)) {
                sb.append(String.format("[bloq] %02d:00\n", h));
            } else {
                boolean livre = agendamentoRepository.findConflitos(ini, fim, null).isEmpty();
                sb.append(String.format("[%s] %02d:00\n", livre ? "livre" : "ocupado", h));
            }
        }

        return ChatResponse.info(sb.toString().trim());
    }

    // ── Tentar criar o agendamento ────────────────────────────────────
    private ChatResponse tentarAgendar(ConversationState state) {
        LocalDateTime inicio = state.data.atTime(state.hora, 0);

        // Horário no passado
        if (inicio.isBefore(LocalDateTime.now())) {
            state.data = null;
            state.hora = null;
            state.aguardandoData = true;
            return ChatResponse.pergunta("Esse horario ja passou!\nPara qual data quer marcar?");
        }

        Servico       servico = state.servico;
        LocalDateTime fim     = inicio.plusMinutes(servico.getDuracaoMinutos());

        // Dia bloqueado
        if (diaBloqueadoRepository.existsByData(state.data)) {
            String motivo = diaBloqueadoRepository.findByData(state.data)
                .map(d -> d.getMotivo() != null ? " (" + d.getMotivo() + ")" : "")
                .orElse("");
            LocalDateTime proximo = encontrarProximoSlot(inicio.plusDays(1).withHour(8), servico);
            String sugestao = proximo != null
                ? String.format("\n\nProximo disponivel: %s as %02d:00\nDeseja marcar?",
                    formatData(proximo.toLocalDate()), proximo.getHour())
                : "";

            if (proximo != null) {
                state.data  = proximo.toLocalDate();
                state.hora  = proximo.getHour();
                state.pendingInicio = proximo;
                state.aguardandoConfirmacao = true;
            } else {
                state.reset();
            }

            return ChatResponse.info(String.format(
                "%s esta bloqueado%s.%s", formatData(state.data != null ? state.data : inicio.toLocalDate()), motivo, sugestao));
        }

        // Hora bloqueada
        List<Integer> horasBloqueadas = horarioBloqueadoRepository.findHorasByData(state.data);
        int horaFim = fim.getHour() + (fim.getMinute() > 0 ? 1 : 0);
        for (int h = state.hora; h < horaFim; h++) {
            if (horasBloqueadas.contains(h)) {
                LocalDateTime proximo = encontrarProximoSlot(inicio.plusHours(1), servico);
                String sugestao = proximo != null
                    ? String.format("\n\nProximo disponivel: %s as %02d:00\nDeseja marcar?",
                        formatData(proximo.toLocalDate()), proximo.getHour())
                    : "";

                if (proximo != null) {
                    state.data  = proximo.toLocalDate();
                    state.hora  = proximo.getHour();
                    state.pendingInicio = proximo;
                    state.aguardandoConfirmacao = true;
                } else {
                    state.reset();
                }

                return ChatResponse.info(String.format(
                    "Horario das %02d:00 esta bloqueado.%s", h, sugestao));
            }
        }

        // Conflito com outro agendamento
        List<Agendamento> conflitos = agendamentoRepository.findConflitos(inicio, fim, null);
        if (!conflitos.isEmpty()) {
            Agendamento conflito = conflitos.get(0);
            LocalDateTime proximo = encontrarProximoSlot(conflito.getDataHoraFim(), servico);

            String sugestao = "";
            if (proximo != null) {
                state.data  = proximo.toLocalDate();
                state.hora  = proximo.getHour();
                state.pendingInicio = proximo;
                state.aguardandoConfirmacao = true;
                sugestao = String.format(
                    "\n\nProximo horario disponivel:\n%s as %02d:00 - %02d:00\n\nDeseja marcar para esse horario?",
                    formatData(proximo.toLocalDate()),
                    proximo.getHour(),
                    proximo.plusMinutes(servico.getDuracaoMinutos()).getHour());
            } else {
                state.reset();
                sugestao = "\n\nNao encontrei horarios disponiveis nos proximos 30 dias.";
            }

            return ChatResponse.confirmacaoComOpcoes(
                String.format(
                    "Horario ocupado!\n\n%s as %02d:00 ja tem:\n%s - %s\n(termina as %02d:00)%s",
                    formatData(inicio.toLocalDate()), state.hora != null ? state.hora : inicio.getHour(),
                    conflito.getNomeCliente(), conflito.getServico().getNome(),
                    conflito.getDataHoraFim().getHour(),
                    sugestao),
                proximo != null ? List.of("Sim, marcar proximo", "Nao, obrigado") : List.of("Ok, entendi")
            );
        }

        // Horario disponivel — pede confirmacao
        state.pendingInicio = inicio;
        state.aguardandoConfirmacao = true;

        return ChatResponse.confirmacao(String.format(
            "Horario disponivel!\n\n"
            + "Cliente: %s\n"
            + "Telefone: %s\n"
            + "Servico: %s (%s)\n"
            + "Data: %s as %02d:00\n"
            + "Termino: %02d:00\n\n"
            + "Confirma o agendamento?",
            state.cliente.getNome(),
            state.cliente.getTelefone(),
            servico.getNome(),
            formatDuracao(servico.getDuracaoMinutos()),
            formatData(state.data),
            state.hora,
            fim.getHour()));
    }

    // ── Confirmacao (sim/nao) ─────────────────────────────────────────
    private ChatResponse handleConfirmacao(ConversationState state, String msg) {
        boolean sim = containsAny(msg, "sim", "s", "confirma", "confirmar", "pode", "ok",
                                  "yes", "isso", "certo", "marcar proximo", "marcar", "quero");
        boolean nao = containsAny(msg, "não", "nao", "n", "cancela", "cancelar", "no",
                                  "nao obrigado", "obrigado", "nao quero");

        if (!sim && !nao) {
            return ChatResponse.pergunta("Confirma o agendamento? Responda sim ou nao.");
        }

        if (nao) {
            state.reset();
            return ChatResponse.info("Ok, cancelado! Como mais posso te ajudar?");
        }

        // Cria o agendamento
        try {
            Agendamento ag = new Agendamento();
            ag.setNomeCliente(state.cliente.getNome());
            ag.setCliente(state.cliente);
            ag.setServico(state.servico);
            ag.setDataHora(state.pendingInicio);
            ag.setDataHoraFim(state.pendingInicio.plusMinutes(state.servico.getDuracaoMinutos()));
            Agendamento salvo = agendamentoRepository.save(ag);

            String resposta = String.format(
                "Agendamento criado!\n\n"
                + "ID: #%d\n"
                + "Cliente: %s\n"
                + "Telefone: %s\n"
                + "Servico: %s\n"
                + "Data: %s as %02d:00\n"
                + "Termino: %02d:00",
                salvo.getId(),
                salvo.getNomeCliente(),
                state.cliente.getTelefone(),
                salvo.getServico().getNome(),
                formatData(salvo.getDataHora().toLocalDate()),
                salvo.getDataHora().getHour(),
                salvo.getDataHoraFim().getHour());

            state.reset();
            return ChatResponse.sucesso(resposta);

        } catch (Exception e) {
            state.reset();
            return ChatResponse.erro("Erro ao criar agendamento: " + e.getMessage());
        }
    }

    // ── Encontrar proximo slot livre ──────────────────────────────────
    private LocalDateTime encontrarProximoSlot(LocalDateTime aPairtir, Servico servico) {
        // Normaliza: sem minutos/segundos, dentro do horario comercial
        LocalDateTime atual = aPairtir.withMinute(0).withSecond(0).withNano(0);
        if (atual.getHour() < 8)  atual = atual.withHour(8);
        if (atual.getHour() > 18) atual = atual.toLocalDate().plusDays(1).atTime(8, 0);

        LocalDate dataAtual = atual.toLocalDate();

        for (int dia = 0; dia < 30; dia++) {
            LocalDate dataCheck = dataAtual.plusDays(dia);

            // Dia bloqueado — pula
            if (diaBloqueadoRepository.existsByData(dataCheck)) continue;

            List<Integer> horasBloqueadas = horarioBloqueadoRepository.findHorasByData(dataCheck);
            int horaInicio = dia == 0 ? atual.getHour() : 8;

            for (int h = horaInicio; h <= 18; h++) {
                if (horasBloqueadas.contains(h)) continue;

                LocalDateTime candidato = dataCheck.atTime(h, 0);
                if (candidato.isBefore(LocalDateTime.now())) continue;

                LocalDateTime candidatoFim = candidato.plusMinutes(servico.getDuracaoMinutos());
                if (candidatoFim.getHour() > 19) break; // nao cabe no dia

                if (agendamentoRepository.findConflitos(candidato, candidatoFim, null).isEmpty()) {
                    return candidato;
                }
            }
        }
        return null;
    }

    private boolean slotDisponivel(LocalDate data, LocalDateTime inicio, LocalDateTime fim) {
        if (diaBloqueadoRepository.existsByData(data)) return false;
        List<Integer> bloq = horarioBloqueadoRepository.findHorasByData(data);
        if (bloq.contains(inicio.getHour())) return false;
        return agendamentoRepository.findConflitos(inicio, fim, null).isEmpty();
    }

    // ── NLP: Extracao de entidades ────────────────────────────────────

    /** Extrai cliente da mensagem buscando padroes "a Maria", "para a Silva", etc. */
    private Cliente extrairCliente(String texto) {
        String[] prefixos = {"\\ba\\s+", "\\bpara a\\s+", "\\bpara\\s+",
                             "\\bp\\/\\s*", "\\bda\\s+", "\\bdo\\s+"};
        for (String prefixo : prefixos) {
            Pattern p = Pattern.compile(prefixo + "([A-ZÀ-Ÿa-zà-ÿ]+(?:\\s+[A-ZÀ-Ÿa-zà-ÿ]+)*)",
                Pattern.CASE_INSENSITIVE | Pattern.UNICODE_CHARACTER_CLASS);
            Matcher m = p.matcher(texto);
            while (m.find()) {
                String nome = m.group(1).trim();
                // Ignora palavras-chave que nao sao nomes
                if (containsAny(nome.toLowerCase(PT_BR), "corte", "color", "cabelo", "unhas", "manicure",
                        "pedicure", "massagem", "luzes", "escova", "hoje", "amanha", "segunda",
                        "servico", "horario")) continue;
                List<Cliente> encontrados = clienteRepository
                    .findByNomeContainingIgnoreCaseOrderByNomeAsc(nome);
                if (!encontrados.isEmpty()) return encontrados.get(0);
                // Tenta primeiro nome
                String primeiro = nome.split("\\s+")[0];
                encontrados = clienteRepository
                    .findByNomeContainingIgnoreCaseOrderByNomeAsc(primeiro);
                if (!encontrados.isEmpty()) return encontrados.get(0);
            }
        }
        return null;
    }

    /** Extrai servico por correspondencia com nomes cadastrados */
    private Servico extrairServico(String texto) {
        String lower = texto.toLowerCase(PT_BR);
        List<Servico> servicos = servicoRepository.findByAtivoTrue();

        // 1) Nome completo do servico no texto
        for (Servico s : servicos) {
            if (lower.contains(s.getNome().toLowerCase(PT_BR))) return s;
        }

        // 2) Palavras-chave do nome do servico (min 4 chars para evitar falsos positivos)
        for (Servico s : servicos) {
            for (String palavra : s.getNome().toLowerCase(PT_BR).split("\\s+")) {
                if (palavra.length() >= 4 && lower.contains(palavra)) return s;
            }
        }
        return null;
    }

    /** Extrai data em portugues */
    private LocalDate extrairData(String msg) {
        if (containsAny(msg, "depois de amanhã", "depois de amanha")) return LocalDate.now().plusDays(2);
        if (containsAny(msg, "amanhã", "amanha"))                     return LocalDate.now().plusDays(1);
        if (msg.contains("hoje"))                                      return LocalDate.now();

        // Dias da semana
        Map<String, DayOfWeek> diasSemana = new LinkedHashMap<>();
        diasSemana.put("segunda-feira", DayOfWeek.MONDAY);
        diasSemana.put("segunda", DayOfWeek.MONDAY);
        diasSemana.put("terça-feira", DayOfWeek.TUESDAY);
        diasSemana.put("terca-feira", DayOfWeek.TUESDAY);
        diasSemana.put("terça", DayOfWeek.TUESDAY);
        diasSemana.put("terca", DayOfWeek.TUESDAY);
        diasSemana.put("quarta-feira", DayOfWeek.WEDNESDAY);
        diasSemana.put("quarta", DayOfWeek.WEDNESDAY);
        diasSemana.put("quinta-feira", DayOfWeek.THURSDAY);
        diasSemana.put("quinta", DayOfWeek.THURSDAY);
        diasSemana.put("sexta-feira", DayOfWeek.FRIDAY);
        diasSemana.put("sexta", DayOfWeek.FRIDAY);
        diasSemana.put("sábado", DayOfWeek.SATURDAY);
        diasSemana.put("sabado", DayOfWeek.SATURDAY);
        diasSemana.put("domingo", DayOfWeek.SUNDAY);

        for (Map.Entry<String, DayOfWeek> e : diasSemana.entrySet()) {
            if (msg.contains(e.getKey())) return proximoDiaDaSemana(e.getValue());
        }

        // "dia 15"
        Matcher m1 = Pattern.compile("\\bdia\\s+(\\d{1,2})\\b").matcher(msg);
        if (m1.find()) {
            try {
                int dia = Integer.parseInt(m1.group(1));
                LocalDate candidato = LocalDate.now().withDayOfMonth(dia);
                if (candidato.isBefore(LocalDate.now())) candidato = candidato.plusMonths(1);
                return candidato;
            } catch (Exception ignored) {}
        }

        // "15/06" ou "15/06/2025"
        Matcher m2 = Pattern.compile("(\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?").matcher(msg);
        if (m2.find()) {
            try {
                int dia = Integer.parseInt(m2.group(1));
                int mes = Integer.parseInt(m2.group(2));
                int ano = m2.group(3) != null ? Integer.parseInt(m2.group(3)) : LocalDate.now().getYear();
                if (ano < 100) ano += 2000;
                return LocalDate.of(ano, mes, dia);
            } catch (Exception ignored) {}
        }

        return null;
    }

    /** Extrai hora em vários formatos: 14h, 14:00, duas da tarde, etc. */
    private Integer extrairHora(String msg) {
        // "14h", "9h30"
        Matcher m1 = Pattern.compile("\\b(\\d{1,2})h(?:\\d{2})?\\b").matcher(msg);
        if (m1.find()) {
            int h = Integer.parseInt(m1.group(1));
            return (h >= 0 && h <= 23) ? h : null;
        }

        // "14:00", "9:30"
        Matcher m2 = Pattern.compile("\\b(\\d{1,2}):(\\d{2})\\b").matcher(msg);
        if (m2.find()) {
            int h = Integer.parseInt(m2.group(1));
            return (h >= 0 && h <= 23) ? h : null;
        }

        // Horários por extenso
        Map<String, Integer> porExtenso = new LinkedHashMap<>();
        porExtenso.put("meia-noite", 0);
        porExtenso.put("meia noite", 0);
        porExtenso.put("meio-dia", 12);
        porExtenso.put("meio dia", 12);
        porExtenso.put("uma da tarde", 13);
        porExtenso.put("duas da tarde", 14);
        porExtenso.put("três da tarde", 15); porExtenso.put("tres da tarde", 15);
        porExtenso.put("quatro da tarde", 16);
        porExtenso.put("cinco da tarde", 17);
        porExtenso.put("seis da tarde", 18);
        porExtenso.put("sete da manhã", 7);  porExtenso.put("sete da manha", 7);
        porExtenso.put("oito da manhã", 8);  porExtenso.put("oito da manha", 8);
        porExtenso.put("nove da manhã", 9);  porExtenso.put("nove da manha", 9);
        porExtenso.put("dez da manhã", 10);  porExtenso.put("dez da manha", 10);
        porExtenso.put("onze da manhã", 11); porExtenso.put("onze da manha", 11);
        for (Map.Entry<String, Integer> e : porExtenso.entrySet()) {
            if (msg.contains(e.getKey())) return e.getValue();
        }

        // Genérico
        if (containsAny(msg, "manhã", "manha", "de manhã")) return 9;
        if (containsAny(msg, "tarde", "de tarde"))          return 14;
        if (containsAny(msg, "noite", "de noite"))          return 18;

        return null;
    }

    // ── Utilitários ───────────────────────────────────────────────────
    private LocalDate proximoDiaDaSemana(DayOfWeek dia) {
        LocalDate hoje = LocalDate.now();
        int diff = dia.getValue() - hoje.getDayOfWeek().getValue();
        if (diff <= 0) diff += 7;
        return hoje.plusDays(diff);
    }

    private String formatData(LocalDate data) {
        if (data == null) return "?";
        LocalDate hoje = LocalDate.now();
        if (data.equals(hoje))              return "hoje (" + data.format(DateTimeFormatter.ofPattern("dd/MM")) + ")";
        if (data.equals(hoje.plusDays(1)))  return "amanha (" + data.format(DateTimeFormatter.ofPattern("dd/MM")) + ")";
        return data.format(DateTimeFormatter.ofPattern("EEEE dd/MM", PT_BR));
    }

    private String formatDuracao(int minutos) {
        if (minutos < 60) return minutos + "min";
        int h = minutos / 60, m = minutos % 60;
        return m == 0 ? h + "h" : h + "h" + m + "min";
    }

    private boolean containsAny(String text, String... words) {
        for (String w : words) if (text.contains(w)) return true;
        return false;
    }

    /** Distância de Levenshtein simplificada para fuzzy matching de nomes */
    private int levenshtein(String a, String b) {
        int[][] dp = new int[a.length() + 1][b.length() + 1];
        for (int i = 0; i <= a.length(); i++) dp[i][0] = i;
        for (int j = 0; j <= b.length(); j++) dp[0][j] = j;
        for (int i = 1; i <= a.length(); i++) {
            for (int j = 1; j <= b.length(); j++) {
                dp[i][j] = a.charAt(i - 1) == b.charAt(j - 1)
                    ? dp[i - 1][j - 1]
                    : 1 + Math.min(dp[i - 1][j - 1], Math.min(dp[i - 1][j], dp[i][j - 1]));
            }
        }
        return dp[a.length()][b.length()];
    }

    private String msgBoasVindas() {
        return "Ola! Sou o assistente do OrganizaAI.\n\n"
            + "Posso te ajudar a:\n"
            + "- Marcar um horario\n"
            + "- Ver agendamentos do dia\n"
            + "- Verificar disponibilidade\n\n"
            + "Exemplo: \"marcar a Maria para corte amanha as 14h\"";
    }

    private String msgAjuda() {
        return "Como usar o assistente:\n\n"
            + "Marcar horario:\n"
            + "\"marcar a [cliente] para [servico] [data] as [hora]\"\n\n"
            + "Ver agendamentos:\n"
            + "\"agendamentos de hoje\" / \"agenda de amanha\"\n\n"
            + "Verificar disponibilidade:\n"
            + "\"tem horario livre amanha as 15h?\"\n\n"
            + "Cancelar acao atual: \"cancela\" ou \"menu\"";
    }
}
