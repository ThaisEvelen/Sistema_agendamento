package organizaAI.OrganizaAI.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Data
@Entity
@Table(
    name = "horarios_bloqueados",
    uniqueConstraints = @UniqueConstraint(columnNames = {"data", "hora"})
)
public class HorarioBloqueado {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Data do horário bloqueado
    @Column(nullable = false)
    private LocalDate data;

    // Hora bloqueada (ex: 9 = 09:00, 14 = 14:00)
    @Column(nullable = false)
    private Integer hora;

    // Motivo opcional
    @Column
    private String motivo;
}
