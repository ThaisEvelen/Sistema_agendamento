package organizaAI.OrganizaAI.dto.chat;

import lombok.Data;

import java.util.List;

@Data
public class ChatResponse {

    private String resposta;
    private String tipo; // INFO | PERGUNTA | SUCESSO | ERRO | CONFIRMACAO
    private List<String> opcoes; // botões de resposta rápida

    // Construtores estáticos para cada tipo
    public static ChatResponse info(String msg) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "INFO";
        return r;
    }

    public static ChatResponse sucesso(String msg) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "SUCESSO";
        return r;
    }

    public static ChatResponse erro(String msg) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "ERRO";
        return r;
    }

    public static ChatResponse pergunta(String msg) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "PERGUNTA";
        return r;
    }

    public static ChatResponse pergunta(String msg, List<String> opcoes) {
        ChatResponse r = pergunta(msg);
        r.opcoes = opcoes;
        return r;
    }

    public static ChatResponse confirmacao(String msg) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "CONFIRMACAO";
        r.opcoes = List.of("Sim, confirmar", "Não, cancelar");
        return r;
    }

    public static ChatResponse confirmacaoComOpcoes(String msg, List<String> opcoes) {
        ChatResponse r = new ChatResponse();
        r.resposta = msg;
        r.tipo = "CONFIRMACAO";
        r.opcoes = opcoes;
        return r;
    }
}
