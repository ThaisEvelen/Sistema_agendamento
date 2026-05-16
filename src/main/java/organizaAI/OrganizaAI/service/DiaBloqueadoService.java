package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.DiaBloqueadoRequest;
import organizaAI.OrganizaAI.dto.DiaBloqueadoResponse;
import organizaAI.OrganizaAI.entity.DiaBloqueado;
import organizaAI.OrganizaAI.repository.DiaBloqueadoRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DiaBloqueadoService {

    private final DiaBloqueadoRepository repository;

    // BLOQUEAR um dia
    public DiaBloqueadoResponse bloquear(DiaBloqueadoRequest request) {
        if (repository.existsByData(request.getData())) {
            throw new RuntimeException("Este dia já está bloqueado");
        }

        DiaBloqueado dia = new DiaBloqueado();
        dia.setData(request.getData());
        dia.setMotivo(request.getMotivo());

        return DiaBloqueadoResponse.fromEntity(repository.save(dia));
    }

    // DESBLOQUEAR por id
    public void desbloquear(Long id) {
        DiaBloqueado dia = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Dia bloqueado não encontrado"));
        repository.delete(dia);
    }

    // LISTAR TODOS
    public List<DiaBloqueadoResponse> listarTodos() {
        return repository.findAllByOrderByDataAsc()
                .stream()
                .map(DiaBloqueadoResponse::fromEntity)
                .toList();
    }

    // VERIFICAR se um dia está bloqueado (usado pelo AgendamentoService)
    public boolean isDiaBloqueado(LocalDate data) {
        return repository.existsByData(data);
    }

    // BUSCAR o bloqueio de um dia (para pegar o motivo)
    public DiaBloqueadoResponse buscarPorData(LocalDate data) {
        return repository.findByData(data)
                .map(DiaBloqueadoResponse::fromEntity)
                .orElseThrow(() -> new RuntimeException("Dia não está bloqueado"));
    }
}
