package organizaAI.OrganizaAI.repository;

import organizaAI.OrganizaAI.entity.DiaBloqueado;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DiaBloqueadoRepository extends JpaRepository<DiaBloqueado, Long> {

    boolean existsByData(LocalDate data);

    Optional<DiaBloqueado> findByData(LocalDate data);

    List<DiaBloqueado> findAllByOrderByDataAsc();
}
