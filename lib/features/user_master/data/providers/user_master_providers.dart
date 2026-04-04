import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_master_repository.dart';
import '../models/role.dart';
import '../models/access_log.dart';

// --- Repositories ---
final userMasterRepositoryProvider = Provider<UserMasterRepository>((ref) {
  return UserMasterRepository();
});

// --- User Providers ---
final usersProvider = FutureProvider.family<Map<String, dynamic>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  return repo.getUsers(
    search: params['search'] as String?,
    role: params['role'] as String?,
    status: params['status'] as String?,
    skip: params['skip'] as int? ?? 0,
    limit: params['limit'] as int? ?? 20,
  );
});

// Stable-key version: prevents infinite re-fetch caused by Map identity changing on every widget rebuild
final usersProviderByKey = FutureProvider.family<Map<String, dynamic>, String>((ref, queryKey) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  final uri = Uri(query: queryKey);
  final params = uri.queryParameters;
  return repo.getUsers(
    search: (params['search'] ?? '').isEmpty ? null : params['search'],
    role: (params['role'] ?? '').isEmpty ? null : params['role'],
    status: (params['status'] ?? '').isEmpty ? null : params['status'],
    skip: int.tryParse(params['skip'] ?? '0') ?? 0,
    limit: int.tryParse(params['limit'] ?? '20') ?? 20,
  );
});

final userSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  return repo.getUserSummary();
});

// --- Role Providers ---
final rolesProvider = FutureProvider<List<Role>>((ref) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  return repo.getRoles();
});

// --- Permission Providers ---
final permissionModulesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  return repo.getPermissionModules();
});

// --- Access Logs Provider ---
final accessLogsProvider = FutureProvider.family<List<AccessLog>, Map<String, dynamic>>((ref, params) async {
  final repo = ref.watch(userMasterRepositoryProvider);
  return repo.getAccessLogs(
    skip: params['skip'] as int? ?? 0,
    limit: params['limit'] as int? ?? 50,
  );
});
