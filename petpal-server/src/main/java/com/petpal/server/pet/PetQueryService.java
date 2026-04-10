package com.petpal.server.pet;

import com.petpal.server.common.enums.HealthRecordType;
import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;
import com.petpal.server.common.error.AppException;
import com.petpal.server.pet.dto.HealthRecordDto;
import com.petpal.server.pet.dto.PetDto;
import com.petpal.server.pet.dto.VaccineRecordDto;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class PetQueryService {
  private final JdbcClient jdbcClient;

  public PetQueryService(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public List<PetDto> listPets(long userId) {
    return jdbcClient.sql("""
      SELECT id, name, species, breed, gender, birthday, weight, avatar_url, is_neutered
      FROM pet
      WHERE owner_id = :userId AND deleted = 0
      ORDER BY id
      """)
      .param("userId", userId)
      .query((rs, rowNum) -> new PetDto(
        rs.getLong("id"),
        rs.getString("name"),
        PetSpecies.valueOf(rs.getString("species")),
        rs.getString("breed"),
        PetGender.valueOf(rs.getString("gender")),
        rs.getDate("birthday").toString(),
        rs.getDouble("weight"),
        rs.getString("avatar_url"),
        rs.getBoolean("is_neutered")
      ))
      .list();
  }

  public PetDto getPet(long userId, Long petId) {
    return jdbcClient.sql("""
      SELECT id, name, species, breed, gender, birthday, weight, avatar_url, is_neutered
      FROM pet
      WHERE id = :petId AND owner_id = :userId AND deleted = 0
      """)
      .param("petId", petId)
      .param("userId", userId)
      .query((rs, rowNum) -> new PetDto(
        rs.getLong("id"),
        rs.getString("name"),
        PetSpecies.valueOf(rs.getString("species")),
        rs.getString("breed"),
        PetGender.valueOf(rs.getString("gender")),
        rs.getDate("birthday").toString(),
        rs.getDouble("weight"),
        rs.getString("avatar_url"),
        rs.getBoolean("is_neutered")
      ))
      .optional()
      .orElseThrow(() -> new AppException(404, "PET_NOT_FOUND", "Pet not found"));
  }

  public List<HealthRecordDto> listHealthRecords(long userId, Long petId) {
    ensurePetOwnedByUser(userId, petId);
    return jdbcClient.sql("""
      SELECT id, record_type, title, description, record_date, next_date
      FROM pet_health_record
      WHERE pet_id = :petId
      ORDER BY record_date DESC
      """)
      .param("petId", petId)
      .query((rs, rowNum) -> new HealthRecordDto(
        rs.getLong("id"),
        HealthRecordType.valueOf(rs.getString("record_type")),
        rs.getString("title"),
        rs.getString("description"),
        rs.getDate("record_date").toString(),
        rs.getDate("next_date") == null ? null : rs.getDate("next_date").toString()
      ))
      .list();
  }

  public List<VaccineRecordDto> listVaccines(long userId, Long petId) {
    ensurePetOwnedByUser(userId, petId);
    return jdbcClient.sql("""
      SELECT id, vaccine_name, vaccinated_at, next_due_at, hospital
      FROM pet_vaccine
      WHERE pet_id = :petId
      ORDER BY vaccinated_at DESC
      """)
      .param("petId", petId)
      .query((rs, rowNum) -> new VaccineRecordDto(
        rs.getLong("id"),
        rs.getString("vaccine_name"),
        rs.getDate("vaccinated_at").toString(),
        rs.getDate("next_due_at") == null ? null : rs.getDate("next_due_at").toString(),
        rs.getString("hospital")
      ))
      .list();
  }

  private void ensurePetOwnedByUser(long userId, Long petId) {
    Long count = jdbcClient.sql("SELECT COUNT(*) FROM pet WHERE id = :petId AND owner_id = :userId AND deleted = 0")
      .param("petId", petId)
      .param("userId", userId)
      .query(Long.class)
      .single();
    if (count == null || count == 0) {
      throw new AppException(404, "PET_NOT_FOUND", "Pet not found");
    }
  }
}
