import '../models/station.dart';

class StationRepository {
  Future<List<Station>> getStations() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Seeded data in Hyderabad
    return [
      Station(
        id: 1,
        name: 'Wezu Station - Hitech City',
        address: 'Cyber Towers, Hitech City, Hyderabad',
        latitude: 17.4435,
        longitude: 78.3772,
        status: 'active',
        totalSlots: 12,
        availableBatteries: 8,
        emptySlots: 4,
        lastPing: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
      Station(
        id: 2,
        name: 'Wezu Station - Gachibowli',
        address: 'Near ORR, Gachibowli, Hyderabad',
        latitude: 17.4401,
        longitude: 78.3489,
        status: 'active',
        totalSlots: 10,
        availableBatteries: 5,
        emptySlots: 5,
        lastPing: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Station(
        id: 3,
        name: 'Wezu Station - Madhapur',
        address: 'Metro Station, Madhapur, Hyderabad',
        latitude: 17.4399,
        longitude: 78.3982,
        status: 'maintenance',
        totalSlots: 8,
        availableBatteries: 0,
        emptySlots: 0,
        lastPing: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Station(
        id: 4,
        name: 'Wezu Station - Jubilee Hills',
        address: 'Road No 36, Jubilee Hills, Hyderabad',
        latitude: 17.4326,
        longitude: 78.4071,
        status: 'active',
        totalSlots: 15,
        availableBatteries: 12,
        emptySlots: 3,
        lastPing: DateTime.now().subtract(const Duration(seconds: 30)),
      ),
      Station(
        id: 5,
        name: 'Wezu Station - Kondapur',
        address: 'Botanical Garden Rd, Kondapur',
        latitude: 17.4622,
        longitude: 78.3568,
        status: 'inactive',
        totalSlots: 6,
        availableBatteries: 0,
        emptySlots: 6,
        lastPing: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];
  }
}
