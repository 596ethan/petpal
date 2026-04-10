package com.petpal.server.auth;

import com.petpal.server.common.error.AppException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AuthContext {
  public Long requireUserId() {
    Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
    if (authentication == null || authentication.getName() == null || authentication.getName().isBlank()) {
      throw new AppException(401, "UNAUTHORIZED", "Authentication required");
    }
    return Long.parseLong(authentication.getName());
  }
}
