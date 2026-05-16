package organizaAI.OrganizaAI.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Data
@Entity
@Table(name = "dias_bloqueados")
public class DiaBloqueado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Data bloqueada (única por dia)
    @Column(nullable = false, unique = true)
    private LocalDate data;

    // Motivo opcional (ex: "Férias", "Feriado", "Folga")
    @Column
    private String motivo;
}
