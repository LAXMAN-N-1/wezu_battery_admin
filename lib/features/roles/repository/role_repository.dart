import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/role_model.dart';

final roleRepositoryProvider = Provider<RoleRepository>((ref) {
  return RoleRepository();
});

class RoleRepository {
  final List<RoleModel> _mockRoles = [
    RoleModel(
      id: 'admin',
      name: 'Administrator',
      description: 'Full access to all modules and settings.',
      permissions: ['all'],
      userCount: 3,
    ),
    RoleModel(
      id: 'manager',
      name: 'Station Manager',
      description: 'Can manage stations, batteries, and view reports.',
      permissions: ['stations.read', 'stations.write', 'batteries.read', 'batteries.write', 'reports.read'],
      userCount: 8,
    ),
    RoleModel(
      id: 'support',
      name: 'Customer Support',
      description: 'Can view user details and manage tickets.',
      permissions: ['users.read', 'tickets.read', 'tickets.write'],
      userCount: 12,
    ),
    RoleModel(
      id: 'auditor',
      name: 'Auditor',
      description: 'Read-only access to all financial and operational data.',
      permissions: ['*.read'],
      userCount: 2,
    ),
  ];

  Future<List<RoleModel>> fetchRoles() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockRoles;
  }
}
