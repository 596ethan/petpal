package com.petpal.server.config;

import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class JwtConfig {
  @Bean
  public SecretKey petpalJwtSecretKey(@Value("${petpal.jwt.secret}") String secret) {
    String normalized = java.util.Base64.getEncoder().encodeToString(secret.getBytes(java.nio.charset.StandardCharsets.UTF_8));
    return Keys.hmacShaKeyFor(Decoders.BASE64.decode(normalized));
  }
}
