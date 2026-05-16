package organizaAI.OrganizaAI.repository;

import organizaAI.OrganizaAI.entity.Agendamento;
import organizaAI.OrganizaAI.entity.enums.Status;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AgendamentoRepository extends JpaRepository<Agendamento, Long> {

    List<Agendamento> findByStatus(Status status);

    List<Agendamento> findByNomeClienteContainingIgnoreCase(String nomeCliente);

    List<Agendamento> findByDataHoraBetweenOrderByDataHoraAsc(LocalDateTime inicio, LocalDateTime fim);

    // Busca agendamentos que conflitam com o horário (início até fim)
    // Ignora cancelados e o próprio agendamento (para edição futura)
    @Query("SELECT a FROM Agendamento a WHERE a.status != 'CANCELADO' " +
           "AND (:idIgnorar IS NULL OR a.id != :idIgnorar) " +
           "AND a.dataHora < :fim AND a.dataHoraFim > :inicio")
    List<Agendamento> findConflitos(
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim,
            @Param("idIgnorar") Long idIgnorar);
}
