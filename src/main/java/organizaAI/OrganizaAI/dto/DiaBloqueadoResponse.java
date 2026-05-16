package organizaAI.OrganizaAI.dto;

import lombok.Data;
import organizaAI.OrganizaAI.entity.DiaBloqueado;

@Data
public class DiaBloqueadoResponse {

    private Long id;
    private String data;       // "2025-06-10"
    private String motivo;

    public static DiaBloqueadoResponse fromEntity(DiaBloqueado d) {
        DiaBloqueadoResponse r = new DiaBloqueadoResponse();
        r.id = d.getId();
        r.data = d.getData().toString();
        r.motivo = d.getMotivo();
        return r;
    }
}
