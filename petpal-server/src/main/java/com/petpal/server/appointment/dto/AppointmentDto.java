package com.petpal.server.appointment.dto;

import com.petpal.server.common.enums.AppointmentStatus;

public record AppointmentDto(
  Long id,
  String orderNo,
  Long userId,
  Long petId,
  String petName,
  Long providerId,
  String providerName,
  Long serviceId,
  String serviceName,
  AppointmentStatus status,
  String appointmentTime,
  String remark
) {
}
