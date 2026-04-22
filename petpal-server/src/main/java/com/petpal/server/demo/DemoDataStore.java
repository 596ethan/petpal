package com.petpal.server.demo;

import com.petpal.server.appointment.dto.AppointmentDto;
import com.petpal.server.appointment.dto.ServiceItemDto;
import com.petpal.server.appointment.dto.ServiceProviderDto;
import com.petpal.server.common.enums.AppointmentStatus;
import com.petpal.server.common.enums.HealthRecordType;
import com.petpal.server.common.enums.PetGender;
import com.petpal.server.common.enums.PetSpecies;
import com.petpal.server.common.enums.PostVisibility;
import com.petpal.server.common.enums.ProviderType;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostDto;
import com.petpal.server.pet.dto.HealthRecordDto;
import com.petpal.server.pet.dto.PetDto;
import com.petpal.server.pet.dto.VaccineRecordDto;
import com.petpal.server.user.dto.UserProfileDto;
import java.util.List;

public class DemoDataStore {
  public List<UserProfileDto> users() {
    return List.of(
      new UserProfileDto(1L, "13800000001", "小满", "https://placehold.co/96x96", "三只猫一只狗的记录者", 18, 42),
      new UserProfileDto(2L, "13800000002", "阿柚", "https://placehold.co/96x96", "每周都在洗护店", 12, 31)
    );
  }

  public List<PetDto> pets() {
    return List.of(
      new PetDto(1L, "糯米", PetSpecies.CAT, "英短", PetGender.FEMALE, "2022-05-01", 4.3, "https://placehold.co/120x120", true),
      new PetDto(2L, "七七", PetSpecies.DOG, "柯基", PetGender.MALE, "2021-11-18", 10.8, "https://placehold.co/120x120", false)
    );
  }

  public List<HealthRecordDto> healthRecords(long petId) {
    return List.of(
      new HealthRecordDto(1L, HealthRecordType.CHECKUP, "年度体检", "血常规正常，建议控制体重", "2026-02-18", "2027-02-18"),
      new HealthRecordDto(2L, HealthRecordType.MEDICATION, "驱虫", "完成体内驱虫", "2026-03-01", "2026-06-01")
    );
  }

  public List<VaccineRecordDto> vaccineRecords(long petId) {
    return List.of(
      new VaccineRecordDto(1L, "猫三联", "2025-04-18", "2026-04-11", "萌宠医院"),
      new VaccineRecordDto(2L, "狂犬", "2025-07-01", "2026-06-24", "萌宠医院")
    );
  }

  public List<PostDto> posts() {
    return List.of(
      new PostDto(1L, 1L, "小满", "https://placehold.co/64x64", 1L, "糯米", "糯米今天打完疫苗，状态很好。#猫咪日常#", List.of("https://placehold.co/400x300", "https://placehold.co/400x300?text=2"), List.of("猫咪日常"), PostVisibility.PUBLIC, 23, 5, false, "2026-03-24T18:20:00"),
      new PostDto(2L, 2L, "阿柚", "https://placehold.co/64x64", 2L, "七七", "七七第一次做全套美容，出片了。#柯基#", List.of("https://placehold.co/400x300?text=3"), List.of("柯基"), PostVisibility.PUBLIC, 56, 12, true, "2026-03-23T13:10:00")
    );
  }

  public List<PostCommentDto> comments(long postId) {
    return List.of(
      new PostCommentDto(1L, null, 2L, "阿柚", "恢复得真快。", "2026-03-24T19:10:00"),
      new PostCommentDto(2L, 1L, 1L, "小满", "是的，医生也说状态稳定。", "2026-03-24T19:18:00")
    );
  }

  public List<ServiceProviderDto> providers() {
    return List.of(
      new ServiceProviderDto(1L, "萌宠医院", ProviderType.HOSPITAL, "浦东新区丁香路 99 号", "021-12345678", 4.8, "https://placehold.co/800x400", "09:00-20:00", "ACTIVE"),
      new ServiceProviderDto(2L, "泡泡美容", ProviderType.GROOMING, "静安区延平路 28 号", "021-87654321", 4.7, "https://placehold.co/800x400?text=grooming", "10:00-21:00", "ACTIVE"),
      new ServiceProviderDto(3L, "安心寄养", ProviderType.BOARDING, "徐汇区漕溪北路 111 号", "021-99887766", 4.6, "https://placehold.co/800x400?text=boarding", "08:00-22:00", "ACTIVE")
    );
  }

  public List<ServiceItemDto> services(long providerId) {
    return switch ((int) providerId) {
      case 1 -> List.of(new ServiceItemDto(1L, 1L, "基础问诊", 59, 30), new ServiceItemDto(2L, 1L, "疫苗接种", 88, 20));
      case 2 -> List.of(new ServiceItemDto(3L, 2L, "基础洗澡", 79, 60), new ServiceItemDto(4L, 2L, "全套美容", 199, 120));
      default -> List.of(new ServiceItemDto(5L, 3L, "单日寄养", 128, 1440), new ServiceItemDto(6L, 3L, "周末寄养", 299, 2880));
    };
  }

  public List<AppointmentDto> appointments() {
    return List.of(
      new AppointmentDto(1L, "PP202603260001", 1L, 1L, "糯米", 1L, "萌宠医院", 2L, "疫苗接种", AppointmentStatus.CONFIRMED, "2026-03-29T10:30:00", "提前到店"),
      new AppointmentDto(2L, "PP202603260002", 1L, 2L, "七七", 2L, "泡泡美容", 4L, "全套美容", AppointmentStatus.PENDING_CONFIRM, "2026-03-30T14:00:00", "怕吹风")
    );
  }
}
