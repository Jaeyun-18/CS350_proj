import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../profile_storage.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const List<String> preferredLocations = <String>[
    'Choose later',
    'Homeplus Yusung',
    'Traders Wolpyeong',
    'KAIST Area',
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users = FirebaseFirestore
      .instance
      .collection('users');

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  bool isKaistEmail(String value) {
    final email = _normalizeEmail(value);
    return RegExp(r'^[^@\s]+@kaist\.ac\.kr$').hasMatch(email);
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email.';
    }
    if (!isKaistEmail(email)) {
      return 'Only KAIST email (@kaist.ac.kr) is allowed.';
    }
    return null;
  }

  String? validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) {
      return 'Please enter a nickname.';
    }
    if (nickname.length < 2) {
      return 'Nickname must be at least 2 characters.';
    }
    if (nickname.length > 20) {
      return 'Nickname must be 20 characters or fewer.';
    }
    return null;
  }

  String _normalizeDisplayName(String value) => value.trim().toLowerCase();

  double _readDouble(dynamic value, {required double fallback}) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  String _displayNameLockId(String value) =>
      '__display_name_lock__${_normalizeDisplayName(value)}';

  DocumentReference<Map<String, dynamic>> _displayNameLockRef(String value) =>
      _users.doc(_displayNameLockId(value));

  Future<bool> isDisplayNameAvailable(String value) async {
    final displayName = value.trim();
    if (displayName.isEmpty) {
      return false;
    }

    final normalized = _normalizeDisplayName(displayName);
    final matchingDocs = await _users
        .where('displayNameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    if (matchingDocs.docs.isNotEmpty) {
      return false;
    }

    final byLegacyNickname = await _users
        .where('nickname', isEqualTo: displayName)
        .limit(1)
        .get();
    return byLegacyNickname.docs.isEmpty;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Please enter your password.';
    }
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    return null;
  }

  String? validatePasswordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != password) {
      return 'Passwords do not match.';
    }
    return null;
  }

  String? sanitizePreferredLocation(String? value) {
    if (value == null || value == preferredLocations.first) {
      return null;
    }
    return value;
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String displayName,
    required String password,
    String? preferredLocation,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final trimmedDisplayName = displayName.trim();
    if (!isKaistEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only KAIST email is allowed.',
      );
    }

    if (!await isDisplayNameAvailable(trimmedDisplayName)) {
      throw FirebaseAuthException(
        code: 'nickname-taken',
        message: 'This nickname is already taken.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'Failed to create user.',
      );
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final lockRef = _displayNameLockRef(trimmedDisplayName);
        final lockSnapshot = await transaction.get(lockRef);
        if (lockSnapshot.exists) {
          throw FirebaseAuthException(
            code: 'nickname-taken',
            message: 'This nickname is already taken.',
          );
        }

        transaction.set(lockRef, {
          'kind': 'display_name_lock',
          'displayName': trimmedDisplayName,
          'displayNameLower': _normalizeDisplayName(trimmedDisplayName),
          'uid': user.uid,
          'email': normalizedEmail,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(_users.doc(user.uid), {
          'uid': user.uid,
          'email': normalizedEmail,
          'displayName': trimmedDisplayName,
          'displayNameLower': _normalizeDisplayName(trimmedDisplayName),
          'preferredLocation': sanitizePreferredLocation(preferredLocation),
          'emailVerified': false,
          'registrationStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    }

    try {
      await user.sendEmailVerification();
    } catch (_) {
      // The account exists, so let the UI fall back to the verification page
      // and allow a resend attempt there.
    }

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (!isKaistEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only KAIST email can sign in.',
      );
    }

    return _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (!isKaistEmail(normalizedEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Only KAIST email is allowed.',
      );
    }

    await _auth.sendPasswordResetEmail(email: normalizedEmail);
  }

  Future<void> resendVerificationEmail(User user) async {
    await user.sendEmailVerification();
  }

  Future<void> signOut() => _auth.signOut();

  DocumentReference<Map<String, dynamic>> profileRef(String uid) =>
      _users.doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile(String uid) {
    return profileRef(uid).snapshots();
  }

  Future<void> ensureProfile(User user) async {
    final ref = profileRef(user.uid);
    final snapshot = await ref.get();
    final existing = snapshot.data();
    final existingDisplayName = existing?['displayName']?.toString().trim();
    final legacyNickname = existing?['nickname']?.toString().trim();
    final existingPreferredLocation = existing?['preferredLocation']
        ?.toString()
        .trim();
    final existingPhotoUrl = existing?['photoURL']?.toString().trim();
    final existingRatingCount = existing?['ratingCount'];
    final existingRatingTotal = existing?['ratingTotal'];
    final existingRatingAverage = existing?['ratingAverage'];
    final fallbackNickname = user.displayName?.trim();
    final fallbackPhotoUrl = user.photoURL?.trim();
    final displayName = (existingDisplayName?.isNotEmpty ?? false)
        ? existingDisplayName!
        : (legacyNickname?.isNotEmpty ?? false)
        ? legacyNickname!
        : (fallbackNickname?.isNotEmpty ?? false)
        ? fallbackNickname!
        : 'Student';
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    final preferredLocation = sanitizePreferredLocation(
      existingPreferredLocation,
    );
    final photoUrl = (existingPhotoUrl?.isNotEmpty ?? false)
        ? existingPhotoUrl!
        : (fallbackPhotoUrl?.isNotEmpty ?? false)
        ? fallbackPhotoUrl!
        : null;
    final ratingCount = _readDouble(existingRatingCount, fallback: 0.0).toInt();
    final ratingTotal = _readDouble(existingRatingTotal, fallback: 0.0).toInt();
    final ratingAverage = _readDouble(
      existingRatingAverage,
      fallback: ratingCount > 0 ? ratingTotal / ratingCount : 0.0,
    );

    final payload = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'displayNameLower': normalizedDisplayName,
      'preferredLocation': preferredLocation,
      'photoURL': photoUrl,
      'emailVerified': user.emailVerified,
      'registrationStatus': user.emailVerified ? 'active' : 'pending',
      'ratingCount': ratingCount,
      'ratingTotal': ratingTotal,
      'ratingAverage': ratingAverage,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      await ref.set({
        ...payload,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final updates = <String, dynamic>{};
    if (existing?['email'] != user.email) {
      updates['email'] = user.email;
    }
    if (existing?['displayName'] != displayName) {
      updates['displayName'] = displayName;
    }
    if (existing?['displayNameLower'] != normalizedDisplayName) {
      updates['displayNameLower'] = normalizedDisplayName;
    }
    if (existing?['nickname'] != null) {
      updates['nickname'] = FieldValue.delete();
    }
    if (existing?['preferredLocation'] != preferredLocation) {
      updates['preferredLocation'] = preferredLocation;
    }
    if (existing?['photoURL'] != photoUrl) {
      updates['photoURL'] = photoUrl;
    }
    if (existing?['emailVerified'] != user.emailVerified) {
      updates['emailVerified'] = user.emailVerified;
    }
    if (existing?['ratingCount'] == null) {
      updates['ratingCount'] = ratingCount;
    }
    if (existing?['ratingTotal'] == null) {
      updates['ratingTotal'] = ratingTotal;
    }
    if (existing?['ratingAverage'] == null) {
      updates['ratingAverage'] = ratingAverage;
    }
    if (user.emailVerified && existing?['registrationStatus'] != 'active') {
      updates['registrationStatus'] = 'active';
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(updates, SetOptions(merge: true));
    }

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == user.uid) {
      try {
        await currentUser.updateDisplayName(displayName);
      } catch (_) {}
      try {
        await currentUser.updatePhotoURL(photoUrl);
      } catch (_) {}
    }
  }

  Future<void> updatePreferredLocation({
    required String uid,
    required String? preferredLocation,
  }) async {
    await profileRef(uid).set({
      'preferredLocation': sanitizePreferredLocation(preferredLocation),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updatePhotoUrl({
    required String uid,
    required String? photoUrl,
  }) async {
    final normalizedPhotoUrl = (photoUrl == null || photoUrl.isEmpty)
        ? null
        : photoUrl;
    await profileRef(uid).set({
      'photoURL': normalizedPhotoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      try {
        await currentUser.updatePhotoURL(normalizedPhotoUrl);
      } catch (_) {}
    }
  }

  Future<void> updateDisplayName({
    required String uid,
    required String currentDisplayName,
    required String newDisplayName,
  }) async {
    final trimmedNew = newDisplayName.trim();
    final validation = validateNickname(trimmedNew);
    if (validation != null) {
      throw FirebaseAuthException(
        code: 'invalid-display-name',
        message: validation,
      );
    }

    final newLower = _normalizeDisplayName(trimmedNew);
    final currentTrimmed = currentDisplayName.trim();
    final currentLower = _normalizeDisplayName(currentTrimmed);
    if (newLower == currentLower) {
      // 동일 닉네임으로의 변경은 표시 이름 대소문자만 갱신한다.
      await profileRef(uid).set({
        'displayName': trimmedNew,
        'displayNameLower': newLower,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final newLockRef = _displayNameLockRef(trimmedNew);
      final newLockSnapshot = await transaction.get(newLockRef);
      if (newLockSnapshot.exists) {
        final ownerUid = newLockSnapshot.data()?['uid']?.toString();
        if (ownerUid != uid) {
          throw FirebaseAuthException(
            code: 'nickname-taken',
            message: 'This nickname is already taken.',
          );
        }
      }

      transaction.set(newLockRef, {
        'kind': 'display_name_lock',
        'displayName': trimmedNew,
        'displayNameLower': newLower,
        'uid': uid,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      if (currentTrimmed.isNotEmpty) {
        final oldLockRef = _displayNameLockRef(currentTrimmed);
        final oldLockSnapshot = await transaction.get(oldLockRef);
        if (oldLockSnapshot.exists &&
            oldLockSnapshot.data()?['uid']?.toString() == uid) {
          transaction.delete(oldLockRef);
        }
      }

      transaction.set(profileRef(uid), {
        'displayName': trimmedNew,
        'displayNameLower': newLower,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      try {
        await currentUser.updateDisplayName(trimmedNew);
      } catch (_) {}
    }
  }

  Future<void> markEmailVerified(User user) async {
    await profileRef(user.uid).set({
      'emailVerified': user.emailVerified,
      'registrationStatus': user.emailVerified ? 'active' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteAccount({required String password}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user found.',
      );
    }
    final email = currentUser.email;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'The signed-in account does not have an email address.',
      );
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser.reauthenticateWithCredential(credential);

    final uid = currentUser.uid;
    final profileSnapshot = await profileRef(uid).get();
    final profile = profileSnapshot.data();
    final displayName = profile?['displayName']?.toString().trim();

    final memberships = await FirebaseFirestore.instance
        .collection('group')
        .where('member_ids', arrayContains: uid)
        .get();

    const maxOpsPerBatch = 400;
    var batch = FirebaseFirestore.instance.batch();
    var opCount = 0;

    Future<void> flushBatch() async {
      if (opCount == 0) {
        return;
      }
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      opCount = 0;
    }

    void queueDelete(DocumentReference<Map<String, dynamic>> ref) {
      batch.delete(ref);
      opCount += 1;
    }

    void queueUpdate(
      DocumentReference<Map<String, dynamic>> ref,
      Map<String, dynamic> data,
    ) {
      batch.update(ref, data);
      opCount += 1;
    }

    for (final doc in memberships.docs) {
      final data = doc.data();
      final ownerId = data['user_id']?.toString() ?? '';
      if (ownerId == uid) {
        queueDelete(doc.reference);
      } else {
        queueUpdate(doc.reference, {
          'member_ids': FieldValue.arrayRemove([uid]),
          'now_num': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (opCount >= maxOpsPerBatch) {
        await flushBatch();
      }
    }

    if (displayName != null && displayName.isNotEmpty) {
      queueDelete(_displayNameLockRef(displayName));
    }
    queueDelete(profileRef(uid));

    await flushBatch();

    try {
      await ProfileStorage.instance.deleteAvatar(uid);
    } catch (_) {}

    await currentUser.delete();
  }
}

String friendlyAuthMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email-domain':
        return error.message ?? 'Only KAIST email is allowed.';
      case 'invalid-display-name':
        return error.message ?? 'Please enter a nickname.';
      case 'nickname-taken':
        return error.message ?? 'This nickname is already taken.';
      case 'account-has-active-groups':
        return error.message ?? 'Please end your active groups first.';
      case 'invalid-email':
        return 'Email format is invalid.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Please check your network connection.';
      default:
        return error.message ?? 'Something went wrong during authentication.';
    }
  }
  return 'An unexpected error occurred.';
}
