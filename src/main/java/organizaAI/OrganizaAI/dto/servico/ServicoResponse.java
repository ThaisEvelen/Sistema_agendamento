package organizaAI.OrganizaAI.dto.servico;

import lombok.Data;
import organizaAI.OrganizaAI.entity.Servico;
import java.math.BigDecimal;

@Data
public class ServicoResponse {

    private Long id;
    private String nome;
    private String descricao;
    private Integer duracaoMinutos;
    private String duracaoFormatada;
    private BigDecimal preco;
    private Boolean ativo;

    public static ServicoResponse fromEntity(Servico servico) {
        ServicoResponse response = new ServicoResponse();
        response.id = servico.getId();
        response.nome = servico.getNome();
        response.descricao = servico.getDescricao();
        response.duracaoMinutos = servico.getDuracaoMinutos();
        response.duracaoFormatada = formatarDuracao(servico.getDuracaoMinutos());
        response.preco = servico.getPreco();
        response.ativo = servico.getAtivo();
        return response;
    }

    // Converte minutos para formato legível
    // Ex: 90 → "1h 30min" | 60 → "1h" | 30 → "30min"
    private static String formatarDuracao(int minutos) {
        if (minutos < 60) {
            return minutos + "min";
        }
        int horas = minutos / 60;
        int min = minutos % 60;
        return min == 0 ? horas + "h" : horas + "h " + min + "min";
    }
}
