package com.petpal.server.admin;

import com.petpal.server.admin.dto.ProviderUpsertRequest;
import com.petpal.server.appointment.ProviderQueryService;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.enums.ProviderType;
import com.petpal.server.common.error.AppException;
import java.util.Locale;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Service;

@Service
public class ProviderAdminService {
  private static final String DEFAULT_COVER_URL = "https://placehold.co/800x400";
  private static final String DEFAULT_BUSINESS_HOURS = "09:00-20:00";
  private static final String DEFAULT_STATUS = "ACTIVE";

  private final NamedParameterJdbcTemplate jdbcTemplate;
  private final ProviderQueryService providerQueryService;

  public ProviderAdminService(NamedParameterJdbcTemplate jdbcTemplate, ProviderQueryService providerQueryService) {
    this.jdbcTemplate = jdbcTemplate;
    this.providerQueryService = providerQueryService;
  }

  public ServiceProviderDto create(ProviderUpsertRequest request) {
    ProviderType type = parseType(request.type());
    KeyHolder keyHolder = new GeneratedKeyHolder();
    MapSqlParameterSource params = new MapSqlParameterSource()
      .addValue("name", request.name().trim())
      .addValue("type", type.name())
      .addValue("address", request.address().trim())
      .addValue("phone", emptyToNull(request.phone()))
      .addValue("rating", request.rating() == null ? 5.0d : request.rating())
      .addValue("coverUrl", resolveCreateCoverUrl(request.coverUrl()))
      .addValue("businessHours", resolveBusinessHours(request.businessHours()))
      .addValue("status", resolveStatus(request.status()));

    int updated = jdbcTemplate.update("""
      INSERT INTO service_provider
        (name, type, address, phone, rating, cover_url, business_hours, status)
      VALUES
        (:name, :type, :address, :phone, :rating, :coverUrl, :businessHours, :status)
      """, params, keyHolder, new String[] {"id"});
    if (updated != 1 || keyHolder.getKey() == null) {
      throw new AppException(500, "PROVIDER_CREATE_FAILED", "Create provider failed");
    }
    return providerQueryService.getProvider(keyHolder.getKey().longValue());
  }

  public ServiceProviderDto update(Long id, ProviderUpsertRequest request) {
    ServiceProviderDto existing = providerQueryService.getProvider(id);
    ProviderType type = parseType(request.type());
    int updated = jdbcTemplate.update("""
      UPDATE service_provider
      SET name = :name,
          type = :type,
          address = :address,
          phone = :phone,
          rating = :rating,
          cover_url = COALESCE(:coverUrl, cover_url),
          business_hours = :businessHours,
          status = :status,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = :id AND deleted = 0
      """, new MapSqlParameterSource()
      .addValue("id", id)
      .addValue("name", request.name().trim())
      .addValue("type", type.name())
      .addValue("address", request.address().trim())
      .addValue("phone", emptyToNull(request.phone()))
      .addValue("rating", request.rating() == null ? existing.rating() : request.rating())
      .addValue("coverUrl", emptyToNull(request.coverUrl()))
      .addValue("businessHours", resolveBusinessHours(request.businessHours()))
      .addValue("status", resolveStatus(request.status())));
    if (updated != 1) {
      throw new AppException(404, "PROVIDER_NOT_FOUND", "Provider not found");
    }
    return providerQueryService.getProvider(id);
  }

  private ProviderType parseType(String value) {
    if (value == null) {
      throw new AppException(400, "INVALID_PROVIDER_TYPE", "Provider type is required");
    }
    try {
      return ProviderType.valueOf(value.trim().toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException ex) {
      throw new AppException(400, "INVALID_PROVIDER_TYPE", "Invalid provider type");
    }
  }

  private String resolveCreateCoverUrl(String value) {
    if (value == null || value.isBlank()) {
      return DEFAULT_COVER_URL;
    }
    return value.trim();
  }

  private String resolveBusinessHours(String value) {
    if (value == null || value.isBlank()) {
      return DEFAULT_BUSINESS_HOURS;
    }
    return value.trim();
  }

  private String resolveStatus(String value) {
    if (value == null || value.isBlank()) {
      return DEFAULT_STATUS;
    }
    return value.trim().toUpperCase(Locale.ROOT);
  }

  private String emptyToNull(String value) {
    if (value == null || value.isBlank()) {
      return null;
    }
    return value.trim();
  }
}
