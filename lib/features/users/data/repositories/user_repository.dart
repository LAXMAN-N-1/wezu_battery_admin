import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/user.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(apiClientProvider));
});

class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  Future<List<User>> getUsers() async {
    final response = await _apiClient.get('/api/v1/admin/main/users/');
    
    // The backend returns a UserSearchResponse object with a 'users' list
    if (response.data is Map && response.data['users'] != null) {
      final List data = response.data['users'];
      return data.map((e) => User.fromJson(e)).toList();
    }
    
    // Fallback if structure is different
    if (response.data is List) {
      return (response.data as List).map((e) => User.fromJson(e)).toList();
    }
    
    return [];
  }
}
