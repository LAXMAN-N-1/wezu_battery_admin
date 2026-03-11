import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_admin/core/api/api_client.dart';
import 'blog_repository.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.read(apiClientProvider));
});
