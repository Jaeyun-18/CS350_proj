import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const List<String> preferredLocations = <String>[
    '나중에 선택',
    'Homeplus Yusung',
    'Traders Wolpyeong',
    'KAIST Area',
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _users =
      FirebaseFirestore.instance.collection('users');

  String _normalizeEmail(String value) => value.trim().toLowerCase();

  bool isKaistEmail(String value) {
    final email = _normalizeEmail(value);
    return RegExp(r'^[^@\s]+@kaist\.ac\.kr$').hasMatch(email);
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }
    if (!isKaistEmail(email)) {
      return 'KAIST 이메일(@kaist.ac.kr)만 사용할 수 있어요.';
    }
    return null;
  }

  String? validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }
    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 해요.';
    }
    if (nickname.length > 20) {
      return '닉네임은 20자 이하로 입력해주세요.';
    }
    return null;
  }

  String _normalizeDisplayName(String value) => value.trim().toLowerCase();

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
      return '비밀번호를 입력해주세요.';
    }
    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 해요.';
    }
    return null;
  }

  String? validatePasswordConfirmation(String? value, String password) {
    if ((value ?? '').isEmpty) {
      return '비밀번호를 다시 입력해주세요.';
    }
    if (value != password) {
      return '비밀번호가 일치하지 않아요.';
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
        message: 'KAIST 이메일만 사용할 수 있어요.',
      );
    }

    if (!await isDisplayNameAvailable(trimmedDisplayName)) {
      throw FirebaseAuthException(
        code: 'nickname-taken',
        message: '이미 사용 중인 닉네임이에요.',
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
        message: '사용자 생성에 실패했습니다.',
      );
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final lockRef = _displayNameLockRef(trimmedDisplayName);
        final lockSnapshot = await transaction.get(lockRef);
        if (lockSnapshot.exists) {
          throw FirebaseAuthException(
            code: 'nickname-taken',
            message: '이미 사용 중인 닉네임이에요.',
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
        message: 'KAIST 이메일만 로그인할 수 있어요.',
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
        message: 'KAIST 이메일만 사용할 수 있어요.',
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
    final existingPreferredLocation =
        existing?['preferredLocation']?.toString().trim();
    final fallbackNickname = user.displayName?.trim();
    final displayName = (existingDisplayName?.isNotEmpty ?? false)
        ? existingDisplayName!
        : (legacyNickname?.isNotEmpty ?? false)
            ? legacyNickname!
            : (fallbackNickname?.isNotEmpty ?? false)
                ? fallbackNickname!
                : '학생';
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    final preferredLocation =
        sanitizePreferredLocation(existingPreferredLocation);

    final payload = <String, dynamic>{
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'displayNameLower': normalizedDisplayName,
      'preferredLocation': preferredLocation,
      'emailVerified': user.emailVerified,
      'registrationStatus': user.emailVerified ? 'active' : 'pending',
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
    if (existing?['emailVerified'] != user.emailVerified) {
      updates['emailVerified'] = user.emailVerified;
    }
    if (user.emailVerified && existing?['registrationStatus'] != 'active') {
      updates['registrationStatus'] = 'active';
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(updates, SetOptions(merge: true));
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

  Future<void> markEmailVerified(User user) async {
    await profileRef(user.uid).set({
      'emailVerified': user.emailVerified,
      'registrationStatus': user.emailVerified ? 'active' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

String friendlyAuthMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email-domain':
        return error.message ?? 'KAIST 이메일만 사용할 수 있어요.';
      case 'invalid-display-name':
        return error.message ?? '닉네임을 입력해주세요.';
      case 'nickname-taken':
        return error.message ?? '이미 사용 중인 닉네임이에요.';
      case 'invalid-email':
        return '이메일 형식이 올바르지 않아요.';
      case 'email-already-in-use':
        return '이미 가입된 이메일이에요.';
      case 'weak-password':
        return '비밀번호가 너무 약해요.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않아요.';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return error.message ?? '인증 처리 중 문제가 발생했어요.';
    }
  }
  return '예상치 못한 오류가 발생했어요.';
}
