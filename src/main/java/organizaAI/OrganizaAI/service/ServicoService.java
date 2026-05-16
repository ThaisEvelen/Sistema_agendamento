package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.servico.ServicoRequest;
import organizaAI.OrganizaAI.dto.servico.ServicoResponse;
import organizaAI.OrganizaAI.entity.Servico;
import organizaAI.OrganizaAI.repository.ServicoRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ServicoService {

    private final ServicoRepository repository;

    // CRIAR
    public ServicoResponse criar(ServicoRequest request) {
        if (repository.existsByNomeIgnoreCase(request.getNome())) {
            throw new RuntimeException("Já existe um serviço com o nome: " + request.getNome());
        }

        Servico servico = new Servico();
        servico.setNome(request.getNome());
        servico.setDescricao(request.getDescricao());
        servico.setDuracaoMinutos(request.getDuracaoMinutos());
        servico.setPreco(request.getPreco());

        return ServicoResponse.fromEntity(repository.save(servico));
    }

    // LISTAR TODOS ATIVOS
    public List<ServicoResponse> listarAtivos() {
        return repository.findByAtivoTrue()
                .stream()
                .map(ServicoResponse::fromEntity)
                .toList();
    }

    // LISTAR TODOS (inclusive inativos — para admin)
    public List<ServicoResponse> listarTodos() {
        return repository.findAll()
                .stream()
                .map(ServicoResponse::fromEntity)
                .toList();
    }

    // BUSCAR POR ID
    public ServicoResponse buscarPorId(Long id) {
        Servico servico = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Serviço não encontrado com id: " + id));
        return ServicoResponse.fromEntity(servico);
    }

    // ATUALIZAR
    public ServicoResponse atualizar(Long id, ServicoRequest request) {
        Servico servico = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Serviço não encontrado com id: " + id));

        servico.setNome(request.getNome());
        servico.setDescricao(request.getDescricao());
        servico.setDuracaoMinutos(request.getDuracaoMinutos());
        servico.setPreco(request.getPreco());

        return ServicoResponse.fromEntity(repository.save(servico));
    }

    // DESATIVAR (soft delete)
    public void desativar(Long id) {
        Servico servico = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Serviço não encontrado com id: " + id));

        if (!servico.getAtivo()) {
            throw new RuntimeException("Serviço já está desativado");
        }

        servico.setAtivo(false);
        repository.save(servico);
    }

    // REATIVAR
    public ServicoResponse reativar(Long id) {
        Servico servico = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Serviço não encontrado com id: " + id));

        if (servico.getAtivo()) {
            throw new RuntimeException("Serviço já está ativo");
        }

        servico.setAtivo(true);
        return ServicoResponse.fromEntity(repository.save(servico));
    }
}
