package com.petpal.server.user.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterRequest(@NotBlank String phone, @NotBlank String password, @NotBlank String nickname) {
}
