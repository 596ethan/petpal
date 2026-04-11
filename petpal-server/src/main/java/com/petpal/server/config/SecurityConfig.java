package com.petpal.server.config;

import com.petpal.server.admin.AdminTokenFilter;
import com.petpal.server.auth.JwtAuthenticationFilter;
import org.springframework.boot.web.servlet.FilterRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.AnonymousAuthenticationFilter;

@Configuration
public class SecurityConfig {
  private final AdminTokenFilter adminTokenFilter;
  private final JwtAuthenticationFilter jwtAuthenticationFilter;

  public SecurityConfig(AdminTokenFilter adminTokenFilter, JwtAuthenticationFilter jwtAuthenticationFilter) {
    this.adminTokenFilter = adminTokenFilter;
    this.jwtAuthenticationFilter = jwtAuthenticationFilter;
  }

  @Bean
  public FilterRegistrationBean<AdminTokenFilter> adminTokenFilterRegistration() {
    FilterRegistrationBean<AdminTokenFilter> registration = new FilterRegistrationBean<>(adminTokenFilter);
    registration.setEnabled(false);
    return registration;
  }

  @Bean
  public FilterRegistrationBean<JwtAuthenticationFilter> jwtAuthenticationFilterRegistration() {
    FilterRegistrationBean<JwtAuthenticationFilter> registration = new FilterRegistrationBean<>(jwtAuthenticationFilter);
    registration.setEnabled(false);
    return registration;
  }

  @Bean
  public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
    return http
      .csrf(csrf -> csrf.disable())
      .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(auth -> auth
        .requestMatchers("/api/user/register", "/api/user/login", "/actuator/health", "/error").permitAll()
        .requestMatchers("/api/provider/**").permitAll()
        .requestMatchers("/admin/**").authenticated()
        .requestMatchers("/api/post/feed", "/api/post/*", "/api/post/*/comment").permitAll()
        .anyRequest().authenticated())
      .addFilterBefore(adminTokenFilter, AnonymousAuthenticationFilter.class)
      .addFilterBefore(jwtAuthenticationFilter, AnonymousAuthenticationFilter.class)
      .build();
  }
}