package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import organizaAI.OrganizaAI.dto.AgendamentoRequest;
import organizaAI.OrganizaAI.dto.AgendamentoResponse;
import organizaAI.OrganizaAI.entity.Agendamento;
import organizaAI.OrganizaAI.entity.Servico;
import organizaAI.OrganizaAI.entity.enums.Status;
import organizaAI.OrganizaAI.exception.AgendamentoNaoEncontradoException;
import organizaAI.OrganizaAI.exception.StatusInvalidoException;
import organizaAI.OrganizaAI.entity.Cliente;
import organizaAI.OrganizaAI.repository.AgendamentoRepository;
import organizaAI.OrganizaAI.repository.ClienteRepository;
import organizaAI.OrganizaAI.repository.DiaBloqueadoRepository;
import organizaAI.OrganizaAI.repository.HorarioBloqueadoRepository;
import organizaAI.OrganizaAI.repository.ServicoRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AgendamentoService {

    private final AgendamentoRepository repository;
    private final ServicoRepository servicoRepository;
    private final ClienteRepository clienteRepository;
    private final DiaBloqueadoRepository diaBloqueadoRepository;
    private final HorarioBloqueadoRepository horarioBloqueadoRepository;

    // CRIAR
    public AgendamentoResponse criar(AgendamentoRequest request) {
        // Resolve o nome do cliente
        Cliente cliente = null;
        String nomeCliente = request.getNomeCliente();
        if (request.getClienteId() != null) {
            cliente = clienteRepository.findById(request.getClienteId())
                    .orElseThrow(() -> new RuntimeException("Cliente não encontrado"));
            nomeCliente = cliente.getNome();
        }
        if (nomeCliente == null || nomeCliente.isBlank()) {
            throw new RuntimeException("Nome do cliente é obrigatório");
        }

        // Busca o serviço pelo ID
        Servico servico = servicoRepository.findById(request.getServicoId())
                .orElseThrow(() -> new RuntimeException("Serviço não encontrado"));

        if (!servico.getAtivo()) {
            throw new RuntimeException("Serviço não está disponível");
        }

        // Verifica se o dia está bloqueado
        LocalDate dataDia = request.getDataHora().toLocalDate();
        if (diaBloqueadoRepository.existsByData(dataDia)) {
            String motivo = diaBloqueadoRepository.findByData(dataDia)
                    .map(d -> d.getMotivo() != null ? d.getMotivo() : "Dia indisponível")
                    .orElse("Dia indisponível");
            throw new RuntimeException("Este dia está bloqueado: " + motivo);
        }

        // Calcula o horário de término baseado na duração do serviço
        LocalDateTime dataHoraFim = request.getDataHora()
                .plusMinutes(servico.getDuracaoMinutos());

        // Verifica horários bloqueados dentro do intervalo do agendamento
        List<Integer> horasBloqueadas = horarioBloqueadoRepository.findHorasByData(dataDia);
        if (!horasBloqueadas.isEmpty()) {
            int horaInicio = request.getDataHora().getHour();
            int horaFim = dataHoraFim.getHour() + (dataHoraFim.getMinute() > 0 ? 1 : 0);
            for (int h = horaInicio; h < horaFim; h++) {
                if (horasBloqueadas.contains(h)) {
                    throw new RuntimeException(
                        "O horário das " + String.format("%02d:00", h) + " está bloqueado neste dia"
                    );
                }
            }
        }

        // Verifica conflito de horário
        verificarConflito(request.getDataHora(), dataHoraFim, null);

        Agendamento agendamento = new Agendamento();
        agendamento.setNomeCliente(nomeCliente);
        agendamento.setCliente(cliente);
        agendamento.setServico(servico);
        agendamento.setDataHora(request.getDataHora());
        agendamento.setDataHoraFim(dataHoraFim);

        return AgendamentoResponse.fromEntity(repository.save(agendamento));
    }

    // LISTAR TODOS
    public List<AgendamentoResponse> listarTodos() {
        return repository.findAll()
                .stream()
                .map(AgendamentoResponse::fromEntity)
                .toList();
    }

    // BUSCAR POR ID
    public AgendamentoResponse buscarPorId(Long id) {
        Agendamento agendamento = repository.findById(id)
                .orElseThrow(() -> new AgendamentoNaoEncontradoException(id));
        return AgendamentoResponse.fromEntity(agendamento);
    }

    // BUSCAR POR STATUS
    public List<AgendamentoResponse> buscarPorStatus(Status status) {
        return repository.findByStatus(status)
                .stream()
                .map(AgendamentoResponse::fromEntity)
                .toList();
    }

    // BUSCAR POR NOME DO CLIENTE
    public List<AgendamentoResponse> buscarPorCliente(String nomeCliente) {
        return repository.findByNomeClienteContainingIgnoreCase(nomeCliente)
                .stream()
                .map(AgendamentoResponse::fromEntity)
                .toList();
    }

    // BUSCAR POR DATA
    public List<AgendamentoResponse> buscarPorData(LocalDate data) {
        LocalDateTime inicio = data.atStartOfDay();
        LocalDateTime fim = data.atTime(23, 59, 59);
        return repository.findByDataHoraBetweenOrderByDataHoraAsc(inicio, fim)
                .stream()
                .map(AgendamentoResponse::fromEntity)
                .toList();
    }

    // ATUALIZAR STATUS
    public AgendamentoResponse atualizarStatus(Long id, Status novoStatus) {
        Agendamento agendamento = repository.findById(id)
                .orElseThrow(() -> new AgendamentoNaoEncontradoException(id));

        if (agendamento.getStatus() == Status.CANCELADO) {
            throw new StatusInvalidoException("Não é possível alterar um agendamento cancelado");
        }

        agendamento.setStatus(novoStatus);
        return AgendamentoResponse.fromEntity(repository.save(agendamento));
    }

    // CANCELAR
    public void cancelar(Long id) {
        Agendamento agendamento = repository.findById(id)
                .orElseThrow(() -> new AgendamentoNaoEncontradoException(id));

        if (agendamento.getStatus() == Status.CANCELADO) {
            throw new StatusInvalidoException("Agendamento já está cancelado");
        }

        agendamento.setStatus(Status.CANCELADO);
        repository.save(agendamento);
    }

    // Verifica se há conflito de horário com agendamentos existentes
    private void verificarConflito(LocalDateTime inicio, LocalDateTime fim, Long idIgnorar) {
        List<Agendamento> conflitos = repository.findConflitos(inicio, fim, idIgnorar);
        if (!conflitos.isEmpty()) {
            throw new RuntimeException(
                "Já existe um agendamento neste horário. " +
                "Por favor escolha outro horário."
            );
        }
    }
}
