package organizaAI.OrganizaAI.controller;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import organizaAI.OrganizaAI.dto.chat.ChatRequest;
import organizaAI.OrganizaAI.dto.chat.ChatResponse;
import organizaAI.OrganizaAI.service.ChatbotService;

@RestController
@RequestMapping("/api/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService service;

    // POST /api/chatbot/mensagem
    @PostMapping("/mensagem")
    public ChatResponse processar(@RequestBody ChatRequest request) {
        String sessaoId = request.getSessaoId() != null
            ? request.getSessaoId()
            : "default";
        return service.processar(sessaoId, request.getMensagem());
    }

    // GET /api/chatbot/ping  (para testar conexão)
    @GetMapping("/ping")
    public ChatResponse ping() {
        return ChatResponse.sucesso("Assistente online!");
    }
}
