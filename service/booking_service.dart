import '../models/booking.dart';
import '../models/rating.dart';
import 'database_helper.dart';
import 'booking_api_service.dart';
import 'rating_api_service.dart';
import '../viewmodels/request/bookingRequest.dart';
import '../viewmodels/request/ratingRequest.dart';
import '../viewmodels/response/bookingResponse.dart';
import '../viewmodels/response/ratingResponse.dart';

class BookingService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final BookingApiService _apiService = BookingApiService();
  final RatingApiService _ratingApiService = RatingApiService();
  
  String? _accessToken;
  int? _currentCustomerId;

  void setAuthToken(String? token) {
    _accessToken = token;
  }

  void setCurrentCustomerId(int? customerId) {
    _currentCustomerId = customerId;
  }

  // Convert API BookingResponse to local Booking model
  Booking _bookingResponseToBooking(BookingResponse response) {
    // Parse date and time
    final dateParts = response.bookingDate.split('-');
    final timeParts = response.startTime.split(':');
    final dateTime = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Get rating from ratings if available
    double? rating;
    if (response.ratings != null && response.ratings!.isNotEmpty) {
      rating = response.ratings!.first.ratingScore?.toDouble();
    }

    return Booking(
      id: response.bookingId.toString(),
      serviceName: response.package?.packageName ?? 'Service',
      category: response.package?.category?.categoryName ?? 'General',
      dateTime: dateTime,
      address: response.address,
      notes: response.note ?? '',
      status: response.status ?? 'pending',
      rating: rating,
      createdAt: response.createdAt != null ? DateTime.parse(response.createdAt!) : DateTime.now(),
      bookingId: response.bookingId,
      customerId: response.customerId,
      workerId: response.workerId,
      packageId: response.packageId,
    );
  }

  // Convert local Booking to API CreateBookingRequest
  CreateBookingRequest _bookingToCreateRequest(Booking booking, int packageId) {
    final dateStr = '${booking.dateTime.year}-${booking.dateTime.month.toString().padLeft(2, '0')}-${booking.dateTime.day.toString().padLeft(2, '0')}';
    final timeStr = '${booking.dateTime.hour.toString().padLeft(2, '0')}:${booking.dateTime.minute.toString().padLeft(2, '0')}:00';

    return CreateBookingRequest(
      customerId: booking.customerId ?? _currentCustomerId ?? 0,
      packageId: packageId,
      bookingDate: dateStr,
      startTime: timeStr,
      address: booking.address,
      note: booking.notes.isNotEmpty ? booking.notes : null,
    );
  }

  // Convert API RatingResponse to local Rating model
  Rating _ratingResponseToRating(RatingResponse response) {
    return Rating(
      id: response.ratingId.toString(),
      bookingId: response.bookingId.toString(),
      rating: response.ratingScore ?? 0,
      comment: response.comment,
      createdAt: response.createdAt != null ? DateTime.parse(response.createdAt!) : DateTime.now(),
    );
  }

  // Booking operations - Try API first, fallback to local DB
  Future<String> createBooking(Booking booking, {int? packageId}) async {
    try {
      // Try API first
      if (_currentCustomerId != null && packageId != null) {
        final request = _bookingToCreateRequest(booking, packageId);
        final response = await _apiService.createBooking(request, accessToken: _accessToken);
        final createdBooking = _bookingResponseToBooking(response);
        
        // Also save to local DB for offline access
        await _dbHelper.insertBooking(createdBooking);
        
        return createdBooking.id;
      } else {
        // Fallback to local DB if no customer ID or package ID
        return await _dbHelper.insertBooking(booking);
      }
    } catch (e) {
      // If API fails, save to local DB
      return await _dbHelper.insertBooking(booking);
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      // Try API first
      if (_currentCustomerId != null) {
        final responses = await _apiService.getBookingsByCustomerId(_currentCustomerId!, accessToken: _accessToken);
        final bookings = responses.map((r) => _bookingResponseToBooking(r)).toList();
        
        // Sync to local DB
        for (var booking in bookings) {
          try {
            await _dbHelper.insertBooking(booking);
          } catch (_) {
            // Ignore if already exists
          }
        }
        
        return bookings;
      } else {
        // Fallback to local DB
        return await _getAllBookingsFromLocal();
      }
    } catch (e) {
      // If API fails, use local DB
      return await _getAllBookingsFromLocal();
    }
  }

  Future<List<Booking>> _getAllBookingsFromLocal() async {
    final bookings = await _dbHelper.getAllBookings();
    final List<Booking> bookingsWithRatings = [];
    for (var booking in bookings) {
      final rating = await _dbHelper.getRatingByBookingId(booking.id);
      if (rating != null) {
        bookingsWithRatings.add(booking.copyWith(rating: rating.rating.toDouble()));
      } else {
        bookingsWithRatings.add(booking);
      }
    }
    return bookingsWithRatings;
  }

  Future<Booking?> getBooking(String id) async {
    try {
      // Try API first
      final bookingId = int.tryParse(id);
      if (bookingId != null) {
        final response = await _apiService.getBookingById(bookingId, accessToken: _accessToken);
        final booking = _bookingResponseToBooking(response);
        
        // Save to local DB
        await _dbHelper.insertBooking(booking);
        
        return booking;
      } else {
        // Fallback to local DB
        return await _dbHelper.getBooking(id);
      }
    } catch (e) {
      // If API fails, use local DB
      return await _dbHelper.getBooking(id);
    }
  }

  Future<bool> updateBooking(Booking booking) async {
    try {
      // Try API first
      if (booking.bookingId != null) {
        final dateStr = '${booking.dateTime.year}-${booking.dateTime.month.toString().padLeft(2, '0')}-${booking.dateTime.day.toString().padLeft(2, '0')}';
        final timeStr = '${booking.dateTime.hour.toString().padLeft(2, '0')}:${booking.dateTime.minute.toString().padLeft(2, '0')}:00';
        
        final request = UpdateBookingRequest(
          address: booking.address,
          note: booking.notes.isNotEmpty ? booking.notes : null,
          status: booking.status,
          bookingDate: dateStr,
          startTime: timeStr,
        );
        
        await _apiService.updateBooking(booking.bookingId!, request, accessToken: _accessToken);
      }
      
      // Also update local DB
      final result = await _dbHelper.updateBooking(booking);
      return result > 0;
    } catch (e) {
      // If API fails, just update local DB
      final result = await _dbHelper.updateBooking(booking);
      return result > 0;
    }
  }

  Future<bool> deleteBooking(String id) async {
    try {
      // Try API first
      final bookingId = int.tryParse(id);
      if (bookingId != null) {
        await _apiService.deleteBooking(bookingId, accessToken: _accessToken);
      }
      
      // Also delete from local DB
      final result = await _dbHelper.deleteBooking(id);
      return result > 0;
    } catch (e) {
      // If API fails, just delete from local DB
      final result = await _dbHelper.deleteBooking(id);
      return result > 0;
    }
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final allBookings = await getAllBookings();
    return allBookings.where((b) => b.status == status).toList();
  }

  // Rating operations - Try API first, fallback to local DB
  Future<String> createRating(Rating rating) async {
    try {
      // Try API first
      final bookingId = int.tryParse(rating.bookingId);
      if (bookingId != null && _currentCustomerId != null) {
        // We need workerId - try to get it from booking
        final booking = await getBooking(rating.bookingId);
        if (booking?.workerId != null) {
          final request = CreateRatingRequest(
            bookingId: bookingId,
            customerId: _currentCustomerId!,
            workerId: booking!.workerId!,
            ratingScore: rating.rating,
            comment: rating.comment,
          );
          
          final response = await _ratingApiService.createRating(request, accessToken: _accessToken);
          final createdRating = _ratingResponseToRating(response);
          
          // Also save to local DB
          await _dbHelper.insertRating(createdRating);
          
          return createdRating.id;
        }
      }
      
      // Fallback to local DB
      return await _dbHelper.insertRating(rating);
    } catch (e) {
      // If API fails, save to local DB
      return await _dbHelper.insertRating(rating);
    }
  }

  Future<Rating?> getRatingByBookingId(String bookingId) async {
    try {
      // Try API first
      final id = int.tryParse(bookingId);
      if (id != null) {
        final response = await _ratingApiService.getRatingByBookingId(id, accessToken: _accessToken);
        if (response != null) {
          final rating = _ratingResponseToRating(response);
          
          // Save to local DB
          await _dbHelper.insertRating(rating);
          
          return rating;
        }
        return null;
      } else {
        // Fallback to local DB
        return await _dbHelper.getRatingByBookingId(bookingId);
      }
    } catch (e) {
      // If API fails, use local DB
      return await _dbHelper.getRatingByBookingId(bookingId);
    }
  }

  Future<List<Rating>> getAllRatings() async {
    try {
      // Try API first
      if (_currentCustomerId != null) {
        final responses = await _ratingApiService.getRatingsByCustomerId(_currentCustomerId!, accessToken: _accessToken);
        final ratings = responses.map((r) => _ratingResponseToRating(r)).toList();
        
        // Sync to local DB
        for (var rating in ratings) {
          try {
            await _dbHelper.insertRating(rating);
          } catch (_) {
            // Ignore if already exists
          }
        }
        
        return ratings;
      } else {
        // Fallback to local DB
        return await _dbHelper.getAllRatings();
      }
    } catch (e) {
      // If API fails, use local DB
      return await _dbHelper.getAllRatings();
    }
  }

  Future<bool> updateRating(Rating rating) async {
    try {
      // Try API first
      final ratingId = int.tryParse(rating.id);
      if (ratingId != null) {
        final request = UpdateRatingRequest(
          ratingScore: rating.rating,
          comment: rating.comment,
        );
        
        await _ratingApiService.updateRating(ratingId, request, accessToken: _accessToken);
      }
      
      // Also update local DB
      final result = await _dbHelper.updateRating(rating);
      return result > 0;
    } catch (e) {
      // If API fails, just update local DB
      final result = await _dbHelper.updateRating(rating);
      return result > 0;
    }
  }

  Future<bool> deleteRating(String id) async {
    try {
      // Try API first
      final ratingId = int.tryParse(id);
      if (ratingId != null) {
        await _ratingApiService.deleteRating(ratingId, accessToken: _accessToken);
      }
      
      // Also delete from local DB
      final result = await _dbHelper.deleteRating(id);
      return result > 0;
    } catch (e) {
      // If API fails, just delete from local DB
      final result = await _dbHelper.deleteRating(id);
      return result > 0;
    }
  }
}
