package organizaAI.OrganizaAI.entity;

import jakarta.persistence.*;
import lombok.Data;
import organizaAI.OrganizaAI.entity.enums.Status;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "agendamentos")
public class Agendamento {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nomeCliente;

    // Vínculo opcional com um cliente cadastrado
    @ManyToOne(fetch = FetchType.EAGER, optional = true)
    @JoinColumn(name = "cliente_id", nullable = true)
    private Cliente cliente;

    // Relacionamento com Servico — muitos agendamentos para um serviço
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "servico_id", nullable = false)
    private Servico servico;

    @Column(nullable = false)
    private LocalDateTime dataHora;

    // Hora de término calculada com base na duração do serviço
    @Column(nullable = false)
    private LocalDateTime dataHoraFim;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Status status = Status.PENDENTE;
}
