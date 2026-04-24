package com.petpal.server.file;

import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.common.error.AppException;
import com.petpal.server.file.dto.FileDownloadDto;
import com.petpal.server.file.dto.FileUploadDto;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/file")
public class FileController {
  private static final long MAX_IMAGE_BYTES = 5L * 1024L * 1024L;

  private final FileStorageService fileStorageService;

  public FileController(FileStorageService fileStorageService) {
    this.fileStorageService = fileStorageService;
  }

  @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
  public ApiResponse<FileUploadDto> upload(HttpServletRequest request, @RequestPart(name = "file", required = false) MultipartFile file) {
    validateFile(file);
    FileUploadDto uploaded = fileStorageService.store(file);
    return ApiResponse.ok(new FileUploadDto(uploaded.fileKey(), buildPublicUrl(request, uploaded.fileKey())));
  }

  @GetMapping("/object/**")
  public ResponseEntity<byte[]> object(HttpServletRequest request) {
    String fileKey = extractFileKey(request);
    FileDownloadDto fileDownload = fileStorageService.load(fileKey);
    return ResponseEntity.status(HttpStatus.OK)
      .header(HttpHeaders.CONTENT_TYPE, fileDownload.contentType())
      .body(fileDownload.content());
  }

  private void validateFile(MultipartFile file) {
    if (file == null || file.isEmpty()) {
      throw new AppException(400, "FILE_REQUIRED", "File is required");
    }
    String contentType = file.getContentType();
    if (contentType == null || !contentType.toLowerCase().startsWith("image/")) {
      throw new AppException(400, "INVALID_FILE_TYPE", "Only image uploads are supported");
    }
    if (file.getSize() > MAX_IMAGE_BYTES) {
      throw new AppException(400, "FILE_TOO_LARGE", "Image must be 5MB or smaller");
    }
  }

  private String buildPublicUrl(HttpServletRequest request, String fileKey) {
    String contextPath = request.getContextPath() == null ? "" : request.getContextPath().trim();
    String prefix = contextPath.isEmpty() ? "/api/file/object/" : contextPath + "/api/file/object/";
    return prefix + fileKey;
  }

  private String extractFileKey(HttpServletRequest request) {
    String prefix = request.getContextPath() + "/api/file/object/";
    String requestUri = request.getRequestURI();
    if (!requestUri.startsWith(prefix) || requestUri.length() <= prefix.length()) {
      throw new AppException(404, "FILE_NOT_FOUND", "File not found");
    }
    return requestUri.substring(prefix.length());
  }
}
