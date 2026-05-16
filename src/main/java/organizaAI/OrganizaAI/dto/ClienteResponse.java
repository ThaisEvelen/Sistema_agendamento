package organizaAI.OrganizaAI.dto;

import lombok.Data;
import organizaAI.OrganizaAI.entity.Cliente;

@Data
public class ClienteResponse {

    private Long id;
    private String nome;
    private String telefone;

    public static ClienteResponse fromEntity(Cliente cliente) {
        ClienteResponse r = new ClienteResponse();
        r.id = cliente.getId();
        r.nome = cliente.getNome();
        r.telefone = cliente.getTelefone();
        return r;
    }
}
