package com.petpal.server.user;

import com.petpal.server.auth.AuthContext;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.user.dto.LoginRequest;
import com.petpal.server.user.dto.RegisterRequest;
import com.petpal.server.user.dto.UserProfileDto;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
public class AuthController {
  private final AuthService authService;
  private final AuthContext authContext;

  public AuthController(AuthService authService, AuthContext authContext) {
    this.authService = authService;
    this.authContext = authContext;
  }

  @PostMapping("/register")
  public ApiResponse<Map<String, Object>> register(@Valid @RequestBody RegisterRequest request) {
    return ApiResponse.ok(authService.register(request));
  }

  @PostMapping("/login")
  public ApiResponse<Map<String, Object>> login(@Valid @RequestBody LoginRequest request) {
    return ApiResponse.ok(authService.login(request));
  }

  @GetMapping("/profile")
  public ApiResponse<UserProfileDto> profile() {
    return ApiResponse.ok(authService.profile(authContext.requireUserId()));
  }
}
