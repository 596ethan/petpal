package com.petpal.server.pet.dto;

public record VaccineRecordDto(Long id, String vaccineName, String vaccinatedAt, String nextDueAt, String hospital) {
}
