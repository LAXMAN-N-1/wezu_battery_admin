import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/models/kyc_model.dart';
import '../../../core/models/user_model.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository();
});

class KycRepository {
  final List<KycRequest> _mockQueue = [];

  KycRepository() {
    _generateMockQueue();
  }

  void _generateMockQueue() {
    final random = Random();
    final names = ['Sarah Connor', 'John Wick', 'Ellen Ripley', 'Tony Stark', 'Bruce Wayne', 'Clark Kent', 'Diana Prince', 'Peter Parker', 'Natasha Romanoff', 'Steve Rogers'];
    
    for (int i = 0; i < 50; i++) {
      final name = names[random.nextInt(names.length)];
      final isPending = random.nextDouble() > 0.3; // 70% pending
      
      _mockQueue.add(KycRequest(
        id: 'KYC-${5000 + i}',
        userId: 'USR-${1000 + i}',
        userName: '$name ${i + 1}',
        userPhone: '+91 98765 ${10000 + i}',
        documentType: DocumentType.values[random.nextInt(DocumentType.values.length)],
        submittedAt: DateTime.now().subtract(Duration(hours: random.nextInt(48))),
        status: isPending ? KycStatus.pending : (random.nextBool() ? KycStatus.approved : KycStatus.rejected),
        documentUrls: [
          'https://placehold.co/600x400/png?text=Front+Side',
          if (random.nextBool()) 'https://placehold.co/600x400/png?text=Back+Side',
        ],
        rejectionReason: !isPending && random.nextBool() ? 'Clear image required' : null,
        verifierName: !isPending ? 'Admin User' : null,
        verifiedAt: !isPending ? DateTime.now().subtract(Duration(hours: random.nextInt(5))) : null,
      ));
    }
    
    // ensure sorted by date desc
    _mockQueue.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  Future<List<KycRequest>> fetchQueue({KycStatus status = KycStatus.pending}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockQueue.where((r) => r.status == status).toList();
  }

  Future<Map<String, dynamic>> fetchAnalytics() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final pending = _mockQueue.where((r) => r.status == KycStatus.pending).length;
    final approvedToday = _mockQueue.where((r) => r.status == KycStatus.approved && r.verifiedAt != null && r.verifiedAt!.isAfter(todayStart)).length;
    final rejectedToday = _mockQueue.where((r) => r.status == KycStatus.rejected && r.verifiedAt != null && r.verifiedAt!.isAfter(todayStart)).length;
    
    return {
      'pending': pending,
      'approved_today': approvedToday,
      'rejected_today': rejectedToday,
      'avg_time': '12m', // Mock value
    };
  }

  Future<void> approveKyc(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockQueue.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _mockQueue[index];
      _mockQueue[index] = KycRequest(
        id: req.id,
        userId: req.userId,
        userName: req.userName,
        userPhone: req.userPhone,
        documentType: req.documentType,
        submittedAt: req.submittedAt,
        status: KycStatus.approved,
        documentUrls: req.documentUrls,
        verifierName: 'You',
        verifiedAt: DateTime.now(),
      );
    }
  }

  Future<void> rejectKyc(String id, String reason) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockQueue.indexWhere((r) => r.id == id);
    if (index != -1) {
      final req = _mockQueue[index];
      _mockQueue[index] = KycRequest(
        id: req.id,
        userId: req.userId,
        userName: req.userName,
        userPhone: req.userPhone,
        documentType: req.documentType,
        submittedAt: req.submittedAt,
        status: KycStatus.rejected,
        documentUrls: req.documentUrls,
        rejectionReason: reason,
        verifierName: 'You',
        verifiedAt: DateTime.now(),
      );
    }
  }
}
