import '../../../../core/api/api_client.dart';
import '../models/fraud_risk.dart';
import '../models/suspension_record.dart';
import '../models/invite_link.dart';

class AnalyticsRepository {
  final ApiClient _api;

  AnalyticsRepository([ApiClient? apiClient]) : _api = apiClient ?? ApiClient();

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime _asDateTime(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ?? fallback ?? DateTime.now();
  }

  Future<Map<int, String>> _resolveUserNames(Iterable<int> userIds) async {
    final ids = userIds.where((id) => id > 0).toSet();
    final names = <int, String>{};
    for (final userId in ids) {
      try {
        final response = await _api.get('/api/v1/admin/users/$userId');
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final fullName = data['full_name']?.toString();
          final email = data['email']?.toString();
          names[userId] = (fullName != null && fullName.trim().isNotEmpty)
              ? fullName
              : (email != null && email.trim().isNotEmpty)
                    ? email
                    : 'User #$userId';
        } else if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          final fullName = map['full_name']?.toString();
          final email = map['email']?.toString();
          names[userId] = (fullName != null && fullName.trim().isNotEmpty)
              ? fullName
              : (email != null && email.trim().isNotEmpty)
                    ? email
                    : 'User #$userId';
        }
      } catch (_) {
        names[userId] = 'User #$userId';
      }
    }
    return names;
  }

  String _riskLevelFromScore(int score) {
    if (score >= 75) return 'critical';
    if (score >= 50) return 'high';
    if (score >= 25) return 'medium';
    return 'low';
  }

  String _severityFromContribution(int contribution) {
    if (contribution >= 50) return 'high';
    if (contribution >= 20) return 'medium';
    return 'low';
  }

  Future<List<FraudRisk>> getFraudRisks() async {
    final response = await _api.get('/api/v1/admin/fraud/high-risk-users');
    final data = response.data;
    final items = data is List ? data : const <dynamic>[];
    final ids = items
        .whereType<Map>()
        .map((item) => _asInt(item['user_id']))
        .where((id) => id > 0);
    final userNames = await _resolveUserNames(ids);

    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      final score = _asInt(item['risk_score']);
      final userId = _asInt(item['user_id']);
      final breakdown = item['breakdown'];
      final factors = <FraudFactor>[];
      if (breakdown is Map) {
        for (final entry in breakdown.entries) {
          final contribution = _asInt(entry.value);
          factors.add(
            FraudFactor(
              name: entry.key.toString().replaceAll('_', ' '),
              description: 'Backend fraud signal: ${entry.key}',
              contribution: contribution,
              severity: _severityFromContribution(contribution),
            ),
          );
        }
      }

      return FraudRisk(
        userId: userId,
        userName: userNames[userId] ?? item['email']?.toString() ?? 'User #$userId',
        score: score,
        level: _riskLevelFromScore(score),
        factors: factors,
        lastUpdated: _asDateTime(item['last_updated']),
        history: [
          FraudScoreHistory(
            date: _asDateTime(item['last_updated']),
            score: score,
          ),
        ],
      );
    }).toList();
  }

  Future<List<SuspensionRecord>> getSuspensionHistory() async {
    final usersResponse = await _api.get(
      '/api/v1/admin/users/',
      queryParameters: {'skip': 0, 'limit': 200},
    );
    final payload = usersResponse.data is Map<String, dynamic>
        ? usersResponse.data as Map<String, dynamic>
        : Map<String, dynamic>.from(usersResponse.data as Map);
    final rawUsers = payload['items'] ?? payload['users'] ?? const <dynamic>[];
    final users = rawUsers is List ? rawUsers : const <dynamic>[];

    final userNames = <int, String>{};
    final history = <SuspensionRecord>[];
    for (final rawUser in users.whereType<Map>()) {
      final user = Map<String, dynamic>.from(rawUser);
      final userId = _asInt(user['id']);
      if (userId <= 0) continue;
      userNames[userId] = user['full_name']?.toString() ?? user['email']?.toString() ?? 'User #$userId';

      final response = await _api.get('/api/v1/admin/users/$userId/suspension-history');
      final entries = response.data is List ? response.data as List : const <dynamic>[];
      for (final rawEntry in entries.whereType<Map>()) {
        final entry = Map<String, dynamic>.from(rawEntry);
        final action = entry['action_type']?.toString() ?? 'suspension';
        final lowerAction = action.toLowerCase();
        final suspended = lowerAction.contains('suspension');
        final reactivated = lowerAction.contains('reactivation');

        history.add(
          SuspensionRecord(
            id: _asInt(entry['id']),
            userId: userId,
            userName: userNames[userId] ?? 'User #$userId',
            reason: entry['reason']?.toString() ?? 'other',
            notes: entry['new_value']?.toString() ?? entry['old_value']?.toString(),
            suspendedBy: entry['actor_name']?.toString() ?? 'Unknown',
            suspendedAt: _asDateTime(entry['created_at']),
            reactivatedAt: reactivated ? _asDateTime(entry['created_at']) : null,
            reactivatedBy: reactivated ? entry['actor_name']?.toString() : null,
            isActive: suspended,
          ),
        );
      }
    }

    history.sort((a, b) => b.suspendedAt.compareTo(a.suspendedAt));
    return history;
  }

  Future<List<InviteLink>> getInviteLinks() async {
    final response = await _api.get('/api/v1/admin/users/invites');
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];
    return items.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      return InviteLink(
        id: _asInt(item['id']),
        token: item['token']?.toString() ?? '',
        email: item['email']?.toString() ?? '',
        role: item['role']?.toString() ?? 'customer',
        createdAt: _asDateTime(item['sent_at']),
        expiresAt: _asDateTime(item['expires_at']),
        createdBy: item['created_by']?.toString() ?? 'System',
        usedAt: item['used_at'] != null ? _asDateTime(item['used_at']) : null,
        isUsed: item['is_used'] == true || (item['status']?.toString().toLowerCase() == 'accepted'),
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getLoginHistory() async {
    final response = await _api.get(
      '/api/v1/admin/security/audit-logs',
      queryParameters: {'days': 30, 'skip': 0, 'limit': 500},
    );
    final payload = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);
    final items = payload['items'] is List ? payload['items'] as List : const <dynamic>[];
    final counts = <String, int>{};

    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      if (item['action']?.toString() != 'AUTH_LOGIN') {
        continue;
      }
      final timestamp = _asDateTime(item['timestamp']);
      final key = '${timestamp.year.toString().padLeft(4, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (entry) => {
            'date': DateTime.parse(entry.key),
            'logins': entry.value,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> getRentalFrequency() async {
    final response = await _api.get(
      '/api/v1/admin/rentals/history',
      queryParameters: {'skip': 0, 'limit': 500},
    );
    final items = response.data is List ? response.data as List : const <dynamic>[];
    final counts = <String, int>{};
    const monthLabels = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final startTime = _asDateTime(item['start_time']);
      final key = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final entries = counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final recent = entries.length > 6 ? entries.sublist(entries.length - 6) : entries;

    return recent.map((entry) {
      final parts = entry.key.split('-');
      final month = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 1;
      return {
        'month': monthLabels[month],
        'rentals': entry.value,
      };
    }).toList();
  }

  Future<Map<String, int>> getDeviceBreakdown() async {
    final response = await _api.get(
      '/api/v1/admin/fraud/device-fingerprints',
      queryParameters: {'limit': 500},
    );
    final items = response.data is List ? response.data as List : const <dynamic>[];
    final counts = <String, int>{};

    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final type = item['device_type']?.toString().toUpperCase() ?? 'UNKNOWN';
      final label = switch (type) {
        'ANDROID' => 'Android App',
        'IOS' => 'iOS App',
        'WEB' => 'Web Browser',
        _ => 'Other',
      };
      counts[label] = (counts[label] ?? 0) + 1;
    }

    return counts;
  }
}
