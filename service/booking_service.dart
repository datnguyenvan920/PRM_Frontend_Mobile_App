import '../models/booking.dart';
import '../models/rating.dart';
import 'database_helper.dart';

class BookingService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Booking operations
  Future<String> createBooking(Booking booking) async {
    return await _dbHelper.insertBooking(booking);
  }

  Future<List<Booking>> getAllBookings() async {
    final bookings = await _dbHelper.getAllBookings();
    // Load ratings for each booking
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
    final booking = await _dbHelper.getBooking(id);
    if (booking != null) {
      final rating = await _dbHelper.getRatingByBookingId(booking.id);
      if (rating != null) {
        return booking.copyWith(rating: rating.rating.toDouble());
      }
    }
    return booking;
  }

  Future<bool> updateBooking(Booking booking) async {
    final result = await _dbHelper.updateBooking(booking);
    return result > 0;
  }

  Future<bool> deleteBooking(String id) async {
    final result = await _dbHelper.deleteBooking(id);
    return result > 0;
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final allBookings = await getAllBookings();
    return allBookings.where((b) => b.status == status).toList();
  }

  // Rating operations
  Future<String> createRating(Rating rating) async {
    return await _dbHelper.insertRating(rating);
  }

  Future<Rating?> getRatingByBookingId(String bookingId) async {
    return await _dbHelper.getRatingByBookingId(bookingId);
  }

  Future<List<Rating>> getAllRatings() async {
    return await _dbHelper.getAllRatings();
  }

  Future<bool> updateRating(Rating rating) async {
    final result = await _dbHelper.updateRating(rating);
    return result > 0;
  }

  Future<bool> deleteRating(String id) async {
    final result = await _dbHelper.deleteRating(id);
    return result > 0;
  }
}
