import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event.dart';

class EventsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all upcoming events
  static Future<List<MusicEvent>> getUpcomingEvents({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching upcoming events: $e');
      return _getMockEvents();
    }
  }

  /// Get featured events
  static Future<List<MusicEvent>> getFeaturedEvents({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('isFeatured', isEqualTo: true)
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching featured events: $e');
      return _getMockEvents().where((e) => e.isFeatured).take(limit).toList();
    }
  }

  /// Get events by city
  static Future<List<MusicEvent>> getEventsByCity(String city, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('city', isEqualTo: city)
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events by city: $e');
      return _getMockEvents().where((e) => e.city == city).toList();
    }
  }

  /// Get events by artist
  static Future<List<MusicEvent>> getEventsByArtist(String artistId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('artistId', isEqualTo: artistId)
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events by artist: $e');
      return [];
    }
  }

  /// Get events this week
  static Future<List<MusicEvent>> getEventsThisWeek() async {
    try {
      final now = DateTime.now();
      final weekFromNow = now.add(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .where('date', isLessThan: Timestamp.fromDate(weekFromNow))
          .orderBy('date')
          .get();

      return snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching events this week: $e');
      return _getMockEvents().where((e) => e.isThisWeek).toList();
    }
  }

  /// Search events
  static Future<List<MusicEvent>> searchEvents(String query) async {
    try {
      final snapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThan: Timestamp.now())
          .orderBy('date')
          .get();

      final events = snapshot.docs
          .map((doc) => MusicEvent.fromFirestore(doc))
          .toList();

      // Filter by query
      return events.where((event) {
        final searchString = query.toLowerCase();
        return event.title.toLowerCase().contains(searchString) ||
               event.artistName.toLowerCase().contains(searchString) ||
               event.venue.toLowerCase().contains(searchString) ||
               event.city.toLowerCase().contains(searchString);
      }).toList();
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  /// RSVP to event
  static Future<void> rsvpToEvent(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final rsvpRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) return;

        final currentCount = eventDoc.data()?['attendeeCount'] ?? 0;
        transaction.update(eventRef, {'attendeeCount': currentCount + 1});
        transaction.set(rsvpRef, {
          'userId': userId,
          'rsvpedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error RSVPing to event: $e');
      rethrow;
    }
  }

  /// Cancel RSVP
  static Future<void> cancelRsvp(String eventId, String userId) async {
    try {
      final eventRef = _firestore.collection('events').doc(eventId);
      final rsvpRef = _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(userId);

      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) return;

        final currentCount = eventDoc.data()?['attendeeCount'] ?? 0;
        transaction.update(eventRef, {
          'attendeeCount': currentCount > 0 ? currentCount - 1 : 0
        });
        transaction.delete(rsvpRef);
      });
    } catch (e) {
      print('Error canceling RSVP: $e');
      rethrow;
    }
  }

  /// Check if user has RSVP'd
  static Future<bool> hasUserRsvped(String eventId, String userId) async {
    try {
      final doc = await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking RSVP status: $e');
      return false;
    }
  }

  /// Mock events for development
  static List<MusicEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      MusicEvent(
        id: '1',
        title: 'Summer Music Festival',
        artistName: 'The Weeknd',
        artistId: 'weeknd_123',
        artistImageUrl: 'https://via.placeholder.com/300',
        venue: 'Madison Square Garden',
        city: 'New York',
        country: 'USA',
        date: now.add(const Duration(days: 15)),
        description: 'Join us for an unforgettable night of music with The Weeknd performing all his greatest hits!',
        ticketUrl: 'https://example.com/tickets',
        price: 89.99,
        currency: '\$',
        genres: ['Pop', 'R&B'],
        imageUrl: 'https://via.placeholder.com/800x400',
        attendeeCount: 1520,
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 30)),
      ),
      MusicEvent(
        id: '2',
        title: 'Jazz Night',
        artistName: 'Norah Jones',
        artistId: 'norah_456',
        artistImageUrl: 'https://via.placeholder.com/300',
        venue: 'Blue Note',
        city: 'Los Angeles',
        country: 'USA',
        date: now.add(const Duration(days: 5)),
        description: 'An intimate evening of jazz with the legendary Norah Jones',
        ticketUrl: 'https://example.com/tickets',
        price: 65.00,
        currency: '\$',
        genres: ['Jazz', 'Soul'],
        imageUrl: 'https://via.placeholder.com/800x400',
        attendeeCount: 280,
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      MusicEvent(
        id: '3',
        title: 'Rock Legends Tour',
        artistName: 'Foo Fighters',
        artistId: 'foo_789',
        artistImageUrl: 'https://via.placeholder.com/300',
        venue: 'Wembley Stadium',
        city: 'London',
        country: 'UK',
        date: now.add(const Duration(days: 30)),
        description: 'Rock out with Foo Fighters on their worldwide tour!',
        ticketUrl: 'https://example.com/tickets',
        price: 120.00,
        currency: '£',
        genres: ['Rock', 'Alternative'],
        imageUrl: 'https://via.placeholder.com/800x400',
        attendeeCount: 3450,
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 45)),
      ),
      MusicEvent(
        id: '4',
        title: 'Electronic Paradise',
        artistName: 'Calvin Harris',
        artistId: 'calvin_101',
        artistImageUrl: 'https://via.placeholder.com/300',
        venue: 'Pacha Ibiza',
        city: 'Ibiza',
        country: 'Spain',
        date: now.add(const Duration(days: 60)),
        description: 'Dance the night away with Calvin Harris at Pacha Ibiza',
        ticketUrl: 'https://example.com/tickets',
        price: 75.00,
        currency: '€',
        genres: ['Electronic', 'Dance'],
        imageUrl: 'https://via.placeholder.com/800x400',
        attendeeCount: 890,
        isFeatured: true,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      MusicEvent(
        id: '5',
        title: 'Hip Hop Fest',
        artistName: 'Kendrick Lamar',
        artistId: 'kendrick_202',
        artistImageUrl: 'https://via.placeholder.com/300',
        venue: 'Staples Center',
        city: 'Los Angeles',
        country: 'USA',
        date: now.add(const Duration(days: 45)),
        description: 'Experience the energy of Kendrick Lamar live in concert',
        ticketUrl: 'https://example.com/tickets',
        price: 95.00,
        currency: '\$',
        genres: ['Hip Hop', 'Rap'],
        imageUrl: 'https://via.placeholder.com/800x400',
        attendeeCount: 2100,
        isFeatured: false,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
    ];
  }
}
