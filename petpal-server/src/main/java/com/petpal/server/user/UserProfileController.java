package com.petpal.server.user;

import com.petpal.server.auth.AuthContext;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.user.dto.UserProfileDto;
import java.util.Map;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/user")
public class UserProfileController {
  private final UserAccountRepository userAccountRepository;
  private final AuthContext authContext;

  public UserProfileController(UserAccountRepository userAccountRepository, AuthContext authContext) {
    this.userAccountRepository = userAccountRepository;
    this.authContext = authContext;
  }

  @PutMapping("/profile")
  public ApiResponse<UserProfileDto> updateProfile(@RequestBody Map<String, String> payload) {
    return ApiResponse.ok(userAccountRepository.updateProfile(
      authContext.requireUserId(),
      payload.get("nickname"),
      payload.get("avatarUrl"),
      payload.get("bio")
    ));
  }

  @PostMapping("/follow/{userId}")
  public ApiResponse<Void> follow(@PathVariable Long userId) {
    return ApiResponse.ok();
  }

  @DeleteMapping("/follow/{userId}")
  public ApiResponse<Void> unfollow(@PathVariable Long userId) {
    return ApiResponse.ok();
  }
}
