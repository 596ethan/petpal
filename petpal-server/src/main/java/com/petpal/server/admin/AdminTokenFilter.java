package com.petpal.server.admin;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class AdminTokenFilter extends OncePerRequestFilter {
  private static final String HEADER_NAME = "X-PetPal-Admin-Token";

  private final String adminToken;

  public AdminTokenFilter(@Value("${petpal.admin.token}") String adminToken) {
    this.adminToken = adminToken;
  }

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    return !request.getRequestURI().startsWith("/admin");
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String token = request.getHeader(HEADER_NAME);
    if (token == null || !adminToken.equals(token)) {
      response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
      response.setCharacterEncoding(StandardCharsets.UTF_8.name());
      response.setContentType("application/json");
      response.getWriter().write("{\"code\":\"ADMIN_UNAUTHORIZED\",\"message\":\"admin token required\",\"data\":null,\"requestId\":null}");
      return;
    }

    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
      "admin",
      null,
      AuthorityUtils.createAuthorityList("ROLE_ADMIN")
    );
    SecurityContextHolder.getContext().setAuthentication(authentication);
    try {
      filterChain.doFilter(request, response);
    } finally {
      SecurityContextHolder.clearContext();
    }
  }
}