package com.petpal.server;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThan;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class PetPalServerMvcTest {

  @Autowired
  private MockMvc mockMvc;

  @Test
  void loginReturnsProfileAndJwtTokens() throws Exception {
    mockMvc.perform(post("/api/user/login")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "phone": "13800000001",
            "password": "123456"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.profile.phone").value("13800000001"))
      .andExpect(jsonPath("$.data.profile.nickname").value("Xiaoman"))
      .andExpect(jsonPath("$.data.tokens.accessToken").isString())
      .andExpect(jsonPath("$.data.tokens.refreshToken").isString());
  }

  @Test
  void loginRejectsWrongPassword() throws Exception {
    mockMvc.perform(post("/api/user/login")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "phone": "13800000001",
            "password": "bad-password"
          }
          """))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
  }

  @Test
  void appointmentListRejectsUnauthenticatedAccess() throws Exception {
    mockMvc.perform(get("/api/appointment/list"))
      .andExpect(status().isForbidden());
  }

  @Test
  void providerListReturnsPersistedData() throws Exception {
    mockMvc.perform(get("/api/provider/list"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.length()").value(greaterThan(0)))
      .andExpect(jsonPath("$.data[0].name").value("Cloud Vet Center"))
      .andExpect(jsonPath("$.data[0].type").value("HOSPITAL"));
  }

  @Test
  void appointmentListReturnsOnlyCurrentUserAppointments() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    mockMvc.perform(get("/api/appointment/list")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(1))
      .andExpect(jsonPath("$.data[0].orderNo").value("PP202603260001"));
  }

  @Test
  void createAppointmentGeneratesPendingOrder() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "2026-12-30T10:00:00",
            "remark": "Check appetite"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.orderNo").exists())
      .andExpect(jsonPath("$.data.status").value("PENDING_CONFIRM"))
      .andExpect(jsonPath("$.data.petName").value("Nuomi"))
      .andExpect(jsonPath("$.data.providerName").value("Cloud Vet Center"));
  }

  @Test
  void cancelConfirmedAppointmentWithinTwoHoursFails() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    String nearFuture = LocalDateTime.now().plusMinutes(90).withNano(0).toString();

    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "%s",
            "remark": "late slot"
          }
          """.formatted(nearFuture)))
      .andExpect(status().isOk());

    mockMvc.perform(put("/admin/appointments/2/status")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "CONFIRMED"
          }
          """))
      .andExpect(status().isOk());

    mockMvc.perform(put("/api/appointment/2/cancel")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isConflict())
      .andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_CANCELLABLE"));
  }

  @Test
  void adminRejectsIllegalStatusTransition() throws Exception {
    mockMvc.perform(put("/admin/appointments/1/status")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "PENDING_CONFIRM"
          }
          """))
      .andExpect(status().isConflict())
      .andExpect(jsonPath("$.code").value("INVALID_APPOINTMENT_STATUS"));
  }

  @Test
  void adminCanConfirmThenCompleteAppointment() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "2099-01-02T10:00:00",
            "remark": "new order"
          }
          """))
      .andExpect(status().isOk());

    mockMvc.perform(put("/admin/appointments/2/status")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "CONFIRMED"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.status", equalTo("CONFIRMED")));

    mockMvc.perform(put("/admin/appointments/2/status")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "COMPLETED"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.status", equalTo("COMPLETED")));
  }

  private String loginAndGetAccessToken(String phone, String password) throws Exception {
    MvcResult result = mockMvc.perform(post("/api/user/login")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "phone": "%s",
            "password": "%s"
          }
          """.formatted(phone, password)))
      .andExpect(status().isOk())
      .andReturn();

    String body = result.getResponse().getContentAsString();
    String marker = "\"accessToken\":\"";
    int start = body.indexOf(marker) + marker.length();
    int end = body.indexOf('"', start);
    return body.substring(start, end);
  }
}
