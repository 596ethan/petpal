package com.petpal.server.community.dto;

import com.petpal.server.common.enums.PostVisibility;
import java.util.List;

public record PostDto(
  Long id,
  Long userId,
  String userNickname,
  String userAvatarUrl,
  Long petId,
  String petName,
  String content,
  List<String> imageUrls,
  List<String> topics,
  PostVisibility visibility,
  long likeCount,
  long commentCount,
  boolean liked,
  String createdAt
) {
}
