package com.petpal.server.community.dto;

import java.util.List;

public record PostCreateRequest(
  Long petId,
  String content,
  List<String> imageUrls
) {
}
