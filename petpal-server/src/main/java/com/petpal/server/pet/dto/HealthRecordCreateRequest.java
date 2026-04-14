package com.petpal.server.pet.dto;

import com.petpal.server.common.enums.HealthRecordType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record HealthRecordCreateRequest(
  @NotNull HealthRecordType recordType,
  @NotBlank @Size(max = 100) String title,
  @Size(max = 255) String description,
  @NotBlank String recordDate,
  String nextDate
) {
}
