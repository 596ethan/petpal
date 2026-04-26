package com.petpal.server.appointment;

import com.petpal.server.appointment.dto.AppointmentCreateRequest;
import com.petpal.server.common.error.AppException;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;

class AppointmentServiceTest {

  @SuppressWarnings("unchecked")
  @Test
  void createTranslatesActiveDuplicateConstraintViolationIntoAppointmentConflict() {
    JdbcClient jdbcClient = Mockito.mock(JdbcClient.class);
    JdbcClient.StatementSpec petSpec = Mockito.mock(JdbcClient.StatementSpec.class);
    JdbcClient.StatementSpec serviceSpec = Mockito.mock(JdbcClient.StatementSpec.class);
    JdbcClient.StatementSpec duplicateSpec = Mockito.mock(JdbcClient.StatementSpec.class);
    JdbcClient.StatementSpec insertSpec = Mockito.mock(JdbcClient.StatementSpec.class);
    JdbcClient.MappedQuerySpec<Long> petQuery = Mockito.mock(JdbcClient.MappedQuerySpec.class);
    JdbcClient.MappedQuerySpec<Long> serviceQuery = Mockito.mock(JdbcClient.MappedQuerySpec.class);
    JdbcClient.MappedQuerySpec<Long> duplicateQuery = Mockito.mock(JdbcClient.MappedQuerySpec.class);

    Mockito.when(jdbcClient.sql(Mockito.anyString())).thenAnswer(invocation -> {
      String sql = invocation.getArgument(0, String.class);
      if (sql.startsWith("SELECT COUNT(*) FROM pet ")) {
        return petSpec;
      }
      if (sql.startsWith("SELECT COUNT(*) FROM service_item ")) {
        return serviceSpec;
      }
      if (sql.contains("SELECT COUNT(*) FROM appointment")) {
        return duplicateSpec;
      }
      if (sql.contains("INSERT INTO appointment")) {
        return insertSpec;
      }
      throw new AssertionError("Unexpected SQL: " + sql);
    });

    Mockito.when(petSpec.param(Mockito.anyString(), Mockito.any())).thenReturn(petSpec);
    Mockito.when(serviceSpec.param(Mockito.anyString(), Mockito.any())).thenReturn(serviceSpec);
    Mockito.when(duplicateSpec.param(Mockito.anyString(), Mockito.any())).thenReturn(duplicateSpec);
    Mockito.when(insertSpec.param(Mockito.anyString(), Mockito.any())).thenReturn(insertSpec);

    Mockito.when(petSpec.query(Long.class)).thenReturn(petQuery);
    Mockito.when(serviceSpec.query(Long.class)).thenReturn(serviceQuery);
    Mockito.when(duplicateSpec.query(Long.class)).thenReturn(duplicateQuery);

    Mockito.when(petQuery.single()).thenReturn(1L);
    Mockito.when(serviceQuery.single()).thenReturn(1L);
    Mockito.when(duplicateQuery.single()).thenReturn(0L);
    Mockito.when(insertSpec.update())
      .thenThrow(new DuplicateKeyException("Unique index or primary key violation: \"uk_appointment_active_duplicate\""));

    AppointmentService appointmentService = new AppointmentService(jdbcClient);
    AppointmentCreateRequest request = new AppointmentCreateRequest(
      1L,
      1L,
      1L,
      "2099-01-07T10:00:00",
      "race conflict"
    );

    AppException error = org.assertj.core.api.Assertions.catchThrowableOfType(
      () -> appointmentService.create(1L, request),
      AppException.class
    );

    org.assertj.core.api.Assertions.assertThat(error).isNotNull();
    org.assertj.core.api.Assertions.assertThat(error.status()).isEqualTo(409);
    org.assertj.core.api.Assertions.assertThat(error.code()).isEqualTo("APPOINTMENT_CONFLICT");
    org.assertj.core.api.Assertions.assertThat(error.getMessage()).isEqualTo("该宠物在此时间已有预约，请选择其他时间");
  }
}
