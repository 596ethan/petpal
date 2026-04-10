package com.petpal.server.admin;

import com.petpal.server.appointment.AppointmentService;
import com.petpal.server.appointment.ProviderQueryService;
import com.petpal.server.appointment.dto.AppointmentDto;
import com.petpal.server.appointment.dto.AppointmentStatusUpdateRequest;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.api.ApiResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
public class AdminController {
  private final ProviderQueryService providerQueryService;
  private final AppointmentService appointmentService;

  public AdminController(ProviderQueryService providerQueryService, AppointmentService appointmentService) {
    this.providerQueryService = providerQueryService;
    this.appointmentService = appointmentService;
  }

  @GetMapping("/providers")
  public ApiResponse<List<ServiceProviderDto>> providers() {
    return ApiResponse.ok(providerQueryService.listProviders());
  }

  @GetMapping("/appointments")
  public ApiResponse<List<AppointmentDto>> appointments() {
    return ApiResponse.ok(appointmentService.listAll());
  }

  @PutMapping("/appointments/{id}/status")
  public ApiResponse<AppointmentDto> updateStatus(@PathVariable Long id, @Valid @RequestBody AppointmentStatusUpdateRequest request) {
    return ApiResponse.ok(appointmentService.updateStatus(id, request.status()));
  }
}
