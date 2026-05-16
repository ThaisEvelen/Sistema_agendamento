package organizaAI.OrganizaAI.dto;

import lombok.Data;
import organizaAI.OrganizaAI.dto.servico.ServicoResponse;
import organizaAI.OrganizaAI.entity.Agendamento;
import organizaAI.OrganizaAI.entity.enums.Status;

import java.time.LocalDateTime;

@Data
public class AgendamentoResponse {

    private Long id;
    private Long clienteId;
    private String nomeCliente;
    private String telefoneCliente;
    private ServicoResponse servico;
    private LocalDateTime dataHora;
    private LocalDateTime dataHoraFim;
    private Status status;

    public static AgendamentoResponse fromEntity(Agendamento agendamento) {
        AgendamentoResponse response = new AgendamentoResponse();
        response.id = agendamento.getId();
        response.nomeCliente = agendamento.getNomeCliente();
        if (agendamento.getCliente() != null) {
            response.clienteId = agendamento.getCliente().getId();
            response.telefoneCliente = agendamento.getCliente().getTelefone();
        }
        response.servico = ServicoResponse.fromEntity(agendamento.getServico());
        response.dataHora = agendamento.getDataHora();
        response.dataHoraFim = agendamento.getDataHoraFim();
        response.status = agendamento.getStatus();
        return response;
    }
}
