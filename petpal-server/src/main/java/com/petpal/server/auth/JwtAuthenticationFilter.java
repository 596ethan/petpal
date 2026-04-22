package com.petpal.server.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class JwtAuthenticationFilter extends OncePerRequestFilter {
  private final JwtService jwtService;

  public JwtAuthenticationFilter(JwtService jwtService) {
    this.jwtService = jwtService;
  }

  @Override
  protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    String header = request.getHeader("Authorization");
    if (header != null && header.startsWith("Bearer ")) {
      String token = header.substring(7);
      try {
        // 管理端等前置过滤器可能已写入认证信息；这里不覆盖已有上下文。
        if (SecurityContextHolder.getContext().getAuthentication() != null) {
          filterChain.doFilter(request, response);
          return;
        }
        Long userId = jwtService.parseAccessUserId(token);
        UsernamePasswordAuthenticationToken authentication =
          UsernamePasswordAuthenticationToken.authenticated(String.valueOf(userId), token, List.of());
        SecurityContextHolder.getContext().setAuthentication(authentication);
      } catch (Exception ignored) {
        // token 无效时直接返回统一 401，防止后续接口以匿名身份继续执行。
        SecurityContextHolder.clearContext();
        writeUnauthorized(response);
        return;
      }
    }
    filterChain.doFilter(request, response);
  }

  private void writeUnauthorized(HttpServletResponse response) throws IOException {
    response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
    response.setCharacterEncoding(StandardCharsets.UTF_8.name());
    response.setContentType("application/json");
    response.getWriter().write("{\"code\":\"UNAUTHORIZED\",\"message\":\"Authentication required\",\"data\":null,\"requestId\":null}");
  }
}
