package com.petpal.server.file.dto;

public record FileDownloadDto(
  String contentType,
  byte[] content
) {
}
