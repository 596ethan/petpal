package com.petpal.server.admin;

import com.petpal.server.admin.dto.ProviderUpsertRequest;
import com.petpal.server.appointment.AppointmentService;
import com.petpal.server.appointment.ProviderQueryService;
import com.petpal.server.appointment.dto.AppointmentDto;
import com.petpal.server.appointment.dto.AppointmentStatusUpdateRequest;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.api.ApiPageResult;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.common.enums.AppointmentStatus;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
public class AdminController {
  private final ProviderQueryService providerQueryService;
  private final ProviderAdminService providerAdminService;
  private final AppointmentService appointmentService;

  public AdminController(ProviderQueryService providerQueryService, ProviderAdminService providerAdminService, AppointmentService appointmentService) {
    this.providerQueryService = providerQueryService;
    this.providerAdminService = providerAdminService;
    this.appointmentService = appointmentService;
  }

  @GetMapping("/providers")
  public ApiResponse<List<ServiceProviderDto>> providers() {
    return ApiResponse.ok(providerQueryService.listProviders());
  }

  @PostMapping("/providers")
  public ApiResponse<ServiceProviderDto> createProvider(@Valid @RequestBody ProviderUpsertRequest request) {
    return ApiResponse.ok(providerAdminService.create(request));
  }

  @PutMapping("/providers/{id}")
  public ApiResponse<ServiceProviderDto> updateProvider(@PathVariable Long id, @Valid @RequestBody ProviderUpsertRequest request) {
    return ApiResponse.ok(providerAdminService.update(id, request));
  }

  @GetMapping("/appointments")
  public ApiResponse<List<AppointmentDto>> appointments() {
    return ApiResponse.ok(appointmentService.listAll());
  }

  @GetMapping("/appointments/page")
  public ApiResponse<ApiPageResult<AppointmentDto>> appointmentsPage(
      @RequestParam(required = false) Integer pageNo,
      @RequestParam(required = false) Integer pageSize,
      @RequestParam(required = false) AppointmentStatus status,
      @RequestParam(required = false) String keyword) {
    return ApiResponse.ok(appointmentService.listAllPage(pageNo, pageSize, status, keyword));
  }

  @PutMapping("/appointments/{id}/status")
  public ApiResponse<AppointmentDto> updateStatus(@PathVariable Long id, @Valid @RequestBody AppointmentStatusUpdateRequest request) {
    return ApiResponse.ok(appointmentService.updateStatus(id, request.status()));
  }
}
