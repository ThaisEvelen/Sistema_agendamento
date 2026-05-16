package organizaAI.OrganizaAI.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AgendamentoRequest {

    // Se clienteId for informado, o nome é obtido do cadastro de clientes.
    // Caso contrário, nomeCliente manual é usado.
    private Long clienteId;

    private String nomeCliente;

    @NotNull(message = "Serviço é obrigatório")
    private Long servicoId;

    @NotNull(message = "Data e hora são obrigatórios")
    @Future(message = "O agendamento deve ser em uma data futura")
    private LocalDateTime dataHora;
}
