package com.petpal.server.pet;

import com.petpal.server.auth.AuthContext;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.pet.dto.HealthRecordCreateRequest;
import com.petpal.server.pet.dto.HealthRecordDto;
import com.petpal.server.pet.dto.PetCreateRequest;
import com.petpal.server.pet.dto.PetDto;
import com.petpal.server.pet.dto.PetUpdateRequest;
import com.petpal.server.pet.dto.VaccineRecordCreateRequest;
import com.petpal.server.pet.dto.VaccineRecordDto;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/pet")
public class PetController {
  private final PetQueryService petQueryService;
  private final PetCommandService petCommandService;
  private final AuthContext authContext;

  public PetController(PetQueryService petQueryService, PetCommandService petCommandService, AuthContext authContext) {
    this.petQueryService = petQueryService;
    this.petCommandService = petCommandService;
    this.authContext = authContext;
  }

  @PostMapping
  public ApiResponse<PetDto> createPet(@Valid @RequestBody PetCreateRequest request) {
    return ApiResponse.ok(petCommandService.create(authContext.requireUserId(), request));
  }

  @GetMapping("/list")
  public ApiResponse<List<PetDto>> listPets() {
    return ApiResponse.ok(petQueryService.listPets(authContext.requireUserId()));
  }

  @GetMapping("/{petId}")
  public ApiResponse<PetDto> getPet(@PathVariable Long petId) {
    return ApiResponse.ok(petQueryService.getPet(authContext.requireUserId(), petId));
  }

  @PutMapping("/{petId}")
  public ApiResponse<PetDto> updatePet(@PathVariable Long petId, @RequestBody PetUpdateRequest request) {
    return ApiResponse.ok(petCommandService.update(authContext.requireUserId(), petId, request));
  }

  @DeleteMapping("/{petId}")
  public ApiResponse<Void> deletePet(@PathVariable Long petId) {
    petCommandService.delete(authContext.requireUserId(), petId);
    return ApiResponse.ok();
  }

  @PostMapping("/{petId}/health")
  public ApiResponse<HealthRecordDto> addHealthRecord(@PathVariable Long petId, @Valid @RequestBody HealthRecordCreateRequest request) {
    return ApiResponse.ok(petCommandService.addHealthRecord(authContext.requireUserId(), petId, request));
  }

  @GetMapping("/{petId}/health")
  public ApiResponse<List<HealthRecordDto>> listHealthRecords(@PathVariable Long petId) {
    return ApiResponse.ok(petQueryService.listHealthRecords(authContext.requireUserId(), petId));
  }

  @PostMapping("/{petId}/vaccine")
  public ApiResponse<VaccineRecordDto> addVaccine(@PathVariable Long petId, @Valid @RequestBody VaccineRecordCreateRequest request) {
    return ApiResponse.ok(petCommandService.addVaccine(authContext.requireUserId(), petId, request));
  }

  @GetMapping("/{petId}/vaccine")
  public ApiResponse<List<VaccineRecordDto>> listVaccines(@PathVariable Long petId) {
    return ApiResponse.ok(petQueryService.listVaccines(authContext.requireUserId(), petId));
  }
}
