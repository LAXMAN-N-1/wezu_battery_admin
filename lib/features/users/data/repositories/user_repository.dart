import '../models/user.dart';

class UserRepository {
  Future<List<User>> getUsers() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate API

    return [
      User(
        id: 1,
        fullName: 'Murari Varma',
        email: 'murari@wezu.com',
        phoneNumber: '+919876543210',
        role: 'admin',
        kycStatus: 'verified',
        isActive: true,
        joinedAt: DateTime(2025, 1, 1),
        lastActive: DateTime.now(),
      ),
      User(
        id: 2,
        fullName: 'Rahul Sharma',
        email: 'rahul.driver@gmail.com',
        phoneNumber: '+919876500001',
        role: 'driver',
        kycStatus: 'pending', // Needs attention
        isActive: true,
        joinedAt: DateTime(2025, 2, 10),
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      User(
        id: 3,
        fullName: 'Green Energy Dealers',
        email: 'contact@greendealers.in',
        phoneNumber: '+919876500002',
        role: 'dealer',
        kycStatus: 'verified',
        isActive: true,
        joinedAt: DateTime(2025, 1, 15),
        lastActive: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      User(
        id: 4,
        fullName: 'Priya Singh',
        email: 'priya.s@outlook.com',
        phoneNumber: '+919876500003',
        role: 'customer',
        kycStatus: 'not_submitted',
        isActive: true,
        joinedAt: DateTime(2025, 2, 18),
        lastActive: DateTime.now().subtract(const Duration(days: 1)),
      ),
      User(
        id: 5,
        fullName: 'Suresh Kumar',
        email: 'suresh.k@gmail.com',
        phoneNumber: '+919876500004',
        role: 'driver',
        kycStatus: 'rejected',
        isActive: false,
        joinedAt: DateTime(2025, 2, 5),
        lastActive: DateTime.now().subtract(const Duration(days: 5)),
      ),
       User(
        id: 6,
        fullName: 'Amit Patel',
        email: 'amit.p@gmail.com',
        phoneNumber: '+919876500005',
        role: 'customer',
        kycStatus: 'verified',
        isActive: true,
        joinedAt: DateTime(2025, 2, 1),
        lastActive: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
