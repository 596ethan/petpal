package com.petpal.server.community;

import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostDto;
import com.petpal.server.demo.DemoDataStore;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/post")
public class PostController {
  private final DemoDataStore demoDataStore;

  public PostController(DemoDataStore demoDataStore) {
    this.demoDataStore = demoDataStore;
  }

  @PostMapping
  public ApiResponse<PostDto> createPost(@RequestBody PostDto request) {
    return ApiResponse.ok(request);
  }

  @GetMapping("/feed")
  public ApiResponse<List<PostDto>> feed() {
    return ApiResponse.ok(demoDataStore.posts());
  }

  @GetMapping("/{postId}")
  public ApiResponse<PostDto> detail(@PathVariable Long postId) {
    PostDto post = demoDataStore.posts().stream().filter(item -> item.id().equals(postId)).findFirst().orElse(demoDataStore.posts().get(0));
    return ApiResponse.ok(post);
  }

  @DeleteMapping("/{postId}")
  public ApiResponse<Void> delete(@PathVariable Long postId) {
    return ApiResponse.ok();
  }

  @PostMapping("/{postId}/like")
  public ApiResponse<Void> like(@PathVariable Long postId) {
    return ApiResponse.ok();
  }

  @DeleteMapping("/{postId}/like")
  public ApiResponse<Void> unlike(@PathVariable Long postId) {
    return ApiResponse.ok();
  }

  @PostMapping("/{postId}/comment")
  public ApiResponse<PostCommentDto> comment(@PathVariable Long postId, @RequestBody PostCommentDto request) {
    return ApiResponse.ok(request);
  }

  @GetMapping("/{postId}/comment")
  public ApiResponse<List<PostCommentDto>> comments(@PathVariable Long postId) {
    return ApiResponse.ok(demoDataStore.comments(postId));
  }
}
