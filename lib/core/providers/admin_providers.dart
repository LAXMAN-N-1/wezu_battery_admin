import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/rentals/data/repositories/rental_repository.dart';
import '../../features/rentals/data/models/rental_model.dart';

final rentalRepositoryProvider = Provider((ref) => RentalRepository());

final adminRentalsProvider = FutureProvider<List<Rental>>((ref) async {
  final repository = ref.watch(rentalRepositoryProvider);
  return repository.getActiveRentals();
});
