package com.petpal.server.community;

import com.petpal.server.auth.AuthContext;
import com.petpal.server.common.api.ApiResponse;
import com.petpal.server.community.dto.PostCommentCreateRequest;
import com.petpal.server.community.dto.PostCommentDto;
import com.petpal.server.community.dto.PostCreateRequest;
import com.petpal.server.community.dto.PostDto;
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
  private final CommunityQueryService communityQueryService;
  private final CommunityMutationService communityMutationService;
  private final AuthContext authContext;

  public PostController(CommunityQueryService communityQueryService, CommunityMutationService communityMutationService, AuthContext authContext) {
    this.communityQueryService = communityQueryService;
    this.communityMutationService = communityMutationService;
    this.authContext = authContext;
  }

  @PostMapping
  public ApiResponse<PostDto> createPost(@RequestBody PostCreateRequest request) {
    return ApiResponse.ok(communityMutationService.createPost(authContext.requireUserId(), request));
  }

  @GetMapping("/feed")
  public ApiResponse<List<PostDto>> feed() {
    return ApiResponse.ok(communityQueryService.feed(authContext.currentUserId().orElse(null)));
  }

  @GetMapping("/{postId}")
  public ApiResponse<PostDto> detail(@PathVariable Long postId) {
    return ApiResponse.ok(communityQueryService.detail(postId, authContext.currentUserId().orElse(null)));
  }

  @DeleteMapping("/{postId}")
  public ApiResponse<Void> delete(@PathVariable Long postId) {
    communityMutationService.deletePost(authContext.requireUserId(), postId);
    return ApiResponse.ok();
  }

  @PostMapping("/{postId}/like")
  public ApiResponse<Void> like(@PathVariable Long postId) {
    communityMutationService.like(authContext.requireUserId(), postId);
    return ApiResponse.ok();
  }

  @DeleteMapping("/{postId}/like")
  public ApiResponse<Void> unlike(@PathVariable Long postId) {
    communityMutationService.unlike(authContext.requireUserId(), postId);
    return ApiResponse.ok();
  }

  @PostMapping("/{postId}/comment")
  public ApiResponse<PostCommentDto> comment(@PathVariable Long postId, @RequestBody PostCommentCreateRequest request) {
    return ApiResponse.ok(communityMutationService.comment(authContext.requireUserId(), postId, request));
  }

  @GetMapping("/{postId}/comment")
  public ApiResponse<List<PostCommentDto>> comments(@PathVariable Long postId) {
    return ApiResponse.ok(communityQueryService.comments(postId));
  }
}
