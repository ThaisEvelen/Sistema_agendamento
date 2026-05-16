package organizaAI.OrganizaAI.dto.servico;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class ServicoRequest {

    @NotBlank(message = "Nome do serviço é obrigatório")
    private String nome;

    private String descricao;

    @NotNull(message = "Duração é obrigatória")
    @Min(value = 15, message = "Duração mínima é de 15 minutos")
    private Integer duracaoMinutos;

    @NotNull(message = "Preço é obrigatório")
    @DecimalMin(value = "0.0", inclusive = true, message = "Preço não pode ser negativo")
    private BigDecimal preco;
}
