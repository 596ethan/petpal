package com.petpal.server.pet.dto;

import com.fasterxml.jackson.annotation.JsonSetter;
import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;

public class PetUpdateRequest {
  private String name;
  private boolean nameSet;
  private PetSpecies species;
  private boolean speciesSet;
  private String breed;
  private boolean breedSet;
  private PetGender gender;
  private boolean genderSet;
  private String birthday;
  private boolean birthdaySet;
  private Double weight;
  private boolean weightSet;
  private String avatarUrl;
  private boolean avatarUrlSet;
  private Boolean neutered;
  private boolean neuteredSet;

  public String name() {
    return name;
  }

  public boolean hasName() {
    return nameSet;
  }

  @JsonSetter("name")
  public void setName(String name) {
    this.name = name;
    this.nameSet = true;
  }

  public PetSpecies species() {
    return species;
  }

  public boolean hasSpecies() {
    return speciesSet;
  }

  @JsonSetter("species")
  public void setSpecies(PetSpecies species) {
    this.species = species;
    this.speciesSet = true;
  }

  public String breed() {
    return breed;
  }

  public boolean hasBreed() {
    return breedSet;
  }

  @JsonSetter("breed")
  public void setBreed(String breed) {
    this.breed = breed;
    this.breedSet = true;
  }

  public PetGender gender() {
    return gender;
  }

  public boolean hasGender() {
    return genderSet;
  }

  @JsonSetter("gender")
  public void setGender(PetGender gender) {
    this.gender = gender;
    this.genderSet = true;
  }

  public String birthday() {
    return birthday;
  }

  public boolean hasBirthday() {
    return birthdaySet;
  }

  @JsonSetter("birthday")
  public void setBirthday(String birthday) {
    this.birthday = birthday;
    this.birthdaySet = true;
  }

  public Double weight() {
    return weight;
  }

  public boolean hasWeight() {
    return weightSet;
  }

  @JsonSetter("weight")
  public void setWeight(Double weight) {
    this.weight = weight;
    this.weightSet = true;
  }

  public String avatarUrl() {
    return avatarUrl;
  }

  public boolean hasAvatarUrl() {
    return avatarUrlSet;
  }

  @JsonSetter("avatarUrl")
  public void setAvatarUrl(String avatarUrl) {
    this.avatarUrl = avatarUrl;
    this.avatarUrlSet = true;
  }

  public Boolean neutered() {
    return neutered;
  }

  public boolean hasNeutered() {
    return neuteredSet;
  }

  @JsonSetter("neutered")
  public void setNeutered(Boolean neutered) {
    this.neutered = neutered;
    this.neuteredSet = true;
  }
}
