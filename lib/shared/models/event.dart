import 'package:cloud_firestore/cloud_firestore.dart';

class MusicEvent {
  final String id;
  final String title;
  final String artistName;
  final String artistId;
  final String? artistImageUrl;
  final String venue;
  final String city;
  final String country;
  final DateTime date;
  final String? description;
  final String? ticketUrl;
  final double? price;
  final String? currency;
  final List<String>? genres;
  final String? imageUrl;
  final int attendeeCount;
  final bool isFeatured;
  final DateTime createdAt;

  MusicEvent({
    required this.id,
    required this.title,
    required this.artistName,
    required this.artistId,
    this.artistImageUrl,
    required this.venue,
    required this.city,
    required this.country,
    required this.date,
    this.description,
    this.ticketUrl,
    this.price,
    this.currency,
    this.genres,
    this.imageUrl,
    this.attendeeCount = 0,
    this.isFeatured = false,
    required this.createdAt,
  });

  factory MusicEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MusicEvent(
      id: doc.id,
      title: data['title'] ?? '',
      artistName: data['artistName'] ?? '',
      artistId: data['artistId'] ?? '',
      artistImageUrl: data['artistImageUrl'],
      venue: data['venue'] ?? '',
      city: data['city'] ?? '',
      country: data['country'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      description: data['description'],
      ticketUrl: data['ticketUrl'],
      price: data['price']?.toDouble(),
      currency: data['currency'],
      genres: data['genres'] != null ? List<String>.from(data['genres']) : null,
      imageUrl: data['imageUrl'],
      attendeeCount: data['attendeeCount'] ?? 0,
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artistName': artistName,
      'artistId': artistId,
      'artistImageUrl': artistImageUrl,
      'venue': venue,
      'city': city,
      'country': country,
      'date': Timestamp.fromDate(date),
      'description': description,
      'ticketUrl': ticketUrl,
      'price': price,
      'currency': currency,
      'genres': genres,
      'imageUrl': imageUrl,
      'attendeeCount': attendeeCount,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String get formattedTime {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String get location => '$city, $country';

  String get formattedPrice {
    if (price == null) return 'Free';
    return '${currency ?? '\$'}${price!.toStringAsFixed(2)}';
  }

  bool get isPast => date.isBefore(DateTime.now());
  
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool get isThisWeek {
    final now = DateTime.now();
    final weekFromNow = now.add(const Duration(days: 7));
    return date.isAfter(now) && date.isBefore(weekFromNow);
  }

  MusicEvent copyWith({
    String? id,
    String? title,
    String? artistName,
    String? artistId,
    String? artistImageUrl,
    String? venue,
    String? city,
    String? country,
    DateTime? date,
    String? description,
    String? ticketUrl,
    double? price,
    String? currency,
    List<String>? genres,
    String? imageUrl,
    int? attendeeCount,
    bool? isFeatured,
    DateTime? createdAt,
  }) {
    return MusicEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      artistImageUrl: artistImageUrl ?? this.artistImageUrl,
      venue: venue ?? this.venue,
      city: city ?? this.city,
      country: country ?? this.country,
      date: date ?? this.date,
      description: description ?? this.description,
      ticketUrl: ticketUrl ?? this.ticketUrl,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      genres: genres ?? this.genres,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
