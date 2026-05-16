package organizaAI.OrganizaAI.service;

import lombok.RequiredArgsConstructor;
import organizaAI.OrganizaAI.dto.auth.AuthResponse;
import organizaAI.OrganizaAI.dto.auth.LoginRequest;
import organizaAI.OrganizaAI.dto.auth.RegisterRequest;
import organizaAI.OrganizaAI.entity.User;
import organizaAI.OrganizaAI.repository.UserRepository;
import organizaAI.OrganizaAI.security.JwtUtil;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    // CADASTRO
    public AuthResponse register(RegisterRequest request) {

        // 1. Verifica se o email já está cadastrado
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email já cadastrado");
        }

        // 2. Cria o usuário com a senha criptografada
        User user = new User();
        user.setNome(request.getNome());
        user.setEmail(request.getEmail());
        user.setSenha(passwordEncoder.encode(request.getSenha()));

        // 3. Salva no banco
        userRepository.save(user);

        // 4. Gera o token JWT
        String token = jwtUtil.gerarToken(user.getEmail());

        // 5. Retorna o token + dados do usuário
        return new AuthResponse(
                token,
                user.getNome(),
                user.getEmail(),
                user.getRole().name()
        );
    }

    // LOGIN
    public AuthResponse login(LoginRequest request) {

        // 1. Autentica o email e senha (lança exceção se inválido)
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getSenha()
                )
        );

        // 2. Busca o usuário no banco
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado"));

        // 3. Gera o token JWT
        String token = jwtUtil.gerarToken(user.getEmail());

        // 4. Retorna o token + dados do usuário
        return new AuthResponse(
                token,
                user.getNome(),
                user.getEmail(),
                user.getRole().name()
        );
    }
}
