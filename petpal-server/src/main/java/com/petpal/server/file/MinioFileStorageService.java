package com.petpal.server.file;

import com.petpal.server.common.error.AppException;
import com.petpal.server.file.dto.FileDownloadDto;
import com.petpal.server.file.dto.FileUploadDto;
import io.minio.BucketExistsArgs;
import io.minio.GetObjectArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.StatObjectArgs;
import io.minio.StatObjectResponse;
import io.minio.errors.ErrorResponseException;
import java.io.InputStream;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class MinioFileStorageService implements FileStorageService {
  private final MinioClient minioClient;
  private final String endpoint;
  private final String bucket;

  public MinioFileStorageService(
    @Value("${petpal.storage.endpoint:http://localhost:9000}") String endpoint,
    @Value("${petpal.storage.bucket:petpal}") String bucket,
    @Value("${petpal.storage.access-key:minioadmin}") String accessKey,
    @Value("${petpal.storage.secret-key:minioadmin}") String secretKey
  ) {
    this.endpoint = endpoint.replaceAll("/+$", "");
    this.bucket = bucket;
    this.minioClient = MinioClient.builder()
      .endpoint(this.endpoint)
      .credentials(accessKey, secretKey)
      .build();
  }

  @Override
  public FileUploadDto store(MultipartFile file) {
    String fileKey = "community/" + UUID.randomUUID() + extensionOf(file);
    try {
      ensureBucket();
      minioClient.putObject(PutObjectArgs.builder()
        .bucket(bucket)
        .object(fileKey)
        .stream(file.getInputStream(), file.getSize(), -1)
        .contentType(file.getContentType())
        .build());
      return new FileUploadDto(fileKey, endpoint + "/" + bucket + "/" + fileKey);
    } catch (Exception ex) {
      throw new AppException(500, "FILE_UPLOAD_FAILED", "File upload failed");
    }
  }

  @Override
  public FileDownloadDto load(String fileKey) {
    try {
      StatObjectResponse stat = minioClient.statObject(StatObjectArgs.builder()
        .bucket(bucket)
        .object(fileKey)
        .build());
      try (InputStream inputStream = minioClient.getObject(GetObjectArgs.builder()
        .bucket(bucket)
        .object(fileKey)
        .build())) {
        String contentType = stat.contentType() == null || stat.contentType().isBlank()
          ? "application/octet-stream"
          : stat.contentType();
        return new FileDownloadDto(contentType, inputStream.readAllBytes());
      }
    } catch (ErrorResponseException ex) {
      if ("NoSuchKey".equals(ex.errorResponse().code())) {
        throw new AppException(404, "FILE_NOT_FOUND", "File not found");
      }
      throw new AppException(500, "FILE_DOWNLOAD_FAILED", "File download failed");
    } catch (Exception ex) {
      throw new AppException(500, "FILE_DOWNLOAD_FAILED", "File download failed");
    }
  }

  private void ensureBucket() throws Exception {
    boolean exists = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucket).build());
    if (!exists) {
      minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucket).build());
    }
  }

  private String extensionOf(MultipartFile file) {
    String originalFilename = file.getOriginalFilename();
    if (originalFilename != null) {
      int dot = originalFilename.lastIndexOf('.');
      if (dot >= 0 && dot < originalFilename.length() - 1) {
        String extension = originalFilename.substring(dot).toLowerCase(Locale.ROOT);
        if (extension.length() <= 10 && extension.matches("\\.[a-z0-9]+")) {
          return extension;
        }
      }
    }
    String contentType = file.getContentType();
    if ("image/png".equalsIgnoreCase(contentType)) {
      return ".png";
    }
    if ("image/gif".equalsIgnoreCase(contentType)) {
      return ".gif";
    }
    if ("image/webp".equalsIgnoreCase(contentType)) {
      return ".webp";
    }
    return ".jpg";
  }
}
