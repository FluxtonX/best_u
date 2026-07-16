import 'package:cloud_firestore/cloud_firestore.dart';

/// A single intermittent-fasting session stored in Firestore.
class FastingSession {
  final String id;
  final DateTime startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime? endsAt;
  final String status; // active | paused | completed | cancelled

  /// 0 = Beginner (12 h), 1 = Intermediate (16 h), 2 = Elite (20 h)
  final int level;

  final bool dayComplete;

  /// Whether the user has logged their post-fast meal for this session.
  final bool mealLogged;

  /// The user's answer to the mid-fast "Have you eaten yet?" prompt.
  /// null = not answered, 'yes' = stopped fast, 'no' = continuing.
  final String? yesNoResponse;

  /// Keys of milestone notifications already fired, e.g. ['25', '50'].
  final List<String> remindersFired;

  final Map<String, dynamic>? meta;

  FastingSession({
    required this.id,
    required this.startedAt,
    this.pausedAt,
    this.endedAt,
    this.endsAt,
    this.status = 'active',
    this.level = 0,
    this.dayComplete = false,
    this.mealLogged = false,
    this.yesNoResponse,
    this.remindersFired = const [],
    this.meta,
  });

  // ── Progress ───────────────────────────────────────────────────────────────

  double progressPct() {
    final now = DateTime.now();
    final end = endsAt ?? endedAt;
    if (end == null) return 0.0;
    final total = end.difference(startedAt).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = now.difference(startedAt).inSeconds.clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  // ── Serialisation ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': Timestamp.fromDate(startedAt),
        'pausedAt': pausedAt == null ? null : Timestamp.fromDate(pausedAt!),
        'endedAt': endedAt == null ? null : Timestamp.fromDate(endedAt!),
        'endsAt': endsAt == null ? null : Timestamp.fromDate(endsAt!),
        'status': status,
        'level': level,
        'dayComplete': dayComplete,
        'mealLogged': mealLogged,
        'yesNoResponse': yesNoResponse,
        'remindersFired': remindersFired,
        'meta': meta ?? {},
      };

  static FastingSession? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final d = doc.data()!;

    DateTime? fromTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    List<String> parseReminders(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return FastingSession(
      id: doc.id,
      startedAt: fromTs(d['startedAt']) ?? DateTime.now(),
      pausedAt: fromTs(d['pausedAt']),
      endedAt: fromTs(d['endedAt']),
      endsAt: fromTs(d['endsAt']),
      status: d['status'] ?? 'active',
      level: (d['level'] as int?) ?? 0,
      dayComplete: d['dayComplete'] == true,
      mealLogged: d['mealLogged'] == true,
      yesNoResponse: d['yesNoResponse'] as String?,
      remindersFired: parseReminders(d['remindersFired']),
      meta: (d['meta'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  // ── Copy-with for immutable updates ────────────────────────────────────────

  FastingSession copyWith({
    String? status,
    DateTime? pausedAt,
    DateTime? endedAt,
    DateTime? endsAt,
    bool? dayComplete,
    bool? mealLogged,
    String? yesNoResponse,
    List<String>? remindersFired,
  }) {
    return FastingSession(
      id: id,
      startedAt: startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      endedAt: endedAt ?? this.endedAt,
      endsAt: endsAt ?? this.endsAt,
      status: status ?? this.status,
      level: level,
      dayComplete: dayComplete ?? this.dayComplete,
      mealLogged: mealLogged ?? this.mealLogged,
      yesNoResponse: yesNoResponse ?? this.yesNoResponse,
      remindersFired: remindersFired ?? this.remindersFired,
      meta: meta,
    );
  }
}
