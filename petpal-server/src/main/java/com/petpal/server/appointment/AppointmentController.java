package com.petpal.server.appointment;

import com.petpal.server.auth.AuthContext;
import com.petpal.server.appointment.dto.AppointmentCreateRequest;
import com.petpal.server.appointment.dto.AppointmentDto;
import com.petpal.server.common.api.ApiResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/appointment")
public class AppointmentController {
  private final AppointmentService appointmentService;
  private final AuthContext authContext;

  public AppointmentController(AppointmentService appointmentService, AuthContext authContext) {
    this.appointmentService = appointmentService;
    this.authContext = authContext;
  }

  @PostMapping
  public ApiResponse<AppointmentDto> create(@Valid @RequestBody AppointmentCreateRequest request) {
    return ApiResponse.ok(appointmentService.create(authContext.requireUserId(), request));
  }

  @GetMapping("/list")
  public ApiResponse<List<AppointmentDto>> list() {
    return ApiResponse.ok(appointmentService.listByUser(authContext.requireUserId()));
  }

  @PutMapping("/{id}/cancel")
  public ApiResponse<Void> cancel(@PathVariable Long id) {
    appointmentService.cancel(authContext.requireUserId(), id);
    return ApiResponse.ok();
  }
}
