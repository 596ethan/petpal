package com.petpal.server.community.dto;

public record PostCommentDto(
  Long id,
  Long parentId,
  Long userId,
  String userNickname,
  String content,
  String createdAt
) {
}
