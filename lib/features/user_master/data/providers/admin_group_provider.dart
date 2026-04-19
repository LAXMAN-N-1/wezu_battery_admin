import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/admin_group_repository.dart';
import '../models/admin_group_model.dart';

final adminGroupRepositoryProvider = Provider<AdminGroupRepository>((ref) {
  return AdminGroupRepository();
});

final adminGroupsProvider = FutureProvider.autoDispose<List<AdminGroupModel>>((ref) async {
  final repo = ref.watch(adminGroupRepositoryProvider);
  return repo.getGroups();
});
