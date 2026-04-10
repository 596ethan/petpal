package com.petpal.server.appointment;

import com.petpal.server.appointment.dto.ServiceItemDto;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.api.ApiResponse;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/provider")
public class ProviderController {
  private final ProviderQueryService providerQueryService;

  public ProviderController(ProviderQueryService providerQueryService) {
    this.providerQueryService = providerQueryService;
  }

  @GetMapping("/list")
  public ApiResponse<List<ServiceProviderDto>> list() {
    return ApiResponse.ok(providerQueryService.listProviders());
  }

  @GetMapping("/{id}")
  public ApiResponse<ServiceProviderDto> detail(@PathVariable Long id) {
    return ApiResponse.ok(providerQueryService.getProvider(id));
  }

  @GetMapping("/{id}/services")
  public ApiResponse<List<ServiceItemDto>> services(@PathVariable Long id) {
    return ApiResponse.ok(providerQueryService.getServices(id));
  }
}
