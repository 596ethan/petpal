package com.petpal.server.user;

record UserAccountRecord(
  Long id,
  String phone,
  String password,
  String nickname,
  String avatarUrl,
  String bio
) {
}
