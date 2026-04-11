package com.petpal.server.admin.dto;

import jakarta.validation.constraints.NotBlank;

public record ProviderUpsertRequest(
  @NotBlank String name,
  @NotBlank String type,
  @NotBlank String address,
  String phone,
  Double rating,
  String coverUrl,
  String businessHours,
  String status
) {
}
