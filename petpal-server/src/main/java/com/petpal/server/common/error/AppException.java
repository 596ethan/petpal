package com.petpal.server.common.error;

public class AppException extends RuntimeException {
  private final int status;
  private final String code;

  public AppException(int status, String code, String message) {
    super(message);
    this.status = status;
    this.code = code;
  }

  public int status() {
    return status;
  }

  public String code() {
    return code;
  }
}
