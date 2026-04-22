package com.petpal.server.common.error;

import com.petpal.server.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.support.MissingServletRequestPartException;

@RestControllerAdvice
public class GlobalExceptionHandler {
  @ExceptionHandler(AppException.class)
  public ResponseEntity<ApiResponse<Void>> handleAppException(AppException ex) {
    // 业务层主动抛出的错误保留原 status/code/message，方便手机端直接展示可读错误。
    return ResponseEntity.status(ex.status())
      .body(new ApiResponse<>(ex.code(), ex.getMessage(), null, null));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
    // Bean Validation 可能返回多个字段错误，接口只取第一个，避免前端一次展示过多信息。
    String message = ex.getBindingResult().getFieldErrors().stream()
      .findFirst()
      .map(error -> error.getField() + " " + error.getDefaultMessage())
      .orElse("invalid request");
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
      .body(new ApiResponse<>("BAD_REQUEST", message, null, null));
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ApiResponse<Void>> handleUnreadableBody(HttpMessageNotReadableException ex) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
      .body(new ApiResponse<>("BAD_REQUEST", "Invalid request body", null, null));
  }

  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ApiResponse<Void>> handleTypeMismatch(MethodArgumentTypeMismatchException ex) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
      .body(new ApiResponse<>("BAD_REQUEST", "Invalid request parameter", null, null));
  }

  @ExceptionHandler(MissingServletRequestPartException.class)
  public ResponseEntity<ApiResponse<Void>> handleMissingRequestPart(MissingServletRequestPartException ex) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
      .body(new ApiResponse<>("FILE_REQUIRED", "File is required", null, null));
  }

  @ExceptionHandler(MaxUploadSizeExceededException.class)
  public ResponseEntity<ApiResponse<Void>> handleMaxUploadSizeExceeded(MaxUploadSizeExceededException ex) {
    return ResponseEntity.status(HttpStatus.BAD_REQUEST)
      .body(new ApiResponse<>("FILE_TOO_LARGE", "Image must be 5MB or smaller", null, null));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex, HttpServletRequest request) {
    // 未预期异常统一转成 500，不把堆栈细节暴露给客户端。
    return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
      .body(new ApiResponse<>("INTERNAL_ERROR", "Unexpected error at " + request.getRequestURI(), null, null));
  }
}
