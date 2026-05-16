package organizaAI.OrganizaAI.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain)
            throws ServletException, IOException {

        // 1. Pega o header Authorization da requisição
        String authHeader = request.getHeader("Authorization");

        // 2. Se não tem header ou não começa com "Bearer ", deixa passar sem autenticar
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 3. Extrai o token removendo o prefixo "Bearer "
        String token = authHeader.substring(7);

        // 4. Extrai o email do token
        String email = jwtUtil.extrairEmail(token);

        // 5. Se tem email e o usuário ainda não está autenticado nessa requisição
        if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {

            // 6. Busca o usuário no banco pelo email
            UserDetails userDetails = userDetailsService.loadUserByUsername(email);

            // 7. Valida o token
            if (jwtUtil.tokenValido(token)) {

                // 8. Cria o objeto de autenticação
                UsernamePasswordAuthenticationToken authToken =
                        new UsernamePasswordAuthenticationToken(
                                userDetails,
                                null,
                                userDetails.getAuthorities()
                        );

                authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                // 9. Registra a autenticação no contexto do Spring Security
                SecurityContextHolder.getContext().setAuthentication(authToken);
            }
        }

        // 10. Continua para o próximo filtro/controller
        filterChain.doFilter(request, response);
    }
}
