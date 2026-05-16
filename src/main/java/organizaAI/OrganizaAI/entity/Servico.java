package organizaAI.OrganizaAI.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;

@Data
@Entity
@Table(name = "servicos")
public class Servico {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    @Column
    private String descricao;

    // Duração em minutos (ex: 30, 60, 90, 120)
    @Column(nullable = false)
    private Integer duracaoMinutos;

    // Preço do serviço (ex: 50.00)
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal preco = BigDecimal.ZERO;

    // Permite desativar um serviço sem deletar
    @Column(nullable = false)
    private Boolean ativo = true;
}
