class PostReview {
  final String id;
  final String parentId;
  final String postId;
  final String userId;
  final String rating;
  final String comment;
  final String status;
  final String createdOn;
  final String updatedOn;

  PostReview({
    required this.id,
    required this.parentId,
    required this.postId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory PostReview.fromJson(Map<String, dynamic> json) {
    return PostReview(
      id: json['id'] ?? '',
      parentId: json['parent_id'] ?? '0',
      postId: json['post_id'] ?? '',
      userId: json['user_id'] ?? '',
      rating: json['rateing'] ?? '0.0',
      comment: json['comment'] ?? '',
      status: json['status'] ?? '0',
      createdOn: json['created_on'] ?? '',
      updatedOn: json['updated_on'] ?? '',
    );
  }
}

class PostReviewsResponse {
  final bool status;
  final List<PostReview> data;
  final String code;

  PostReviewsResponse({
    required this.status,
    required this.data,
    required this.code,
  });

  factory PostReviewsResponse.fromJson(Map<String, dynamic> json) {
    return PostReviewsResponse(
      status: json['status'] == 'true',
      data: (json['data'] as List)
          .map((item) => PostReview.fromJson(item))
          .toList(),
      code: json['code'] ?? '0',
    );
  }
}