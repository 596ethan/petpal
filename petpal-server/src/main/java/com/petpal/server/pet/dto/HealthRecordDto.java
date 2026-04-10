package com.petpal.server.pet.dto;

import com.petpal.server.common.enums.HealthRecordType;

public record HealthRecordDto(
  Long id,
  HealthRecordType recordType,
  String title,
  String description,
  String recordDate,
  String nextDate
) {
}
