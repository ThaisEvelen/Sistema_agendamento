package organizaAI.OrganizaAI.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.DiaBloqueadoRequest;
import organizaAI.OrganizaAI.dto.DiaBloqueadoResponse;
import organizaAI.OrganizaAI.service.DiaBloqueadoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dias-bloqueados")
@RequiredArgsConstructor
public class DiaBloqueadoController {

    private final DiaBloqueadoService service;

    // GET /api/dias-bloqueados — listar todos
    @GetMapping
    public List<DiaBloqueadoResponse> listar() {
        return service.listarTodos();
    }

    // POST /api/dias-bloqueados — bloquear um dia
    @PostMapping
    public ResponseEntity<DiaBloqueadoResponse> bloquear(
            @Valid @RequestBody DiaBloqueadoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.bloquear(request));
    }

    // DELETE /api/dias-bloqueados/{id} — desbloquear
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desbloquear(@PathVariable Long id) {
        service.desbloquear(id);
        return ResponseEntity.noContent().build();
    }
}
