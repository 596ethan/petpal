package com.petpal.server.pet;

import com.petpal.server.common.error.AppException;
import com.petpal.server.pet.dto.HealthRecordCreateRequest;
import com.petpal.server.pet.dto.HealthRecordDto;
import com.petpal.server.pet.dto.PetCreateRequest;
import com.petpal.server.pet.dto.PetDto;
import com.petpal.server.pet.dto.PetUpdateRequest;
import com.petpal.server.pet.dto.VaccineRecordCreateRequest;
import com.petpal.server.pet.dto.VaccineRecordDto;
import java.sql.Date;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;

@Service
public class PetCommandService {
  private static final double MIN_WEIGHT = 0.01;
  private static final double MAX_WEIGHT = 999.99;

  private final JdbcClient jdbcClient;
  private final PetQueryService petQueryService;

  public PetCommandService(JdbcClient jdbcClient, PetQueryService petQueryService) {
    this.jdbcClient = jdbcClient;
    this.petQueryService = petQueryService;
  }

  public PetDto create(long userId, PetCreateRequest request) {
    String name = requiredText(request.name(), 50, "INVALID_PET_FIELD", "Pet name is required");
    String breed = optionalText(request.breed(), 50, "INVALID_PET_FIELD", "Pet breed is too long");
    String avatarUrl = optionalText(request.avatarUrl(), 255, "INVALID_PET_FIELD", "Pet avatar URL is too long");
    Date birthday = parseOptionalDate(request.birthday(), "INVALID_PET_FIELD", "Pet birthday must use yyyy-MM-dd");
    Double weight = validateWeight(request.weight());
    boolean neutered = request.neutered() != null && request.neutered();

    KeyHolder keyHolder = new GeneratedKeyHolder();
    jdbcClient.sql("""
      INSERT INTO pet (owner_id, name, species, breed, gender, birthday, weight, avatar_url, is_neutered)
      VALUES (:ownerId, :name, :species, :breed, :gender, :birthday, :weight, :avatarUrl, :neutered)
      """)
      .param("ownerId", userId)
      .param("name", name)
      .param("species", request.species().name())
      .param("breed", breed)
      .param("gender", request.gender().name())
      .param("birthday", birthday)
      .param("weight", weight)
      .param("avatarUrl", avatarUrl)
      .param("neutered", neutered)
      .update(keyHolder, "id");

    return petQueryService.getPet(userId, keyHolder.getKey().longValue());
  }

  public PetDto update(long userId, Long petId, PetUpdateRequest request) {
    PetDto existing = petQueryService.getPet(userId, petId);
    String name = request.hasName()
      ? requiredText(request.name(), 50, "INVALID_PET_FIELD", "Pet name is required")
      : existing.name();
    String breed = request.hasBreed()
      ? optionalText(request.breed(), 50, "INVALID_PET_FIELD", "Pet breed is too long")
      : existing.breed();
    String birthday = request.hasBirthday()
      ? toDateString(parseNullableUpdateDate(request.birthday(), "INVALID_PET_FIELD", "Pet birthday must use yyyy-MM-dd"))
      : existing.birthday();
    Double weight = request.hasWeight() ? validateNullableWeight(request.weight()) : existing.weight();
    String avatarUrl = request.hasAvatarUrl()
      ? optionalText(request.avatarUrl(), 255, "INVALID_PET_FIELD", "Pet avatar URL is too long")
      : existing.avatarUrl();
    boolean neutered = request.hasNeutered() && request.neutered() != null ? request.neutered() : existing.neutered();

    jdbcClient.sql("""
      UPDATE pet
      SET name = :name,
          species = :species,
          breed = :breed,
          gender = :gender,
          birthday = :birthday,
          weight = :weight,
          avatar_url = :avatarUrl,
          is_neutered = :neutered,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :petId AND owner_id = :userId AND deleted = 0
      """)
      .param("name", name)
      .param("species", request.hasSpecies() ? requiredEnumName(request.species(), "INVALID_PET_FIELD", "Pet species is required") : existing.species().name())
      .param("breed", breed)
      .param("gender", request.hasGender() ? requiredEnumName(request.gender(), "INVALID_PET_FIELD", "Pet gender is required") : existing.gender().name())
      .param("birthday", parsePersistedDate(birthday))
      .param("weight", weight)
      .param("avatarUrl", avatarUrl)
      .param("neutered", neutered)
      .param("petId", petId)
      .param("userId", userId)
      .update();

    return petQueryService.getPet(userId, petId);
  }

  public void delete(long userId, Long petId) {
    petQueryService.getPet(userId, petId);
    jdbcClient.sql("""
      UPDATE pet
      SET deleted = 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :petId AND owner_id = :userId AND deleted = 0
      """)
      .param("petId", petId)
      .param("userId", userId)
      .update();
  }

  public HealthRecordDto addHealthRecord(long userId, Long petId, HealthRecordCreateRequest request) {
    petQueryService.getPet(userId, petId);
    String title = requiredText(request.title(), 100, "INVALID_HEALTH_RECORD_FIELD", "Health record title is required");
    String description = optionalText(request.description(), 255, "INVALID_HEALTH_RECORD_FIELD", "Health record description is too long");
    Date recordDate = parseRequiredDate(request.recordDate(), "INVALID_HEALTH_RECORD_FIELD", "Health record date must use yyyy-MM-dd");
    Date nextDate = parseOptionalDate(request.nextDate(), "INVALID_HEALTH_RECORD_FIELD", "Health record next date must use yyyy-MM-dd");

    KeyHolder keyHolder = new GeneratedKeyHolder();
    jdbcClient.sql("""
      INSERT INTO pet_health_record (pet_id, record_type, title, description, record_date, next_date)
      VALUES (:petId, :recordType, :title, :description, :recordDate, :nextDate)
      """)
      .param("petId", petId)
      .param("recordType", request.recordType().name())
      .param("title", title)
      .param("description", description)
      .param("recordDate", recordDate)
      .param("nextDate", nextDate)
      .update(keyHolder, "id");

    Long id = keyHolder.getKey().longValue();
    return petQueryService.listHealthRecords(userId, petId).stream()
      .filter(item -> item.id().equals(id))
      .findFirst()
      .orElseThrow(() -> new AppException(404, "PET_NOT_FOUND", "Pet not found"));
  }

  public VaccineRecordDto addVaccine(long userId, Long petId, VaccineRecordCreateRequest request) {
    petQueryService.getPet(userId, petId);
    String vaccineName = requiredText(request.vaccineName(), 100, "INVALID_VACCINE_RECORD_FIELD", "Vaccine name is required");
    String hospital = optionalText(request.hospital(), 100, "INVALID_VACCINE_RECORD_FIELD", "Vaccine hospital is too long");
    Date vaccinatedAt = parseRequiredDate(request.vaccinatedAt(), "INVALID_VACCINE_RECORD_FIELD", "Vaccine date must use yyyy-MM-dd");
    Date nextDueAt = parseOptionalDate(request.nextDueAt(), "INVALID_VACCINE_RECORD_FIELD", "Vaccine next due date must use yyyy-MM-dd");

    KeyHolder keyHolder = new GeneratedKeyHolder();
    jdbcClient.sql("""
      INSERT INTO pet_vaccine (pet_id, vaccine_name, vaccinated_at, next_due_at, hospital)
      VALUES (:petId, :vaccineName, :vaccinatedAt, :nextDueAt, :hospital)
      """)
      .param("petId", petId)
      .param("vaccineName", vaccineName)
      .param("vaccinatedAt", vaccinatedAt)
      .param("nextDueAt", nextDueAt)
      .param("hospital", hospital)
      .update(keyHolder, "id");

    Long id = keyHolder.getKey().longValue();
    return petQueryService.listVaccines(userId, petId).stream()
      .filter(item -> item.id().equals(id))
      .findFirst()
      .orElseThrow(() -> new AppException(404, "PET_NOT_FOUND", "Pet not found"));
  }

  private String requiredText(String value, int maxLength, String code, String message) {
    if (value == null || value.trim().isEmpty()) {
      throw new AppException(400, code, message);
    }
    String trimmed = value.trim();
    if (trimmed.length() > maxLength) {
      throw new AppException(400, code, message);
    }
    return trimmed;
  }

  private String optionalText(String value, int maxLength, String code, String message) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      return null;
    }
    if (trimmed.length() > maxLength) {
      throw new AppException(400, code, message);
    }
    return trimmed;
  }

  private Double validateWeight(Double weight) {
    if (weight == null) {
      return null;
    }
    return validateNullableWeight(weight);
  }

  private Double validateNullableWeight(Double weight) {
    if (weight == null) {
      return null;
    }
    if (weight < MIN_WEIGHT || weight > MAX_WEIGHT) {
      throw new AppException(400, "INVALID_PET_FIELD", "Pet weight is invalid");
    }
    return weight;
  }

  private String requiredEnumName(Enum<?> value, String code, String message) {
    if (value == null) {
      throw new AppException(400, code, message);
    }
    return value.name();
  }

  private Date parseNullableUpdateDate(String value, String code, String message) {
    if (value == null) {
      return null;
    }
    return parseOptionalDate(value, code, message);
  }

  private Date parseRequiredDate(String value, String code, String message) {
    if (value == null || value.trim().isEmpty()) {
      throw new AppException(400, code, message);
    }
    return parseOptionalDate(value, code, message);
  }

  private Date parseOptionalDate(String value, String code, String message) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    if (trimmed.isEmpty()) {
      throw new AppException(400, code, message);
    }
    try {
      return Date.valueOf(LocalDate.parse(trimmed));
    } catch (DateTimeParseException ex) {
      throw new AppException(400, code, message);
    }
  }

  private Date parsePersistedDate(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return Date.valueOf(LocalDate.parse(value));
  }

  private String toDateString(Date date) {
    return date == null ? null : date.toLocalDate().toString();
  }
}
