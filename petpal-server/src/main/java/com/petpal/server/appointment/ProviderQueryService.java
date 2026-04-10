package com.petpal.server.appointment;

import com.petpal.server.appointment.dto.ServiceItemDto;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.enums.ProviderType;
import com.petpal.server.common.error.AppException;
import java.util.List;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Service;

@Service
public class ProviderQueryService {
  private final JdbcClient jdbcClient;

  public ProviderQueryService(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public List<ServiceProviderDto> listProviders() {
    return jdbcClient.sql("""
      SELECT id, name, type, address, phone, rating, cover_url, business_hours, status
      FROM service_provider
      WHERE deleted = 0
      ORDER BY id
      """)
      .query((rs, rowNum) -> new ServiceProviderDto(
        rs.getLong("id"),
        rs.getString("name"),
        ProviderType.valueOf(rs.getString("type")),
        rs.getString("address"),
        rs.getString("phone"),
        rs.getDouble("rating"),
        rs.getString("cover_url"),
        rs.getString("business_hours"),
        rs.getString("status")
      ))
      .list();
  }

  public ServiceProviderDto getProvider(Long id) {
    return jdbcClient.sql("""
      SELECT id, name, type, address, phone, rating, cover_url, business_hours, status
      FROM service_provider
      WHERE id = :id AND deleted = 0
      """)
      .param("id", id)
      .query((rs, rowNum) -> new ServiceProviderDto(
        rs.getLong("id"),
        rs.getString("name"),
        ProviderType.valueOf(rs.getString("type")),
        rs.getString("address"),
        rs.getString("phone"),
        rs.getDouble("rating"),
        rs.getString("cover_url"),
        rs.getString("business_hours"),
        rs.getString("status")
      ))
      .optional()
      .orElseThrow(() -> new AppException(404, "PROVIDER_NOT_FOUND", "Provider not found"));
  }

  public List<ServiceItemDto> getServices(Long providerId) {
    return jdbcClient.sql("""
      SELECT id, provider_id, name, price, duration
      FROM service_item
      WHERE provider_id = :providerId AND deleted = 0
      ORDER BY id
      """)
      .param("providerId", providerId)
      .query((rs, rowNum) -> new ServiceItemDto(
        rs.getLong("id"),
        rs.getLong("provider_id"),
        rs.getString("name"),
        rs.getDouble("price"),
        rs.getInt("duration")
      ))
      .list();
  }
}
