import 'package:cloud_firestore/cloud_firestore.dart';

enum NewsCategory {
  newRelease,
  tour,
  industry,
  interview,
  review,
  trending,
}

class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? content;
  final String? imageUrl;
  final String? authorName;
  final String? authorImageUrl;
  final NewsCategory category;
  final List<String> tags;
  final String? artistId;
  final String? artistName;
  final String? albumId;
  final String? albumName;
  final String? sourceUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final bool isFeatured;
  final DateTime publishedAt;
  final DateTime createdAt;

  NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.content,
    this.imageUrl,
    this.authorName,
    this.authorImageUrl,
    required this.category,
    this.tags = const [],
    this.artistId,
    this.artistName,
    this.albumId,
    this.albumName,
    this.sourceUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isFeatured = false,
    required this.publishedAt,
    required this.createdAt,
  });

  factory NewsArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NewsArticle(
      id: doc.id,
      title: data['title'] ?? '',
      summary: data['summary'] ?? '',
      content: data['content'],
      imageUrl: data['imageUrl'],
      authorName: data['authorName'],
      authorImageUrl: data['authorImageUrl'],
      category: _parseCategoryFromString(data['category'] ?? 'trending'),
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      artistId: data['artistId'],
      artistName: data['artistName'],
      albumId: data['albumId'],
      albumName: data['albumName'],
      sourceUrl: data['sourceUrl'],
      viewCount: data['viewCount'] ?? 0,
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'imageUrl': imageUrl,
      'authorName': authorName,
      'authorImageUrl': authorImageUrl,
      'category': category.name,
      'tags': tags,
      'artistId': artistId,
      'artistName': artistName,
      'albumId': albumId,
      'albumName': albumName,
      'sourceUrl': sourceUrl,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'isFeatured': isFeatured,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static NewsCategory _parseCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'newrelease':
      case 'new_release':
        return NewsCategory.newRelease;
      case 'tour':
        return NewsCategory.tour;
      case 'industry':
        return NewsCategory.industry;
      case 'interview':
        return NewsCategory.interview;
      case 'review':
        return NewsCategory.review;
      default:
        return NewsCategory.trending;
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case NewsCategory.newRelease:
        return 'New Release';
      case NewsCategory.tour:
        return 'Tour';
      case NewsCategory.industry:
        return 'Industry';
      case NewsCategory.interview:
        return 'Interview';
      case NewsCategory.review:
        return 'Review';
      case NewsCategory.trending:
        return 'Trending';
    }
  }

  String get formattedPublishDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[publishedAt.month - 1]} ${publishedAt.day}, ${publishedAt.year}';
    }
  }

  String get readingTime {
    if (content == null) return '1 min read';
    final wordCount = content!.split(' ').length;
    final minutes = (wordCount / 200).ceil();
    return '$minutes min read';
  }

  NewsArticle copyWith({
    String? id,
    String? title,
    String? summary,
    String? content,
    String? imageUrl,
    String? authorName,
    String? authorImageUrl,
    NewsCategory? category,
    List<String>? tags,
    String? artistId,
    String? artistName,
    String? albumId,
    String? albumName,
    String? sourceUrl,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    bool? isFeatured,
    DateTime? publishedAt,
    DateTime? createdAt,
  }) {
    return NewsArticle(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      authorName: authorName ?? this.authorName,
      authorImageUrl: authorImageUrl ?? this.authorImageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isFeatured: isFeatured ?? this.isFeatured,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
