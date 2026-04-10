package com.petpal.server.appointment.dto;

import com.petpal.server.common.enums.AppointmentStatus;
import jakarta.validation.constraints.NotNull;

public record AppointmentStatusUpdateRequest(@NotNull AppointmentStatus status) {
}
