package com.petpal.server.pet.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record VaccineRecordCreateRequest(
  @NotBlank @Size(max = 100) String vaccineName,
  @NotBlank String vaccinatedAt,
  String nextDueAt,
  @Size(max = 100) String hospital
) {
}
