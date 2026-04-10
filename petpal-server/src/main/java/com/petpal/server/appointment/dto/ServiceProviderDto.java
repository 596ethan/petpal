package com.petpal.server.appointment.dto;

import com.petpal.server.common.enums.ProviderType;

public record ServiceProviderDto(
  Long id,
  String name,
  ProviderType type,
  String address,
  String phone,
  double rating,
  String coverUrl,
  String businessHours,
  String status
) {
}
