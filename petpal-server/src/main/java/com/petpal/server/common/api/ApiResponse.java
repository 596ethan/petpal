package com.petpal.server.common.api;

public record ApiResponse<T>(String code, String message, T data, String requestId) {
  public static <T> ApiResponse<T> ok(T data) {
    return new ApiResponse<>("OK", "success", data, null);
  }

  public static ApiResponse<Void> ok() {
    return new ApiResponse<>("OK", "success", null, null);
  }
}
