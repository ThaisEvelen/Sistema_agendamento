package organizaAI.OrganizaAI.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.ClienteRequest;
import organizaAI.OrganizaAI.dto.ClienteResponse;
import organizaAI.OrganizaAI.service.ClienteService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clientes")
@RequiredArgsConstructor
public class ClienteController {

    private final ClienteService service;

    // GET /api/clientes  ou  GET /api/clientes?nome=joao
    @GetMapping
    public List<ClienteResponse> listar(
            @RequestParam(required = false) String nome) {
        if (nome != null && !nome.isBlank()) {
            return service.buscarPorNome(nome);
        }
        return service.listarTodos();
    }

    // GET /api/clientes/{id}
    @GetMapping("/{id}")
    public ClienteResponse buscarPorId(@PathVariable Long id) {
        return service.buscarPorId(id);
    }

    // POST /api/clientes
    @PostMapping
    public ResponseEntity<ClienteResponse> criar(
            @Valid @RequestBody ClienteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.criar(request));
    }

    // PUT /api/clientes/{id}
    @PutMapping("/{id}")
    public ClienteResponse atualizar(
            @PathVariable Long id,
            @Valid @RequestBody ClienteRequest request) {
        return service.atualizar(id, request);
    }

    // DELETE /api/clientes/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletar(@PathVariable Long id) {
        service.deletar(id);
        return ResponseEntity.noContent().build();
    }
}
