import '../../../../core/api/api_client.dart';
import '../models/rental_model.dart';
import '../models/swap_model.dart';
import '../models/purchase_model.dart';
import '../models/late_fee_model.dart';

class RentalRepository {
  final ApiClient _api = ApiClient();

  Future<RentalStats> getRentalStats() async {
    try {
      final response = await _api.get('/api/v1/admin/rentals/stats');
      return RentalStats.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Rental>> getActiveRentals({int skip = 0, int limit = 100}) async {
    try {
      final response = await _api.get('/api/v1/admin/rentals/active', queryParameters: {'skip': skip.toString(), 'limit': limit.toString()});
      return (response.data as List).map((r) => Rental.fromJson(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Rental>> getRentalHistory({int skip = 0, int limit = 50, String? search}) async {
    final Map<String, dynamic> params = {'skip': skip.toString(), 'limit': limit.toString()};
    if (search != null) params['search'] = search;
    try {
      final response = await _api.get('/api/v1/admin/rentals/history', queryParameters: params);
      return (response.data as List).map((r) => Rental.fromJson(r)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SwapSession>> getSwaps({int skip = 0, int limit = 100}) async {
    try {
      final response = await _api.get('/api/v1/admin/rentals/swaps', queryParameters: {'skip': skip.toString(), 'limit': limit.toString()});
      return (response.data as List).map((s) => SwapSession.fromJson(s)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PurchaseOrder>> getPurchases({int skip = 0, int limit = 100}) async {
    try {
      final response = await _api.get('/api/v1/admin/rentals/purchases', queryParameters: {'skip': skip.toString(), 'limit': limit.toString()});
      return (response.data as List).map((p) => PurchaseOrder.fromJson(p)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LateFee>> getLateFees() async {
    try {
      final response = await _api.get('/api/v1/admin/rentals/late-fees');
      return (response.data as List).map((l) => LateFee.fromJson(l)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> reviewWaiver(int waiverId, String status, {double? approvedAmount, String? notes}) async {
    try {
      final Map<String, dynamic> data = {'status': status};
      if (approvedAmount != null) data['approved_amount'] = approvedAmount;
      if (notes != null) data['admin_notes'] = notes;
      
      await _api.put('/api/v1/admin/rentals/late-fees/waivers/$waiverId/review', data: data);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> terminateRental(int rentalId, String reason) async {
    try {
      await _api.put('/api/v1/admin/rentals/$rentalId/terminate', queryParameters: {'reason': reason});
      return true;
    } catch (e) {
      rethrow;
    }
  }
}
