package organizaAI.OrganizaAI.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;

@Component
public class JwtUtil {

    // Chave secreta para assinar o token — em produção coloque no application.properties
    private static final String SECRET = "organizaAI-chave-secreta-muito-segura-2026";

    // Tempo de expiração: 24 horas em milissegundos
    private static final long EXPIRATION = 1000 * 60 * 60 * 24;

    // Gera a chave criptográfica a partir do SECRET
    private SecretKey getKey() {
        return Keys.hmacShaKeyFor(SECRET.getBytes());
    }

    // Gera um token JWT para o usuário
    public String gerarToken(String email) {
        return Jwts.builder()
                .subject(email)
                .issuedAt(new Date())
                .expiration(new Date(System.currentTimeMillis() + EXPIRATION))
                .signWith(getKey())
                .compact();
    }

    // Extrai o email do token
    public String extrairEmail(String token) {
        return getClaims(token).getSubject();
    }

    // Verifica se o token é válido e não expirou
    public boolean tokenValido(String token) {
        try {
            return !getClaims(token).getExpiration().before(new Date());
        } catch (Exception e) {
            return false;
        }
    }

    // Extrai as informações (claims) do token
    private Claims getClaims(String token) {
        return Jwts.parser()
                .verifyWith(getKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }
}
