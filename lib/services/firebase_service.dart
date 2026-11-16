class LocalChatMessage {
  const LocalChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    required this.level,
    required this.sentAtUtc,
    this.isSystem = false,
  });

  final String id;
  final String sender;
  final String message;
  final int level;
  final DateTime sentAtUtc;
  final bool isSystem;
}

class LocalLeaderboardEntry {
  const LocalLeaderboardEntry({
    required this.rank,
    required this.companyName,
    required this.level,
    required this.companyValue,
  });

  final int rank;
  final String companyName;
  final int level;
  final double companyValue;
}

/// Offline-first facade. Firebase is intentionally optional: this class has
/// no Firebase SDK dependency, so missing native config cannot crash startup.
class FirebaseService {
  FirebaseService();

  bool _initialized = false;
  final List<LocalChatMessage> _messages = <LocalChatMessage>[
    LocalChatMessage(
      id: 'system-welcome',
      sender: 'SYSTEM',
      message: 'Global Chat berjalan dalam mode simulasi lokal.',
      level: 1,
      sentAtUtc: DateTime.utc(2026, 1, 1),
      isSystem: true,
    ),
  ];

  bool get isInitialized => _initialized;
  bool get isOnline => false;
  bool get usesLocalSimulation => true;

  Future<void> initialize({bool firebaseConfigured = false}) async {
    try {
      // Firebase initialization is skipped until platform configuration and
      // an SDK-backed implementation are deliberately added to the project.
      _initialized = true;
    } catch (_) {
      _initialized = true;
    }
  }

  Future<LocalChatMessage> sendChatMessage({
    required String sender,
    required String message,
    int level = 1,
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }
    if (cleanMessage.length > 180) {
      throw ArgumentError('Pesan maksimal 180 karakter.');
    }
    try {
      final item = LocalChatMessage(
        id: 'local-${DateTime.now().microsecondsSinceEpoch}',
        sender: sender.trim().isEmpty ? 'Pemain' : sender.trim(),
        message: cleanMessage,
        level: level < 1 ? 1 : level,
        sentAtUtc: DateTime.now().toUtc(),
      );
      _messages.add(item);
      return item;
    } catch (_) {
      rethrow;
    }
  }

  Future<List<LocalChatMessage>> fetchChatMessages() async {
    try {
      return List<LocalChatMessage>.unmodifiable(_messages);
    } catch (_) {
      return const <LocalChatMessage>[];
    }
  }

  Future<List<LocalLeaderboardEntry>> fetchLeaderboard() async {
    try {
      return const <LocalLeaderboardEntry>[
        LocalLeaderboardEntry(rank: 1, companyName: 'ADIEXPRESS', level: 8, companyValue: 1250000),
        LocalLeaderboardEntry(rank: 2, companyName: 'NUSANTARA CARGO', level: 6, companyValue: 875000),
        LocalLeaderboardEntry(rank: 3, companyName: 'GLOBAL HAUL', level: 5, companyValue: 620000),
      ];
    } catch (_) {
      return const <LocalLeaderboardEntry>[];
    }
  }

  Future<void> addSystemMessage(String message, {int level = 1}) async {
    try {
      _messages.add(LocalChatMessage(
        id: 'system-${DateTime.now().microsecondsSinceEpoch}',
        sender: 'SYSTEM',
        message: message,
        level: level,
        sentAtUtc: DateTime.now().toUtc(),
        isSystem: true,
      ));
    } catch (_) {
      // A local feed failure must never affect gameplay.
    }
  }

  Future<void> dispose() async {
    _initialized = false;
  }
}
