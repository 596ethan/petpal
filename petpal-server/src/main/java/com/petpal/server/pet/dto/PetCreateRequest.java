package com.petpal.server.pet.dto;

import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record PetCreateRequest(
  @NotBlank @Size(max = 50) String name,
  @NotNull PetSpecies species,
  @Size(max = 50) String breed,
  @NotNull PetGender gender,
  String birthday,
  Double weight,
  @Size(max = 255) String avatarUrl,
  Boolean neutered
) {
}
