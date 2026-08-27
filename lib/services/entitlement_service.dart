import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum VerificationState {
  none,
  pending,
  verified,
  rejected,
}

/// Centralized entitlement and verification status service for Best-U.
/// Single source of truth for all Pro features and access decisions.
class EntitlementService extends ChangeNotifier {
  static final EntitlementService _instance = EntitlementService._internal();
  factory EntitlementService() => _instance;
  EntitlementService._internal() {
    _initAuthListener();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<User?>? _authSub;

  VerificationState _state = VerificationState.none;
  String? _reviewNote;
  String? _verificationType;
  String? _idNumber;
  bool _isInitialized = false;

  VerificationState get state => _state;
  String? get reviewNote => _reviewNote;
  String? get verificationType => _verificationType;
  String? get idNumber => _idNumber;
  bool get isInitialized => _isInitialized;

  /// Core Access Rule:
  /// ONLY users who are admin-approved (verificationStatus == 'verified')
  /// receive complimentary Best-U Pro access.
  bool get hasProAccess => _state == VerificationState.verified;

  bool get isVerified => _state == VerificationState.verified;
  bool get isPending => _state == VerificationState.pending;
  bool get isRejected => _state == VerificationState.rejected;
  bool get isNotSubmitted => _state == VerificationState.none;

  void _initAuthListener() {
    _authSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _subscribeToUserDoc(user.uid);
      } else {
        _userDocSub?.cancel();
        _userDocSub = null;
        _state = VerificationState.none;
        _reviewNote = null;
        _verificationType = null;
        _idNumber = null;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  void _subscribeToUserDoc(String uid) {
    _userDocSub?.cancel();
    _userDocSub = _db.collection('users').doc(uid).snapshots().listen(
      (doc) {
        if (doc.exists) {
          _updateFromData(doc.data());
        } else {
          _state = VerificationState.none;
          _reviewNote = null;
          _isInitialized = true;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('EntitlementService stream error: $err');
      },
    );
  }

  void _updateFromData(Map<String, dynamic>? data) {
    if (data == null) {
      _state = VerificationState.none;
      _reviewNote = null;
      _isInitialized = true;
      notifyListeners();
      return;
    }

    final rawStatus =
        (data['verificationStatus'] as String?)?.toLowerCase().trim() ?? 'none';
    _reviewNote = data['reviewNote'] as String?;
    _verificationType =
        data['verificationType'] as String? ?? data['userType'] as String?;
    _idNumber = data['idNumber'] as String?;

    switch (rawStatus) {
      case 'verified':
        _state = VerificationState.verified;
        break;
      case 'pending':
        _state = VerificationState.pending;
        break;
      case 'rejected':
        _state = VerificationState.rejected;
        break;
      default:
        _state = VerificationState.none;
        break;
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// Manually force a refresh of verification status from Firestore.
  Future<VerificationState> refreshStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      _state = VerificationState.none;
      _isInitialized = true;
      notifyListeners();
      return _state;
    }

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        _updateFromData(doc.data());
      } else {
        _state = VerificationState.none;
        _isInitialized = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing verification status: $e');
    }
    return _state;
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
