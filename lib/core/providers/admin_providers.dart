import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rentals/data/models/rental_model.dart';
import 'repository_providers.dart';

final adminRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  final repository = ref.watch(rentalRepositoryProvider);
  return repository.getActiveRentals();
});
