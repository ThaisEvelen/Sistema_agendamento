package organizaAI.OrganizaAI.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class HorarioBloqueadoRequest {

    @NotNull(message = "A data é obrigatória")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate data;

    @NotNull(message = "A hora é obrigatória")
    @Min(value = 0, message = "Hora inválida")
    @Max(value = 23, message = "Hora inválida")
    private Integer hora;

    private String motivo;
}
