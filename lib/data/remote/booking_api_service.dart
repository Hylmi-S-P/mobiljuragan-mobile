import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

/// Layanan API pemesanan kendaraan (Booking) ke backend MobilJuragan
class BookingApiService {
  final ApiClient _client;

  BookingApiService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Mengirim pemesanan sewa baru ke backend REST API (POST /api/v1/bookings)
  Future<Map<String, dynamic>> createBooking({
    required String vehicleId,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool withDriver,
    String? pickupLocation,
    String? customerRequest,
    int? numberGuests,
  }) async {
    final response = await _client.post(
      ApiConstants.bookingsEndpoint,
      requiresAuth: true,
      body: {
        'vehicleId': vehicleId,
        'startDateTime': startDateTime.toUtc().toIso8601String(),
        'endDateTime': endDateTime.toUtc().toIso8601String(),
        'rentalType': withDriver ? 'WITH_DRIVER' : 'WITHOUT_DRIVER',
        if (pickupLocation != null && pickupLocation.isNotEmpty)
          'pickupLocation': pickupLocation,
        if (customerRequest != null && customerRequest.isNotEmpty)
          'customerRequest': customerRequest,
        if (numberGuests != null && numberGuests > 0)
          'numberGuests': numberGuests,
      },
    );

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  /// Mengambil riwayat pemesanan pelanggan dari backend (GET /api/v1/bookings)
  Future<List<dynamic>> fetchBookings() async {
    final response = await _client.get(
      ApiConstants.bookingsEndpoint,
      requiresAuth: true,
    );

    if (response is List) {
      return response;
    }
    return [];
  }
}
