package com.petpal.server.auth;

import com.petpal.server.common.error.AppException;
import java.util.Optional;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AuthContext {
  public Long requireUserId() {
    return currentUserId()
      .orElseThrow(() -> new AppException(401, "UNAUTHORIZED", "Authentication required"));
  }

  public Optional<Long> currentUserId() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
      return Optional.empty();
    }
    try {
      return Optional.of(Long.parseLong(authentication.getName()));
    } catch (NumberFormatException ex) {
      return Optional.empty();
    }
  }
}
