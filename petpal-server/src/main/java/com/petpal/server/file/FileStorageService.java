package com.petpal.server.file;

import com.petpal.server.file.dto.FileUploadDto;
import com.petpal.server.file.dto.FileDownloadDto;
import org.springframework.web.multipart.MultipartFile;

public interface FileStorageService {
  FileUploadDto store(MultipartFile file);

  FileDownloadDto load(String fileKey);
}
