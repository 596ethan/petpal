package com.petpal.server;

import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.greaterThan;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.common.error.AppException;
import com.petpal.server.common.error.GlobalExceptionHandler;
import com.petpal.server.file.FileStorageService;
import com.petpal.server.file.dto.FileDownloadDto;
import com.petpal.server.file.dto.FileUploadDto;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartFile;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class PetPalServerMvcTest {

  @Autowired
  private MockMvc mockMvc;

  @Autowired
  private ObjectMapper objectMapper;

  @Autowired
  private JdbcClient jdbcClient;

  @MockBean
  private FileStorageService fileStorageService;

  @Value("${petpal.admin.token}")
  private String adminToken;

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
      .andExpect(jsonPath("$.data.profile.nickname").value("小满"))
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
  void loginRejectsPlaintextStoredPassword() throws Exception {
    jdbcClient.sql("UPDATE user SET password = '123456' WHERE phone = '13800000001'")
      .update();

    mockMvc.perform(post("/api/user/login")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "phone": "13800000001",
            "password": "123456"
          }
          """))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.code").value("INVALID_CREDENTIALS"));
  }

  @Test
  void refreshTokenCannotAccessProtectedPhoneEndpoint() throws Exception {
    String refreshToken = loginAndGetRefreshToken("13800000001", "123456");

    mockMvc.perform(get("/api/appointment/list")
        .header("Authorization", "Bearer " + refreshToken))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.code").value("UNAUTHORIZED"));
  }

  @Test
  void appointmentListRejectsUnauthenticatedAccess() throws Exception {
    mockMvc.perform(get("/api/appointment/list"))
      .andExpect(status().isForbidden());
  }

  @Test
  void adminEndpointsRejectMissingToken() throws Exception {
    mockMvc.perform(get("/admin/providers"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.code").value("ADMIN_UNAUTHORIZED"));
  }

  @Test
  void adminEndpointsRejectWrongBearerToken() throws Exception {
    mockMvc.perform(get("/admin/providers")
        .header("Authorization", "Bearer wrong-admin-token"))
      .andExpect(status().isUnauthorized())
      .andExpect(jsonPath("$.code").value("ADMIN_UNAUTHORIZED"));
  }

  @Test
  void adminEndpointsAcceptBearerToken() throws Exception {
    mockMvc.perform(get("/admin/providers")
        .header("Authorization", "Bearer " + adminToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.length()").value(greaterThan(0)));
  }
  @Test
  void adminEndpointsAllowBrowserPreflight() throws Exception {
    mockMvc.perform(options("/admin/providers")
        .header("Origin", "null")
        .header("Access-Control-Request-Method", "GET")
        .header("Access-Control-Request-Headers", "x-petpal-admin-token"))
      .andExpect(status().isOk());
  }

  @Test
  void providerListReturnsPersistedData() throws Exception {
    mockMvc.perform(get("/api/provider/list"))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.length()").value(greaterThan(0)))
      .andExpect(jsonPath("$.data[0].name").value("云朵宠物医院"))
      .andExpect(jsonPath("$.data[0].type").value("HOSPITAL"));
  }

  @Test
  void createPetPersistsAndAppearsInCurrentUserList() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Momo",
            "species": "RABBIT",
            "breed": "Mini Rex",
            "gender": "UNKNOWN",
            "birthday": "2024-02-03",
            "weight": 2.40,
            "avatarUrl": "https://placehold.co/120x120?text=momo",
            "neutered": false
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.id").exists())
      .andExpect(jsonPath("$.data.name").value("Momo"))
      .andExpect(jsonPath("$.data.species").value("RABBIT"));

    mockMvc.perform(get("/api/pet/list")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(3))
      .andExpect(jsonPath("$.data[2].name").value("Momo"));
  }

  @Test
  void createPetUsesDefaultAvatarWhenAvatarUrlIsMissing() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Default Avatar Dog",
            "species": "DOG",
            "gender": "MALE"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.avatarUrl").value("https://placehold.co/320x320/png?text=Dog"));
  }

  @Test
  void createPetKeepsCustomAvatarUrl() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Custom Avatar Cat",
            "species": "CAT",
            "gender": "FEMALE",
            "avatarUrl": "https://example.com/custom-cat.png"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.avatarUrl").value("https://example.com/custom-cat.png"));
  }

  @Test
  void updatePetPartiallyPreservesOmittedFields() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(put("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "糯米更新",
            "weight": 4.80
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.name").value("糯米更新"))
      .andExpect(jsonPath("$.data.species").value("CAT"))
      .andExpect(jsonPath("$.data.breed").value("英短"))
      .andExpect(jsonPath("$.data.gender").value("FEMALE"))
      .andExpect(jsonPath("$.data.weight").value(4.8));

    mockMvc.perform(get("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.name").value("糯米更新"))
      .andExpect(jsonPath("$.data.species").value("CAT"))
      .andExpect(jsonPath("$.data.breed").value("英短"));
  }

  @Test
  void updatePetRejectsBlankRequiredField() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(put("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "   "
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("INVALID_PET_FIELD"));
  }

  @Test
  void petMutationRejectsInvalidDateAndWeight() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Bad Date",
            "species": "CAT",
            "gender": "FEMALE",
            "birthday": "2026-99-99"
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("INVALID_PET_FIELD"));

    mockMvc.perform(post("/api/pet")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Bad Weight",
            "species": "DOG",
            "gender": "MALE",
            "weight": -1
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("INVALID_PET_FIELD"));
  }

  @Test
  void deletePetSoftDeletesAndHidesPetFromReads() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(delete("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"));

    mockMvc.perform(get("/api/pet/list")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(1))
      .andExpect(jsonPath("$.data[0].id").value(2));

    mockMvc.perform(get("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));

    mockMvc.perform(delete("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));
  }

  @Test
  void petWritesRejectNonOwnedPetAsNotFound() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000002", "123456");

    mockMvc.perform(get("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));

    mockMvc.perform(put("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Not Mine"
          }
          """))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));

    mockMvc.perform(delete("/api/pet/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));

    mockMvc.perform(post("/api/pet/1/health")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "recordType": "CHECKUP",
            "title": "Wrong owner",
            "recordDate": "2026-04-01"
          }
          """))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));

    mockMvc.perform(post("/api/pet/1/vaccine")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "vaccineName": "Wrong owner vaccine",
            "vaccinatedAt": "2026-04-01"
          }
          """))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("PET_NOT_FOUND"));
  }

  @Test
  void healthRecordCreationPersistsAndSortsByDateThenIdDescending() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet/1/health")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "recordType": "CHECKUP",
            "title": "Morning check",
            "description": "Stable",
            "recordDate": "2026-04-01",
            "nextDate": "2026-05-01"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.title").value("Morning check"));

    mockMvc.perform(post("/api/pet/1/health")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "recordType": "MEDICATION",
            "title": "Evening medication",
            "description": "Completed",
            "recordDate": "2026-04-01",
            "nextDate": "2026-05-01"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.title").value("Evening medication"));

    mockMvc.perform(get("/api/pet/1/health")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data[0].title").value("Evening medication"))
      .andExpect(jsonPath("$.data[1].title").value("Morning check"));
  }

  @Test
  void vaccineCreationPersistsAndSortsByDateThenIdDescending() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/pet/1/vaccine")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "vaccineName": "First same day",
            "vaccinatedAt": "2026-08-01",
            "nextDueAt": "2027-08-01",
            "hospital": "云朵宠物医院"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.vaccineName").value("First same day"));

    mockMvc.perform(post("/api/pet/1/vaccine")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "vaccineName": "Second same day",
            "vaccinatedAt": "2026-08-01",
            "nextDueAt": "2027-08-01",
            "hospital": "云朵宠物医院"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.vaccineName").value("Second same day"));

    mockMvc.perform(get("/api/pet/1/vaccine")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data[0].vaccineName").value("Second same day"))
      .andExpect(jsonPath("$.data[1].vaccineName").value("First same day"));
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
      .andExpect(jsonPath("$.data.petName").value("糯米"))
      .andExpect(jsonPath("$.data.providerName").value("云朵宠物医院"));
  }

  @Test
  void createAppointmentRejectsInvalidTimeFormat() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "2026-04-12 15:30",
            "remark": "bad time"
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("INVALID_APPOINTMENT_TIME"));
  }

  @Test
  void createAppointmentRejectsPastTime() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "2026-01-01T10:00:00",
            "remark": "past time"
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("APPOINTMENT_TIME_IN_PAST"));
  }

  @Test
  void createAppointmentRejectsPetNotOwnedByCurrentUser() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000002", "123456");
    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 1,
            "appointmentTime": "2099-01-02T10:00:00",
            "remark": "wrong pet"
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("PET_NOT_AVAILABLE"));
  }

  @Test
  void createAppointmentRejectsServiceProviderMismatch() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "providerId": 1,
            "serviceId": 3,
            "appointmentTime": "2099-01-02T10:00:00",
            "remark": "wrong service"
          }
          """))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("SERVICE_NOT_AVAILABLE"));
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
        .header("X-PetPal-Admin-Token", adminToken)
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
        .header("X-PetPal-Admin-Token", adminToken)
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
        .header("X-PetPal-Admin-Token", adminToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "CONFIRMED"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.status", equalTo("CONFIRMED")));

    mockMvc.perform(put("/admin/appointments/2/status")
        .header("X-PetPal-Admin-Token", adminToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "status": "COMPLETED"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.status", equalTo("COMPLETED")));
  }

  @Test
  void adminCanCreateAndUpdateProvider() throws Exception {
    MvcResult createResult = mockMvc.perform(post("/admin/providers")
        .header("X-PetPal-Admin-Token", adminToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Test Clinic",
            "type": "HOSPITAL",
            "address": "Test Address 1",
            "phone": "021-10000000",
            "rating": 4.9,
            "businessHours": "08:00-18:00",
            "status": "OPEN"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.name").value("Test Clinic"))
      .andExpect(jsonPath("$.data.type").value("HOSPITAL"))
      .andReturn();

    long providerId = readDataId(createResult.getResponse().getContentAsString());

    mockMvc.perform(put("/admin/providers/{id}", providerId)
        .header("X-PetPal-Admin-Token", adminToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "name": "Updated Clinic",
            "type": "GROOMING",
            "address": "Updated Address 2",
            "phone": "021-20000000",
            "rating": 4.5,
            "businessHours": "10:00-19:00",
            "status": "PAUSED"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.name").value("Updated Clinic"))
      .andExpect(jsonPath("$.data.type").value("GROOMING"))
      .andExpect(jsonPath("$.data.status").value("PAUSED"));

    mockMvc.perform(get("/api/provider/{id}", providerId))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.name").value("Updated Clinic"))
      .andExpect(jsonPath("$.data.address").value("Updated Address 2"))
      .andExpect(jsonPath("$.data.rating").value(4.5));
  }

  @Test
  void communityWritesRejectUnauthenticatedAccess() throws Exception {
    mockMvc.perform(post("/api/post")
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "Community P0 unauthenticated"
          }
          """))
      .andExpect(status().isForbidden());
  }

  @Test
  void createPostPersistsImagesAndFeedReturnsCurrentUserLikeState() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    MvcResult result = mockMvc.perform(post("/api/post")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "petId": 1,
            "content": "Community P0 post with #care",
            "imageUrls": [
              "http://192.168.1.3:18080/api/file/object/community/community-1.jpg",
              "http://192.168.1.3:18080/api/file/object/community/community-2.jpg"
            ]
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.userId").value(1))
      .andExpect(jsonPath("$.data.petId").value(1))
      .andExpect(jsonPath("$.data.content").value("Community P0 post with #care"))
      .andExpect(jsonPath("$.data.imageUrls.length()").value(2))
      .andExpect(jsonPath("$.data.likeCount").value(0))
      .andExpect(jsonPath("$.data.commentCount").value(0))
      .andExpect(jsonPath("$.data.liked").value(false))
      .andReturn();

    long postId = readDataId(result.getResponse().getContentAsString());

    mockMvc.perform(post("/api/post/{postId}/like", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());

    mockMvc.perform(get("/api/post/{postId}", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.imageUrls[0]").value("/api/file/object/community/community-1.jpg"))
      .andExpect(jsonPath("$.data.likeCount").value(1))
      .andExpect(jsonPath("$.data.liked").value(true));

    mockMvc.perform(get("/api/post/feed")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data[0].id").value((int) postId))
      .andExpect(jsonPath("$.data[0].imageUrls[0]").value("/api/file/object/community/community-1.jpg"))
      .andExpect(jsonPath("$.data[0].liked").value(true))
      .andExpect(jsonPath("$.data[0].likeCount").value(1));
  }

  @Test
  void communityFeedSupportsLimitAndBeforeId() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    long olderPostId = createCommunityPost(accessToken, "First paged feed post");
    long newerPostId = createCommunityPost(accessToken, "Second paged feed post");

    mockMvc.perform(get("/api/post/feed")
        .param("limit", "1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(1))
      .andExpect(jsonPath("$.data[0].id").value((int) newerPostId));

    mockMvc.perform(get("/api/post/feed")
        .param("limit", "1")
        .param("beforeId", String.valueOf(newerPostId))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(1))
      .andExpect(jsonPath("$.data[0].id").value((int) olderPostId));
  }

  @Test
  void likeAndUnlikeAreIdempotent() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/post/2/like")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());
    mockMvc.perform(post("/api/post/2/like")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());

    mockMvc.perform(get("/api/post/2")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.likeCount").value(57))
      .andExpect(jsonPath("$.data.liked").value(true));

    mockMvc.perform(delete("/api/post/2/like")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());
    mockMvc.perform(delete("/api/post/2/like")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());

    mockMvc.perform(get("/api/post/2")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.likeCount").value(56))
      .andExpect(jsonPath("$.data.liked").value(false));
  }

  @Test
  void commentCreationPersistsRootCommentsInAscendingOrder() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    MvcResult result = mockMvc.perform(post("/api/post")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "Community P0 comment target"
          }
          """))
      .andExpect(status().isOk())
      .andReturn();
    long postId = readDataId(result.getResponse().getContentAsString());

    mockMvc.perform(post("/api/post/{postId}/comment", postId)
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "First root comment"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.content").value("First root comment"));

    mockMvc.perform(post("/api/post/{postId}/comment", postId)
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "Second root comment"
          }
          """))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.content").value("Second root comment"));

    mockMvc.perform(get("/api/post/{postId}/comment", postId))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.length()").value(2))
      .andExpect(jsonPath("$.data[0].content").value("First root comment"))
      .andExpect(jsonPath("$.data[1].content").value("Second root comment"));

    mockMvc.perform(get("/api/post/{postId}", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.data.commentCount").value(2));
  }

  @Test
  void deletePostSoftDeletesAndMakesPostUnavailable() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    MvcResult result = mockMvc.perform(post("/api/post")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "Community P0 delete target"
          }
          """))
      .andExpect(status().isOk())
      .andReturn();
    long postId = readDataId(result.getResponse().getContentAsString());

    mockMvc.perform(delete("/api/post/{postId}", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk());

    mockMvc.perform(get("/api/post/{postId}", postId))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
    mockMvc.perform(get("/api/post/{postId}/comment", postId))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
    mockMvc.perform(post("/api/post/{postId}/like", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
    mockMvc.perform(delete("/api/post/{postId}", postId)
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
  }

  @Test
  void nonAuthorDeleteReturnsPostNotFound() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000002", "123456");

    mockMvc.perform(delete("/api/post/1")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("POST_NOT_FOUND"));
  }

  @Test
  void uploadRejectsMissingInvalidAndOversizedFiles() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(multipart("/api/file/upload")
        .file(new MockMultipartFile("other", "cat.png", "image/png", new byte[] { 1 }))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("FILE_REQUIRED"));

    mockMvc.perform(multipart("/api/file/upload")
        .file(new MockMultipartFile("file", "note.txt", "text/plain", "hello".getBytes()))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("INVALID_FILE_TYPE"));

    mockMvc.perform(multipart("/api/file/upload")
        .file(new MockMultipartFile("file", "large.png", "image/png", new byte[6 * 1024 * 1024]))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("FILE_TOO_LARGE"));
  }

  @Test
  void uploadStorageFailureReturnsStableCode() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    when(fileStorageService.store(any(MultipartFile.class)))
      .thenThrow(new AppException(500, "FILE_UPLOAD_FAILED", "File upload failed"));

    mockMvc.perform(multipart("/api/file/upload")
        .file(new MockMultipartFile("file", "cat.png", "image/png", new byte[] { 1, 2, 3 }))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isInternalServerError())
      .andExpect(jsonPath("$.code").value("FILE_UPLOAD_FAILED"))
      .andExpect(jsonPath("$.message").value("File upload failed"));
  }

  @Test
  void invalidJsonAndParameterTypeReturnStableBadRequest() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");

    mockMvc.perform(post("/api/appointment")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("{"))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("BAD_REQUEST"))
      .andExpect(jsonPath("$.message").value("Invalid request body"));

    mockMvc.perform(get("/api/pet/not-a-number")
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isBadRequest())
      .andExpect(jsonPath("$.code").value("BAD_REQUEST"))
      .andExpect(jsonPath("$.message").value("Invalid request parameter"));
  }

  @Test
  void multipartLimitExceptionUsesFileTooLargeCode() {
    GlobalExceptionHandler handler = new GlobalExceptionHandler();
    ResponseEntity<ApiResponse<Void>> response =
      handler.handleMaxUploadSizeExceeded(new MaxUploadSizeExceededException(5L * 1024L * 1024L));

    org.assertj.core.api.Assertions.assertThat(response.getStatusCode().value()).isEqualTo(400);
    org.assertj.core.api.Assertions.assertThat(response.getBody()).isNotNull();
    org.assertj.core.api.Assertions.assertThat(response.getBody().code()).isEqualTo("FILE_TOO_LARGE");
    org.assertj.core.api.Assertions.assertThat(response.getBody().message()).isEqualTo("Image must be 5MB or smaller");
  }

  @Test
  void uploadStoresValidImageAndReturnsFileUrl() throws Exception {
    String accessToken = loginAndGetAccessToken("13800000001", "123456");
    when(fileStorageService.store(any(MultipartFile.class)))
      .thenReturn(new FileUploadDto("community/test-image.png", "http://localhost:9000/petpal/community/test-image.png"));

    mockMvc.perform(multipart("/api/file/upload")
        .file(new MockMultipartFile("file", "cat.png", "image/png", new byte[] { 1, 2, 3 }))
        .header("Authorization", "Bearer " + accessToken))
      .andExpect(status().isOk())
      .andExpect(jsonPath("$.code").value("OK"))
      .andExpect(jsonPath("$.data.fileKey").value("community/test-image.png"))
      .andExpect(jsonPath("$.data.url").value("/api/file/object/community/test-image.png"));
  }

  @Test
  void objectEndpointStreamsStoredImageBytes() throws Exception {
    when(fileStorageService.load("community/test-image.png"))
      .thenReturn(new FileDownloadDto("image/png", new byte[] { 1, 2, 3 }));

    mockMvc.perform(get("/api/file/object/community/test-image.png"))
      .andExpect(status().isOk())
      .andExpect(content().contentType("image/png"))
      .andExpect(content().bytes(new byte[] { 1, 2, 3 }));
  }

  @Test
  void objectEndpointReturnsStableNotFoundCode() throws Exception {
    when(fileStorageService.load("community/missing.png"))
      .thenThrow(new AppException(404, "FILE_NOT_FOUND", "File not found"));

    mockMvc.perform(get("/api/file/object/community/missing.png"))
      .andExpect(status().isNotFound())
      .andExpect(jsonPath("$.code").value("FILE_NOT_FOUND"))
      .andExpect(jsonPath("$.message").value("File not found"));
  }

  private String loginAndGetAccessToken(String phone, String password) throws Exception {
    return loginAndGetToken(phone, password, "accessToken");
  }

  private String loginAndGetRefreshToken(String phone, String password) throws Exception {
    return loginAndGetToken(phone, password, "refreshToken");
  }

  private String loginAndGetToken(String phone, String password, String tokenName) throws Exception {
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
    String marker = "\"" + tokenName + "\":\"";
    int start = body.indexOf(marker) + marker.length();
    int end = body.indexOf('"', start);
    return body.substring(start, end);
  }

  private long createCommunityPost(String accessToken, String content) throws Exception {
    MvcResult result = mockMvc.perform(post("/api/post")
        .header("Authorization", "Bearer " + accessToken)
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
          {
            "content": "%s"
          }
          """.formatted(content)))
      .andExpect(status().isOk())
      .andReturn();
    return readDataId(result.getResponse().getContentAsString());
  }

  private long readDataId(String body) throws Exception {
    JsonNode root = objectMapper.readTree(body);
    return root.path("data").path("id").asLong();
  }
}
