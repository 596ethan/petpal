package com.petpal.server.appointment;

import com.petpal.server.appointment.dto.AppointmentCreateRequest;
import com.petpal.server.appointment.dto.AppointmentDto;
import com.petpal.server.common.enums.AppointmentStatus;
import com.petpal.server.common.error.AppException;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class AppointmentService {
  private static final DateTimeFormatter RESPONSE_TIME = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
  private final JdbcClient jdbcClient;

  public AppointmentService(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public AppointmentDto create(long userId, AppointmentCreateRequest request) {
    ensurePetOwnedByUser(userId, request.petId());
    ensureServiceMatchesProvider(request.providerId(), request.serviceId());
    String orderNo = "PP" + System.currentTimeMillis() + ThreadLocalRandom.current().nextInt(100, 1000);
    LocalDateTime appointmentTime = LocalDateTime.parse(request.appointmentTime());
    jdbcClient.sql("""
      INSERT INTO appointment (order_no, user_id, pet_id, provider_id, service_id, status, appointment_time, remark)
      VALUES (:orderNo, :userId, :petId, :providerId, :serviceId, :status, :appointmentTime, :remark)
      """)
      .param("orderNo", orderNo)
      .param("userId", userId)
      .param("petId", request.petId())
      .param("providerId", request.providerId())
      .param("serviceId", request.serviceId())
      .param("status", AppointmentStatus.PENDING_CONFIRM.name())
      .param("appointmentTime", Timestamp.valueOf(appointmentTime))
      .param("remark", request.remark())
      .update();
    Long id = jdbcClient.sql("SELECT id FROM appointment WHERE order_no = :orderNo")
      .param("orderNo", orderNo)
      .query(Long.class)
      .single();
    return getAppointmentById(id);
  }

  public List<AppointmentDto> listByUser(long userId) {
    return jdbcClient.sql(baseAppointmentSelect() + " WHERE a.user_id = :userId ORDER BY a.id DESC")
      .param("userId", userId)
      .query((rs, rowNum) -> new AppointmentDto(
        rs.getLong("id"),
        rs.getString("order_no"),
        rs.getLong("user_id"),
        rs.getLong("pet_id"),
        rs.getString("pet_name"),
        rs.getLong("provider_id"),
        rs.getString("provider_name"),
        rs.getLong("service_id"),
        rs.getString("service_name"),
        AppointmentStatus.valueOf(rs.getString("status")),
        rs.getTimestamp("appointment_time").toLocalDateTime().format(RESPONSE_TIME),
        rs.getString("remark")
      ))
      .list();
  }

  public List<AppointmentDto> listAll() {
    return jdbcClient.sql(baseAppointmentSelect() + " ORDER BY a.id DESC")
      .query((rs, rowNum) -> new AppointmentDto(
        rs.getLong("id"),
        rs.getString("order_no"),
        rs.getLong("user_id"),
        rs.getLong("pet_id"),
        rs.getString("pet_name"),
        rs.getLong("provider_id"),
        rs.getString("provider_name"),
        rs.getLong("service_id"),
        rs.getString("service_name"),
        AppointmentStatus.valueOf(rs.getString("status")),
        rs.getTimestamp("appointment_time").toLocalDateTime().format(RESPONSE_TIME),
        rs.getString("remark")
      ))
      .list();
  }

  public void cancel(long userId, Long appointmentId) {
    AppointmentRecord record = loadAppointmentRecord(appointmentId);
    if (record.userId() != userId) {
      throw new AppException(403, "FORBIDDEN", "Cannot cancel another user's appointment");
    }
    if (record.status() == AppointmentStatus.COMPLETED || record.status() == AppointmentStatus.CANCELLED) {
      throw new AppException(409, "APPOINTMENT_NOT_CANCELLABLE", "Appointment cannot be cancelled");
    }
    if (record.status() == AppointmentStatus.CONFIRMED) {
      Duration leadTime = Duration.between(LocalDateTime.now(), record.appointmentTime());
      if (leadTime.toMinutes() < 120) {
        throw new AppException(409, "APPOINTMENT_NOT_CANCELLABLE", "Confirmed appointments within 2 hours cannot be cancelled");
      }
    }
    jdbcClient.sql("UPDATE appointment SET status = :status WHERE id = :id")
      .param("status", AppointmentStatus.CANCELLED.name())
      .param("id", appointmentId)
      .update();
  }

  public AppointmentDto updateStatus(Long appointmentId, AppointmentStatus nextStatus) {
    AppointmentRecord record = loadAppointmentRecord(appointmentId);
    if (!isLegalTransition(record.status(), nextStatus)) {
      throw new AppException(409, "INVALID_APPOINTMENT_STATUS", "Illegal appointment status transition");
    }
    jdbcClient.sql("UPDATE appointment SET status = :status WHERE id = :id")
      .param("status", nextStatus.name())
      .param("id", appointmentId)
      .update();
    return getAppointmentById(appointmentId);
  }

  private AppointmentDto getAppointmentById(Long appointmentId) {
    return listAll().stream()
      .filter(item -> item.id().equals(appointmentId))
      .findFirst()
      .orElseThrow(() -> new AppException(404, "APPOINTMENT_NOT_FOUND", "Appointment not found"));
  }

  private void ensurePetOwnedByUser(long userId, Long petId) {
    Long count = jdbcClient.sql("SELECT COUNT(*) FROM pet WHERE id = :petId AND owner_id = :userId AND deleted = 0")
      .param("petId", petId)
      .param("userId", userId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(400, "PET_NOT_AVAILABLE", "Pet does not belong to current user");
    }
  }

  private void ensureServiceMatchesProvider(Long providerId, Long serviceId) {
    Long count = jdbcClient.sql("SELECT COUNT(*) FROM service_item WHERE id = :serviceId AND provider_id = :providerId AND deleted = 0")
      .param("serviceId", serviceId)
      .param("providerId", providerId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(400, "SERVICE_NOT_AVAILABLE", "Service does not belong to provider");
    }
  }

  private AppointmentRecord loadAppointmentRecord(Long appointmentId) {
    return jdbcClient.sql("SELECT id, user_id, status, appointment_time FROM appointment WHERE id = :id")
      .param("id", appointmentId)
      .query((rs, rowNum) -> new AppointmentRecord(
        rs.getLong("id"),
        rs.getLong("user_id"),
        AppointmentStatus.valueOf(rs.getString("status")),
        rs.getTimestamp("appointment_time").toLocalDateTime()
      ))
      .optional()
      .orElseThrow(() -> new AppException(404, "APPOINTMENT_NOT_FOUND", "Appointment not found"));
  }

  private boolean isLegalTransition(AppointmentStatus currentStatus, AppointmentStatus nextStatus) {
    return switch (currentStatus) {
      case PENDING_CONFIRM -> nextStatus == AppointmentStatus.CONFIRMED || nextStatus == AppointmentStatus.CANCELLED;
      case CONFIRMED -> nextStatus == AppointmentStatus.COMPLETED || nextStatus == AppointmentStatus.CANCELLED;
      default -> false;
    };
  }

  private String baseAppointmentSelect() {
    return """
      SELECT a.id, a.order_no, a.user_id, a.pet_id, p.name AS pet_name,
             a.provider_id, sp.name AS provider_name, a.service_id, si.name AS service_name,
             a.status, a.appointment_time, a.remark
      FROM appointment a
      JOIN pet p ON p.id = a.pet_id
      JOIN service_provider sp ON sp.id = a.provider_id
      JOIN service_item si ON si.id = a.service_id
      """;
  }

  private record AppointmentRecord(Long id, Long userId, AppointmentStatus status, LocalDateTime appointmentTime) {
  }
}
