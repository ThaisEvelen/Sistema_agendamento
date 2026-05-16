package organizaAI.OrganizaAI.repository;

import organizaAI.OrganizaAI.entity.Servico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ServicoRepository extends JpaRepository<Servico, Long> {

    // Retorna apenas serviços ativos
    List<Servico> findByAtivoTrue();

    // Verifica se já existe serviço com o mesmo nome
    boolean existsByNomeIgnoreCase(String nome);
}
