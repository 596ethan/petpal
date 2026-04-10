package com.petpal.server.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class JwtService {
  private final SecretKey secretKey;
  private final String issuer;
  private final long accessExpireSeconds;
  private final long refreshExpireSeconds;

  public JwtService(
    SecretKey secretKey,
    @Value("${petpal.jwt.issuer}") String issuer,
    @Value("${petpal.jwt.access-expire-seconds}") long accessExpireSeconds,
    @Value("${petpal.jwt.refresh-expire-seconds}") long refreshExpireSeconds
  ) {
    this.secretKey = secretKey;
    this.issuer = issuer;
    this.accessExpireSeconds = accessExpireSeconds;
    this.refreshExpireSeconds = refreshExpireSeconds;
  }

  public String createAccessToken(Long userId, String phone) {
    return createToken(userId, phone, accessExpireSeconds, "access");
  }

  public String createRefreshToken(Long userId, String phone) {
    return createToken(userId, phone, refreshExpireSeconds, "refresh");
  }

  public Long parseUserId(String token) {
    Claims claims = Jwts.parser()
      .verifyWith(secretKey)
      .build()
      .parseSignedClaims(token)
      .getPayload();
    return Long.parseLong(claims.getSubject());
  }

  private String createToken(Long userId, String phone, long expireSeconds, String type) {
    Instant now = Instant.now();
    return Jwts.builder()
      .subject(String.valueOf(userId))
      .issuer(issuer)
      .claim("phone", phone)
      .claim("type", type)
      .issuedAt(Date.from(now))
      .expiration(Date.from(now.plusSeconds(expireSeconds)))
      .signWith(secretKey)
      .compact();
  }
}
