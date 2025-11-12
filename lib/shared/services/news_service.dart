import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';

class NewsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get latest news articles
  static Future<List<NewsArticle>> getLatestNews({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching latest news: $e');
      return _getMockNews();
    }
  }

  /// Get featured news
  static Future<List<NewsArticle>> getFeaturedNews({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .where('isFeatured', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching featured news: $e');
      return _getMockNews().where((n) => n.isFeatured).take(limit).toList();
    }
  }

  /// Get news by category
  static Future<List<NewsArticle>> getNewsByCategory(NewsCategory category, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .where('category', isEqualTo: category.name)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching news by category: $e');
      return _getMockNews().where((n) => n.category == category).toList();
    }
  }

  /// Get news by artist
  static Future<List<NewsArticle>> getNewsByArtist(String artistId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .where('artistId', isEqualTo: artistId)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching news by artist: $e');
      return [];
    }
  }

  /// Search news
  static Future<List<NewsArticle>> searchNews(String query) async {
    try {
      final snapshot = await _firestore
          .collection('news')
          .orderBy('publishedAt', descending: true)
          .limit(100)
          .get();

      final articles = snapshot.docs
          .map((doc) => NewsArticle.fromFirestore(doc))
          .toList();

      // Filter by query
      return articles.where((article) {
        final searchString = query.toLowerCase();
        return article.title.toLowerCase().contains(searchString) ||
               article.summary.toLowerCase().contains(searchString) ||
               (article.artistName?.toLowerCase().contains(searchString) ?? false) ||
               article.tags.any((tag) => tag.toLowerCase().contains(searchString));
      }).toList();
    } catch (e) {
      print('Error searching news: $e');
      return [];
    }
  }

  /// Increment view count
  static Future<void> incrementViewCount(String articleId) async {
    try {
      await _firestore.collection('news').doc(articleId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Like article
  static Future<void> likeArticle(String articleId, String userId) async {
    try {
      final likeRef = _firestore
          .collection('news')
          .doc(articleId)
          .collection('likes')
          .doc(userId);

      final articleRef = _firestore.collection('news').doc(articleId);

      await _firestore.runTransaction((transaction) async {
        final articleDoc = await transaction.get(articleRef);
        if (!articleDoc.exists) return;

        final currentCount = articleDoc.data()?['likeCount'] ?? 0;
        transaction.update(articleRef, {'likeCount': currentCount + 1});
        transaction.set(likeRef, {
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error liking article: $e');
      rethrow;
    }
  }

  /// Unlike article
  static Future<void> unlikeArticle(String articleId, String userId) async {
    try {
      final likeRef = _firestore
          .collection('news')
          .doc(articleId)
          .collection('likes')
          .doc(userId);

      final articleRef = _firestore.collection('news').doc(articleId);

      await _firestore.runTransaction((transaction) async {
        final articleDoc = await transaction.get(articleRef);
        if (!articleDoc.exists) return;

        final currentCount = articleDoc.data()?['likeCount'] ?? 0;
        transaction.update(articleRef, {
          'likeCount': currentCount > 0 ? currentCount - 1 : 0
        });
        transaction.delete(likeRef);
      });
    } catch (e) {
      print('Error unliking article: $e');
      rethrow;
    }
  }

  /// Check if user liked article
  static Future<bool> hasUserLiked(String articleId, String userId) async {
    try {
      final doc = await _firestore
          .collection('news')
          .doc(articleId)
          .collection('likes')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking like status: $e');
      return false;
    }
  }

  /// Mock news for development
  static List<NewsArticle> _getMockNews() {
    final now = DateTime.now();
    return [
      NewsArticle(
        id: '1',
        title: 'Taylor Swift Announces New Album "Midnights"',
        summary: 'Pop superstar Taylor Swift surprises fans with announcement of her tenth studio album, releasing October 21st.',
        content: '''
Taylor Swift has officially announced her tenth studio album, "Midnights," set to release on October 21st, 2022. The announcement came during her acceptance speech at the MTV Video Music Awards, where she won the award for Video of the Year.

The album, described by Swift as "the stories of 13 sleepless nights scattered throughout my life," marks her return to pop music after her indie-folk albums "folklore" and "evermore."

"This is a collection of music written in the middle of the night, a journey through terrors and sweet dreams," Swift said in her announcement video. "The floors we pace and the demons we face."

Fans are already speculating about collaborations and the album's sound, with many hoping for a return to the synth-pop style of her earlier work.
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'Music Weekly',
        category: NewsCategory.newRelease,
        tags: ['pop', 'taylor-swift', 'album-announcement'],
        artistName: 'Taylor Swift',
        viewCount: 15420,
        likeCount: 3240,
        commentCount: 567,
        isFeatured: true,
        publishedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      NewsArticle(
        id: '2',
        title: 'The Weeknd World Tour Dates Announced',
        summary: 'The Weeknd announces massive world tour spanning 50+ cities across North America, Europe, and Asia.',
        content: '''
The Weeknd has announced his highly anticipated "After Hours Til Dawn" world tour, which will kick off this summer and continue through 2024. The tour will span over 50 cities across multiple continents.

The tour follows the success of his albums "After Hours" and "Dawn FM," and promises an incredible stage production that fans have come to expect from The Weeknd's performances.

Tickets will go on sale next Friday, with pre-sale opportunities available for fan club members and credit card holders.
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'Tour News Daily',
        category: NewsCategory.tour,
        tags: ['the-weeknd', 'tour', 'concerts'],
        artistName: 'The Weeknd',
        viewCount: 8930,
        likeCount: 1840,
        commentCount: 234,
        isFeatured: true,
        publishedAt: now.subtract(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      NewsArticle(
        id: '3',
        title: 'Spotify Wrapped 2023: Top Artists and Songs',
        summary: 'Spotify releases annual Wrapped statistics, revealing the most-streamed artists and songs of the year.',
        content: '''
Spotify has released its annual "Wrapped" campaign, showcasing the most-streamed artists, songs, and podcasts of 2023. Bad Bunny takes the crown as the most-streamed artist globally for the third consecutive year.

Other top artists include Taylor Swift, Drake, The Weeknd, and Harry Styles. "As It Was" by Harry Styles was the most-streamed song globally.

The data reveals interesting trends in music consumption, with Latin music continuing its global dominance and K-pop maintaining strong growth in western markets.
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'Industry Insider',
        category: NewsCategory.industry,
        tags: ['spotify', 'streaming', 'statistics'],
        viewCount: 12340,
        likeCount: 2567,
        commentCount: 445,
        isFeatured: false,
        publishedAt: now.subtract(const Duration(hours: 8)),
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      NewsArticle(
        id: '4',
        title: 'Interview: Dua Lipa on Her New Sound',
        summary: 'In an exclusive interview, Dua Lipa discusses her musical evolution and upcoming projects.',
        content: '''
In a candid conversation, pop star Dua Lipa opens up about her journey in the music industry and her plans for the future. The British singer, known for hits like "Levitating" and "Don't Start Now," is working on her third studio album.

"I wanted to push myself creatively," Dua Lipa explains. "This new album is a departure from what people might expect, but I think that's what makes it exciting."

She hints at collaborations with unexpected artists and producers, promising fans a fresh take on her signature pop sound mixed with elements of dance and electronic music.
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'Celebrity Talk',
        category: NewsCategory.interview,
        tags: ['dua-lipa', 'interview', 'new-music'],
        artistName: 'Dua Lipa',
        viewCount: 6780,
        likeCount: 1234,
        commentCount: 189,
        isFeatured: false,
        publishedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
      ),
      NewsArticle(
        id: '5',
        title: 'Album Review: Arctic Monkeys - "The Car"',
        summary: 'A deep dive into Arctic Monkeys\' seventh studio album, exploring their evolution and mature sound.',
        content: '''
Arctic Monkeys return with "The Car," their seventh studio album that showcases a band fully comfortable in their mature, sophisticated sound. The album is a follow-up to 2018's "Tranquility Base Hotel & Casino."

The 10-track album features lush orchestration, jazz-influenced arrangements, and Alex Turner's poetic lyricism at its finest. Standout tracks include "Body Paint," "There'd Better Be A Mirrorball," and "Sculptures of Anything Goes."

While some fans might miss the raw energy of their early work, "The Car" proves that Arctic Monkeys continue to evolve and challenge themselves creatively. It's a bold statement from a band that refuses to stay in one place.

Rating: 8.5/10
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'Album Reviews Pro',
        category: NewsCategory.review,
        tags: ['arctic-monkeys', 'album-review', 'indie-rock'],
        artistName: 'Arctic Monkeys',
        albumName: 'The Car',
        viewCount: 4560,
        likeCount: 890,
        commentCount: 123,
        isFeatured: false,
        publishedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      NewsArticle(
        id: '6',
        title: 'BTS Announces Military Service Plans',
        summary: 'K-pop sensation BTS shares details about members\' military service, promising to return as a group.',
        content: '''
Global K-pop phenomenon BTS has announced the timeline for all members to fulfill their mandatory military service in South Korea. The news comes as fans worldwide expressed concern about the group's future.

"We will return as a more mature group after completing our duties," the group stated in their official announcement. The eldest member, Jin, will begin his service first, followed by the other members in order.

Despite the temporary hiatus, BTS promises to continue releasing solo projects and maintaining connection with their fanbase, ARMY. The group expects to reunite around 2025 for a comeback.
        ''',
        imageUrl: 'https://via.placeholder.com/800x400',
        authorName: 'K-Pop Central',
        category: NewsCategory.trending,
        tags: ['bts', 'k-pop', 'military-service'],
        artistName: 'BTS',
        viewCount: 18750,
        likeCount: 4320,
        commentCount: 892,
        isFeatured: true,
        publishedAt: now.subtract(const Duration(hours: 12)),
        createdAt: now.subtract(const Duration(hours: 13)),
      ),
    ];
  }
}
