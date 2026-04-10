package com.petpal.server.file;

import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.file.dto.FileUploadDto;
import java.util.UUID;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/file")
public class FileController {
  @PostMapping("/upload")
  public ApiResponse<FileUploadDto> upload() {
    String fileKey = UUID.randomUUID() + ".jpg";
    return ApiResponse.ok(new FileUploadDto(fileKey, "http://localhost:9000/petpal/" + fileKey));
  }
}
