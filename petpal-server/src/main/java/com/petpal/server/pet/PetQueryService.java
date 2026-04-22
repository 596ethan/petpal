package com.petpal.server.pet;

import com.petpal.server.common.enums.HealthRecordType;
import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;
import com.petpal.server.common.error.AppException;
import com.petpal.server.pet.dto.HealthRecordDto;
import com.petpal.server.pet.dto.PetDto;
import com.petpal.server.pet.dto.VaccineRecordDto;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
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
      .query((rs, rowNum) -> mapPet(rs))
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
      .query((rs, rowNum) -> mapPet(rs))
      .optional()
      .orElseThrow(() -> new AppException(404, "PET_NOT_FOUND", "Pet not found"));
  }

  public List<HealthRecordDto> listHealthRecords(long userId, Long petId) {
    ensurePetOwnedByUser(userId, petId);
    // 健康记录按业务要求倒序返回，手机端时间线可以直接按接口结果展示。
    return jdbcClient.sql("""
      SELECT id, record_type, title, description, record_date, next_date
      FROM pet_health_record
      WHERE pet_id = :petId
      ORDER BY record_date DESC, id DESC
      """)
      .param("petId", petId)
      .query((rs, rowNum) -> new HealthRecordDto(
        rs.getLong("id"),
        HealthRecordType.valueOf(rs.getString("record_type")),
        rs.getString("title"),
        rs.getString("description"),
        requiredDateString(rs, "record_date"),
        nullableDateString(rs, "next_date")
      ))
      .list();
  }

  public List<VaccineRecordDto> listVaccines(long userId, Long petId) {
    ensurePetOwnedByUser(userId, petId);
    // 疫苗记录同样由后端保证排序，避免不同页面重复实现排序规则。
    return jdbcClient.sql("""
      SELECT id, vaccine_name, vaccinated_at, next_due_at, hospital
      FROM pet_vaccine
      WHERE pet_id = :petId
      ORDER BY vaccinated_at DESC, id DESC
      """)
      .param("petId", petId)
      .query((rs, rowNum) -> new VaccineRecordDto(
        rs.getLong("id"),
        rs.getString("vaccine_name"),
        requiredDateString(rs, "vaccinated_at"),
        nullableDateString(rs, "next_due_at"),
        rs.getString("hospital")
      ))
      .list();
  }

  private PetDto mapPet(ResultSet rs) throws SQLException {
    return new PetDto(
      rs.getLong("id"),
      rs.getString("name"),
      PetSpecies.valueOf(rs.getString("species")),
      rs.getString("breed"),
      PetGender.valueOf(rs.getString("gender")),
      nullableDateString(rs, "birthday"),
      nullableDouble(rs, "weight"),
      rs.getString("avatar_url"),
      rs.getBoolean("is_neutered")
    );
  }

  private String requiredDateString(ResultSet rs, String column) throws SQLException {
    Date date = rs.getDate(column);
    return date == null ? null : date.toString();
  }

  private String nullableDateString(ResultSet rs, String column) throws SQLException {
    Date date = rs.getDate(column);
    return date == null ? null : date.toString();
  }

  private Double nullableDouble(ResultSet rs, String column) throws SQLException {
    BigDecimal value = rs.getBigDecimal(column);
    return value == null ? null : value.doubleValue();
  }

  private void ensurePetOwnedByUser(long userId, Long petId) {
    // 所有宠物子资源先校验归属和软删除状态，避免越权读取健康/疫苗记录。
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
