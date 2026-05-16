package organizaAI.OrganizaAI.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {

    private String token;
    private String nome;
    private String email;
    private String role;
}
