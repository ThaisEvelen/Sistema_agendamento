package organizaAI.OrganizaAI.dto;

import lombok.Data;
import organizaAI.OrganizaAI.entity.HorarioBloqueado;

@Data
public class HorarioBloqueadoResponse {

    private Long id;
    private String data;      // "2025-06-10"
    private Integer hora;     // 14
    private String horaTexto; // "14:00"
    private String motivo;

    public static HorarioBloqueadoResponse fromEntity(HorarioBloqueado h) {
        HorarioBloqueadoResponse r = new HorarioBloqueadoResponse();
        r.id = h.getId();
        r.data = h.getData().toString();
        r.hora = h.getHora();
        r.horaTexto = String.format("%02d:00", h.getHora());
        r.motivo = h.getMotivo();
        return r;
    }
}
