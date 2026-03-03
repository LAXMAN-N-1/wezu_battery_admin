import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserModel?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockUser = UserModel(
        id: 'ADMIN-001',
        name: 'Admin User',
        email: 'admin@powerfill.com',
        phone: '+1 234 567 890',
        registrationDate: DateTime.now().subtract(const Duration(days: 365)),
        kycStatus: KycStatus.approved,
        accountStatus: AccountStatus.active,
        lastActive: DateTime.now(),
        walletBalance: 0.0,
        totalSwaps: 0,
        profilePhotoUrl: null,
      );

      state = AsyncValue.data(mockUser);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
