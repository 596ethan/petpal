package com.petpal.server.pet.dto;

import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;

public record PetDto(
  Long id,
  String name,
  PetSpecies species,
  String breed,
  PetGender gender,
  String birthday,
  Double weight,
  String avatarUrl,
  boolean neutered
) {
}
