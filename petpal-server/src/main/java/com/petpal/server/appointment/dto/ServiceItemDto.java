package com.petpal.server.appointment.dto;

public record ServiceItemDto(Long id, Long providerId, String name, double price, int durationMinutes) {
}
