package com.petpal.server.appointment.dto;

import jakarta.validation.constraints.NotNull;

public record AppointmentCreateRequest(
  @NotNull Long petId,
  @NotNull Long providerId,
  @NotNull Long serviceId,
  @NotNull String appointmentTime,
  String remark
) {
}
