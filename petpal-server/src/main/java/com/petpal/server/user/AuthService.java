package com.petpal.server.user;

import com.petpal.server.auth.JwtService;
import com.petpal.server.common.error.AppException;
import com.petpal.server.user.dto.AuthTokens;
import com.petpal.server.user.dto.LoginRequest;
import com.petpal.server.user.dto.RegisterRequest;
import com.petpal.server.user.dto.UserProfileDto;
import java.util.Map;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {
  private final UserAccountRepository userAccountRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtService jwtService;

  public AuthService(UserAccountRepository userAccountRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
    this.userAccountRepository = userAccountRepository;
    this.passwordEncoder = passwordEncoder;
    this.jwtService = jwtService;
  }

  public Map<String, Object> register(RegisterRequest request) {
    // 手机端 MVP 用手机号作为唯一登录标识；注册时先拦截重复号码，避免生成孤立 profile。
    userAccountRepository.findByPhone(request.phone()).ifPresent(existing -> {
      throw new AppException(409, "PHONE_EXISTS", "Phone already registered");
    });
    long userId = userAccountRepository.create(request.phone(), passwordEncoder.encode(request.password()), request.nickname());
    UserProfileDto profile = userAccountRepository.loadProfile(userId);
    return Map.of("profile", profile, "tokens", createTokens(profile.id(), profile.phone()));
  }

  public Map<String, Object> login(LoginRequest request) {
    // 账号不存在和密码错误统一返回同一错误，避免向客户端暴露手机号是否已注册。
    UserAccountRecord account = userAccountRepository.findByPhone(request.phone())
      .orElseThrow(() -> new AppException(401, "INVALID_CREDENTIALS", "Invalid phone or password"));
    if (!passwordMatches(request.password(), account.password())) {
      throw new AppException(401, "INVALID_CREDENTIALS", "Invalid phone or password");
    }
    UserProfileDto profile = userAccountRepository.loadProfile(account.id());
    return Map.of("profile", profile, "tokens", createTokens(profile.id(), profile.phone()));
  }

  public UserProfileDto profile(long userId) {
    return userAccountRepository.loadProfile(userId);
  }

  private AuthTokens createTokens(Long userId, String phone) {
    // access token 用于接口鉴权，refresh token 预留给后续刷新登录态。
    return new AuthTokens(jwtService.createAccessToken(userId, phone), jwtService.createRefreshToken(userId, phone));
  }

  private boolean passwordMatches(String rawPassword, String storedPassword) {
    if (storedPassword == null || storedPassword.isBlank()) {
      return false;
    }
    return passwordEncoder.matches(rawPassword, storedPassword);
  }
}
