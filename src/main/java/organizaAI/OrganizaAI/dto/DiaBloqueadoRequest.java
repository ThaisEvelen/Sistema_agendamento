package organizaAI.OrganizaAI.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class DiaBloqueadoRequest {

    @NotNull(message = "A data é obrigatória")
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate data;

    // Motivo é opcional (ex: "Férias", "Feriado")
    private String motivo;
}
