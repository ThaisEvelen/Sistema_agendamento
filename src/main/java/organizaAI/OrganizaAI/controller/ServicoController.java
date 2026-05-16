package organizaAI.OrganizaAI.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.servico.ServicoRequest;
import organizaAI.OrganizaAI.dto.servico.ServicoResponse;
import organizaAI.OrganizaAI.service.ServicoService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/servicos")
@RequiredArgsConstructor
public class ServicoController {

    private final ServicoService service;

    // POST /api/servicos
    @PostMapping
    public ResponseEntity<ServicoResponse> criar(@RequestBody @Valid ServicoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.criar(request));
    }

    // GET /api/servicos (apenas ativos — para o app)
    @GetMapping
    public ResponseEntity<List<ServicoResponse>> listarAtivos() {
        return ResponseEntity.ok(service.listarAtivos());
    }

    // GET /api/servicos/todos (todos incluindo inativos — para admin)
    @GetMapping("/todos")
    public ResponseEntity<List<ServicoResponse>> listarTodos() {
        return ResponseEntity.ok(service.listarTodos());
    }

    // GET /api/servicos/1
    @GetMapping("/{id}")
    public ResponseEntity<ServicoResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    // PUT /api/servicos/1
    @PutMapping("/{id}")
    public ResponseEntity<ServicoResponse> atualizar(
            @PathVariable Long id,
            @RequestBody @Valid ServicoRequest request) {
        return ResponseEntity.ok(service.atualizar(id, request));
    }

    // DELETE /api/servicos/1 (soft delete — desativa)
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> desativar(@PathVariable Long id) {
        service.desativar(id);
        return ResponseEntity.noContent().build();
    }

    // PATCH /api/servicos/1/reativar
    @PatchMapping("/{id}/reativar")
    public ResponseEntity<ServicoResponse> reativar(@PathVariable Long id) {
        return ResponseEntity.ok(service.reativar(id));
    }
}
