package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import organizaAI.OrganizaAI.dto.ClienteRequest;
import organizaAI.OrganizaAI.dto.ClienteResponse;
import organizaAI.OrganizaAI.entity.Cliente;
import organizaAI.OrganizaAI.repository.ClienteRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository repository;

    public List<ClienteResponse> listarTodos() {
        return repository.findAllByOrderByNomeAsc()
                .stream()
                .map(ClienteResponse::fromEntity)
                .toList();
    }

    public List<ClienteResponse> buscarPorNome(String nome) {
        return repository.findByNomeContainingIgnoreCaseOrderByNomeAsc(nome)
                .stream()
                .map(ClienteResponse::fromEntity)
                .toList();
    }

    public ClienteResponse buscarPorId(Long id) {
        Cliente cliente = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cliente não encontrado"));
        return ClienteResponse.fromEntity(cliente);
    }

    public ClienteResponse criar(ClienteRequest request) {
        Cliente cliente = new Cliente();
        cliente.setNome(request.getNome());
        cliente.setTelefone(request.getTelefone());
        return ClienteResponse.fromEntity(repository.save(cliente));
    }

    public ClienteResponse atualizar(Long id, ClienteRequest request) {
        Cliente cliente = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Cliente não encontrado"));
        cliente.setNome(request.getNome());
        cliente.setTelefone(request.getTelefone());
        return ClienteResponse.fromEntity(repository.save(cliente));
    }

    public void deletar(Long id) {
        if (!repository.existsById(id)) {
            throw new RuntimeException("Cliente não encontrado");
        }
        repository.deleteById(id);
    }
}
