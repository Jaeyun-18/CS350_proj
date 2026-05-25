import 'package:cloud_firestore/cloud_firestore.dart';

class RatingService {
  RatingService._();

  static final RatingService instance = RatingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> _ratings(String groupId) =>
      _firestore.collection('group').doc(groupId).collection('ratings');

  DocumentReference<Map<String, dynamic>> _profileRef(String uid) =>
      _users.doc(uid);

  DocumentReference<Map<String, dynamic>> _groupRef(String groupId) =>
      _firestore.collection('group').doc(groupId);

  String _ratingId(String fromUid, String toUid) => '$fromUid${'__'}$toUid';

  int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return fallback;
  }

  DateTime? _readDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  bool isWithinRatingWindow(DateTime meetingTime, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final windowEnd = meetingTime.add(const Duration(days: 7));
    return !current.isBefore(meetingTime) && current.isBefore(windowEnd);
  }

  Future<RatingEligibility> loadEligibility({
    required String groupId,
    required String viewerUid,
    required String targetUid,
  }) async {
    final groupSnapshot = await _groupRef(groupId).get();
    final groupData = groupSnapshot.data();
    if (groupData == null) {
      return const RatingEligibility(
        canSubmit: false,
        message: 'Group not found.',
      );
    }

    final memberIds = _readMemberIds(groupData['member_ids']);
    if (!memberIds.contains(viewerUid)) {
      return const RatingEligibility(
        canSubmit: false,
        message: 'Only group participants can rate.',
      );
    }

    if (!memberIds.contains(targetUid)) {
      return const RatingEligibility(
        canSubmit: false,
        message: 'This profile is not part of the selected group.',
      );
    }

    if (viewerUid == targetUid) {
      return const RatingEligibility(
        canSubmit: false,
        message: 'You cannot rate yourself.',
      );
    }

    final meetingTime = _readDateTime(groupData['date_time']);
    if (meetingTime == null) {
      return const RatingEligibility(
        canSubmit: false,
        message: 'The meeting schedule is missing, so rating is unavailable.',
      );
    }

    final now = DateTime.now();
    if (!isWithinRatingWindow(meetingTime, now: now)) {
      return RatingEligibility(
        canSubmit: false,
        message:
            'Rating is only available from the meeting time until 7 days later.',
        meetingTime: meetingTime,
        windowEndsAt: meetingTime.add(const Duration(days: 7)),
      );
    }

    final existingSnapshot = await _ratings(
      groupId,
    ).doc(_ratingId(viewerUid, targetUid)).get();
    final existingData = existingSnapshot.data();
    final existingValue = existingData == null
        ? null
        : _readInt(existingData['value'], fallback: 0);

    return RatingEligibility(
      canSubmit: true,
      existingValue: existingValue,
      meetingTime: meetingTime,
      windowEndsAt: meetingTime.add(const Duration(days: 7)),
    );
  }

  Future<void> submitRating({
    required String groupId,
    required String viewerUid,
    required String targetUid,
    required int value,
  }) async {
    if (value < 1 || value > 5) {
      throw FirebaseException(
        plugin: 'rating_service',
        message: 'Rating must be between 1 and 5.',
      );
    }
    if (viewerUid == targetUid) {
      throw FirebaseException(
        plugin: 'rating_service',
        message: 'You cannot rate yourself.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final groupSnapshot = await transaction.get(_groupRef(groupId));
      final groupData = groupSnapshot.data();
      if (groupData == null) {
        throw FirebaseException(
          plugin: 'rating_service',
          message: 'Group not found.',
        );
      }

      final memberIds = _readMemberIds(groupData['member_ids']);
      if (!memberIds.contains(viewerUid)) {
        throw FirebaseException(
          plugin: 'rating_service',
          message: 'Only group participants can rate.',
        );
      }
      if (!memberIds.contains(targetUid)) {
        throw FirebaseException(
          plugin: 'rating_service',
          message: 'The selected member is not part of this group.',
        );
      }

      final meetingTime = _readDateTime(groupData['date_time']);
      if (meetingTime == null) {
        throw FirebaseException(
          plugin: 'rating_service',
          message: 'The meeting schedule is missing.',
        );
      }

      final now = DateTime.now();
      if (!isWithinRatingWindow(meetingTime, now: now)) {
        throw FirebaseException(
          plugin: 'rating_service',
          message:
              'Rating is only available from the meeting time until 7 days later.',
        );
      }

      final ratingRef = _ratings(groupId).doc(_ratingId(viewerUid, targetUid));
      final ratingSnapshot = await transaction.get(ratingRef);
      final existingRating = ratingSnapshot.data();
      final previousValue = existingRating == null
          ? null
          : _readInt(existingRating['value'], fallback: 0);
      final isNewRating = existingRating == null;
      final delta = isNewRating ? value : value - (previousValue ?? 0);

      final profileRef = _profileRef(targetUid);
      final profileSnapshot = await transaction.get(profileRef);
      final profileData = profileSnapshot.data();
      final currentCount = _readInt(profileData?['ratingCount'], fallback: 0);
      final currentTotal = _readInt(profileData?['ratingTotal'], fallback: 0);
      final nextCount = isNewRating ? currentCount + 1 : currentCount;
      final nextTotal = currentTotal + delta;
      final nextAverage = nextCount == 0 ? 0.0 : nextTotal / nextCount;

      transaction.set(ratingRef, {
        'groupId': groupId,
        'fromUid': viewerUid,
        'toUid': targetUid,
        'value': value,
        'meetingTime': Timestamp.fromDate(meetingTime),
        'updatedAt': FieldValue.serverTimestamp(),
        if (existingRating == null) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      transaction.set(profileRef, {
        'ratingCount': nextCount,
        'ratingTotal': nextTotal,
        'ratingAverage': nextAverage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  List<String> _readMemberIds(dynamic value) {
    if (value is! Iterable) {
      return const [];
    }
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }
}

class RatingEligibility {
  const RatingEligibility({
    required this.canSubmit,
    this.message,
    this.existingValue,
    this.meetingTime,
    this.windowEndsAt,
  });

  final bool canSubmit;
  final String? message;
  final int? existingValue;
  final DateTime? meetingTime;
  final DateTime? windowEndsAt;
}
