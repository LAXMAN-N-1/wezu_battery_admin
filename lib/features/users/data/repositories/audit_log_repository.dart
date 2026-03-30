import '../models/audit_log.dart';

class AuditLogRepository {
  static final List<AuditLog> _logs = [
    AuditLog(id: 1, userId: 1, userName: 'Murari Varma', action: 'login', module: 'auth', details: 'Admin login successful', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    AuditLog(id: 2, userId: 1, userName: 'Murari Varma', action: 'update', module: 'users', details: 'Updated user profile for Rahul Sharma', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(minutes: 15)), beforeValue: 'role: driver', afterValue: 'role: driver'),
    AuditLog(id: 3, userId: 7, userName: 'Deepak Verma', action: 'kyc_reject', module: 'kyc', details: 'Rejected KYC for Suresh Kumar — blurry document', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    AuditLog(id: 4, userId: 1, userName: 'Murari Varma', action: 'suspend', module: 'users', details: 'Suspended Kavita Reddy — fraud suspected', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
    AuditLog(id: 5, userId: 1, userName: 'Murari Varma', action: 'permission_change', module: 'roles', details: 'Removed finance.manage from Supervisor role', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 8)), beforeValue: 'finance.manage: true', afterValue: 'finance.manage: false'),
    AuditLog(id: 6, userId: 8, userName: 'Neha Gupta', action: 'login', module: 'auth', details: 'Support staff login', ipAddress: '172.20.10.5', userAgent: 'Edge 120 / Windows', timestamp: DateTime.now().subtract(const Duration(hours: 10))),
    AuditLog(id: 7, userId: 7, userName: 'Deepak Verma', action: 'kyc_approve', module: 'kyc', details: 'Approved KYC for Amit Patel', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(days: 1))),
    AuditLog(id: 8, userId: 1, userName: 'Murari Varma', action: 'create', module: 'users', details: 'Created new user account for Vikram Malhotra', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3))),
    AuditLog(id: 9, userId: 1, userName: 'Murari Varma', action: 'update', module: 'settings', details: 'Updated platform timezone to IST', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 2))),
    AuditLog(id: 10, userId: 7, userName: 'Deepak Verma', action: 'reactivate', module: 'users', details: 'Reactivated account for Suresh Kumar', ipAddress: '103.55.90.12', userAgent: 'Firefox 121 / Mac', timestamp: DateTime.now().subtract(const Duration(days: 3))),
    AuditLog(id: 11, userId: 1, userName: 'Murari Varma', action: 'delete', module: 'users', details: 'Deleted inactive test account', ipAddress: '192.168.1.100', userAgent: 'Chrome 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 4))),
    AuditLog(id: 12, userId: 8, userName: 'Neha Gupta', action: 'logout', module: 'auth', details: 'Support staff logout', ipAddress: '172.20.10.5', userAgent: 'Edge 120 / Windows', timestamp: DateTime.now().subtract(const Duration(days: 4, hours: 6))),
  ];

  Future<List<AuditLog>> getLogs({
    String? action,
    String? module,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var filtered = List<AuditLog>.from(_logs);

    if (action != null && action != 'all') {
      filtered = filtered.where((l) => l.action == action).toList();
    }
    if (module != null && module != 'all') {
      filtered = filtered.where((l) => l.module == module).toList();
    }
    if (userId != null) {
      filtered = filtered.where((l) => l.userId == userId).toList();
    }
    if (fromDate != null) {
      filtered = filtered.where((l) => l.timestamp.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      filtered = filtered.where((l) => l.timestamp.isBefore(toDate)).toList();
    }

    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  Future<List<String>> getActionTypes() async {
    return ['all', 'login', 'logout', 'create', 'update', 'delete', 'suspend', 'reactivate', 'kyc_approve', 'kyc_reject', 'permission_change'];
  }

  Future<List<String>> getModules() async {
    return ['all', 'auth', 'users', 'kyc', 'roles', 'settings', 'fleet', 'finance'];
  }
}
