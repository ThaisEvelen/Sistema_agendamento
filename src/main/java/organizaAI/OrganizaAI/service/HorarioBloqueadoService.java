package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.HorarioBloqueadoRequest;
import organizaAI.OrganizaAI.dto.HorarioBloqueadoResponse;
import organizaAI.OrganizaAI.entity.HorarioBloqueado;
import organizaAI.OrganizaAI.repository.HorarioBloqueadoRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
public class HorarioBloqueadoService {

    private final HorarioBloqueadoRepository repository;

    // BLOQUEAR um horário
    public HorarioBloqueadoResponse bloquear(HorarioBloqueadoRequest request) {
        if (repository.existsByDataAndHora(request.getData(), request.getHora())) {
            throw new RuntimeException(
                "O horário das " + String.format("%02d:00", request.getHora()) +
                " já está bloqueado neste dia"
            );
        }

        HorarioBloqueado h = new HorarioBloqueado();
        h.setData(request.getData());
        h.setHora(request.getHora());
        h.setMotivo(request.getMotivo());

        return HorarioBloqueadoResponse.fromEntity(repository.save(h));
    }

    // DESBLOQUEAR por id
    public void desbloquear(Long id) {
        HorarioBloqueado h = repository.findById(id)
                .orElseThrow(() -> new RuntimeException("Horário bloqueado não encontrado"));
        repository.delete(h);
    }

    // LISTAR por data
    public List<HorarioBloqueadoResponse> listarPorData(LocalDate data) {
        return repository.findByData(data)
                .stream()
                .map(HorarioBloqueadoResponse::fromEntity)
                .toList();
    }

    // Retorna as horas bloqueadas de um dia (para validação)
    public List<Integer> horasBloqueadasNoDia(LocalDate data) {
        return repository.findHorasByData(data);
    }
}
