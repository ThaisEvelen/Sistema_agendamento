package organizaAI.OrganizaAI.repository;

import organizaAI.OrganizaAI.entity.HorarioBloqueado;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface HorarioBloqueadoRepository extends JpaRepository<HorarioBloqueado, Long> {

    boolean existsByDataAndHora(LocalDate data, Integer hora);

    Optional<HorarioBloqueado> findByDataAndHora(LocalDate data, Integer hora);

    List<HorarioBloqueado> findByData(LocalDate data);

    // Retorna apenas os números das horas bloqueadas em um dia
    @Query("SELECT h.hora FROM HorarioBloqueado h WHERE h.data = :data")
    List<Integer> findHorasByData(@Param("data") LocalDate data);
}
