package organizaAI.OrganizaAI.controller;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import organizaAI.OrganizaAI.dto.AgendamentoRequest;
import organizaAI.OrganizaAI.dto.AgendamentoResponse;
import organizaAI.OrganizaAI.entity.enums.Status;
import organizaAI.OrganizaAI.service.AgendamentoService;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/agendamentos")
@RequiredArgsConstructor
public class AgendamentoController {

    private final AgendamentoService service;

    // POST /api/agendamentos
    @PostMapping
    public ResponseEntity<AgendamentoResponse> criar(@RequestBody @Valid AgendamentoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.criar(request));
    }

    // GET /api/agendamentos
    @GetMapping
    public ResponseEntity<List<AgendamentoResponse>> listarTodos() {
        return ResponseEntity.ok(service.listarTodos());
    }

    // GET /api/agendamentos/1
    @GetMapping("/{id}")
    public ResponseEntity<AgendamentoResponse> buscarPorId(@PathVariable Long id) {
        return ResponseEntity.ok(service.buscarPorId(id));
    }

    // GET /api/agendamentos/status?status=PENDENTE
    @GetMapping("/status")
    public ResponseEntity<List<AgendamentoResponse>> buscarPorStatus(@RequestParam Status status) {
        return ResponseEntity.ok(service.buscarPorStatus(status));
    }

    // GET /api/agendamentos/cliente?nome=joao
    @GetMapping("/cliente")
    public ResponseEntity<List<AgendamentoResponse>> buscarPorCliente(@RequestParam String nome) {
        return ResponseEntity.ok(service.buscarPorCliente(nome));
    }

    // GET /api/agendamentos/data?data=2026-06-01
    @GetMapping("/data")
    public ResponseEntity<List<AgendamentoResponse>> buscarPorData(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate data) {
        return ResponseEntity.ok(service.buscarPorData(data));
    }

    // PATCH /api/agendamentos/1/status?novoStatus=CONFIRMADO
    @PatchMapping("/{id}/status")
    public ResponseEntity<AgendamentoResponse> atualizarStatus(
            @PathVariable Long id,
            @RequestParam Status novoStatus) {
        return ResponseEntity.ok(service.atualizarStatus(id, novoStatus));
    }

    // DELETE /api/agendamentos/1
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> cancelar(@PathVariable Long id) {
        service.cancelar(id);
        return ResponseEntity.noContent().build();
    }
}
