package organizaAI.OrganizaAI.dto.chat;

import lombok.Data;

@Data
public class ChatRequest {
    private String mensagem;
    private String sessaoId; // ID de sessão para manter contexto da conversa
}
