package organizaAI.OrganizaAI.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.HorarioBloqueadoRequest;
import organizaAI.OrganizaAI.dto.HorarioBloqueadoResponse;
import organizaAI.OrganizaAI.service.HorarioBloqueadoService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/horarios-bloqueados")
@RequiredArgsConstructor
public class HorarioBloqueadoController {

    private final HorarioBloqueadoService service;

    // GET /api/horarios-bloqueados?data=2025-06-10
    @GetMapping
    public List<HorarioBloqueadoResponse> listarPorData(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        return service.listarPorData(data);
    }

    // POST /api/horarios-bloqueados
    @PostMapping
    public ResponseEntity<HorarioBloqueadoResponse> bloquear(
            @Valid @RequestBody HorarioBloqueadoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.bloquear(request));
    }

    // DELETE /api/horarios-bloqueados/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desbloquear(@PathVariable Long id) {
        service.desbloquear(id);
        return ResponseEntity.noContent().build();
    }
}
