import 'package:flutter/material.dart';
import '../../service/auth_helper.dart';
import '../../service/booking_api_service.dart';
import '../../service/rating_api_service.dart';
import '../../viewmodels/request/paginationRequest.dart';
import '../../viewmodels/request/ratingRequest.dart';
import '../../viewmodels/request/bookingRequest.dart'; 
import '../../viewmodels/response/bookingResponse.dart';
import '../../viewmodels/response/ratingResponse.dart';
import '../../widgets/rating_bar.dart';
import '../../screen/rating/rating_dialog.dart';
import '../general/customer_home.dart';
import '../general/worker_home.dart';
import '../general/profile_screen.dart';
import 'create_booking_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final BookingApiService _apiService = BookingApiService();
  final RatingApiService _ratingApiService = RatingApiService();
  final AuthHelper _authHelper = AuthHelper.instance;

  int _selectedIndex = 1;
  String? _accessToken;
  int? _currentCustomerId;

  List<BookingResponse> _bookings = [];
  Map<int, RatingResponse?> _ratedBookings = {}; 
  bool _isLoading = true;
  String _selectedFilter = 'all';
  int _currentPage = 1;
  bool _hasNextPage = false;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _accessToken = await _authHelper.getAccessToken();
    _currentCustomerId = await _authHelper.getCurrentCustomerId();
    _loadBookings();
  }

  void _onItemTapped(int index) async {
    if (index == _selectedIndex) return;
    
    if (index == 0) {
      final workerId = await _authHelper.getCurrentWorkerId();
      if (mounted) {
        if (workerId != null) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkerHomeScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CustomerHomeScreen()));
        }
      }
    } else if (index == 2) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  Future<void> _loadBookings({int page = 1}) async {
    if (_currentCustomerId == null) return;

    setState(() {
      if (page == 1) _isLoading = true;
      _currentPage = page;
    });

    try {
      final paginationRequest = PaginationRequest(pageNumber: _currentPage, pageSize: _pageSize);
      final response = await _apiService.getBookingsByCustomerId(
          _currentCustomerId!,
          paginationRequest,
          accessToken: _accessToken
      );

      final ratingsList = await _ratingApiService.getRatingsByCustomerId(_currentCustomerId!, accessToken: _accessToken);
      final Map<int, RatingResponse?> ratingsMap = {for (var r in ratingsList) r.bookingId: r};

      setState(() {
        if (page == 1) {
          _bookings = response.items;
          _ratedBookings = ratingsMap;
        } else {
          _bookings.addAll(response.items);
          _ratedBookings.addAll(ratingsMap);
        }
        _hasNextPage = response.currentPage < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  List<BookingResponse> get _filteredBookings {
    if (_selectedFilter == 'all') {
      return _bookings.where((b) {
        final status = (b.status ?? '').toLowerCase();
        return status != 'completed' && status != 'cancelled';
      }).toList();
    }
    return _bookings.where((b) => (b.status ?? '').toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  void _openNewBookingForm() async {
    final bookingCreated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateBookingScreen(),
      ),
    );

    if (bookingCreated == true) {
      _loadBookings();
    }
  }

  void _showWorkerInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow modal to adjust to height
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24.0),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7), // Cap height
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const CircleAvatar(
                radius: 40, // Slightly smaller
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=worker1'),
              ),
              const SizedBox(height: 16),
              const Text('Trần Văn Thợ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Text('(5.0)', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 32),
              _buildWorkerInfoItem(Icons.email, 'tho1@homeservice.vn', 'Email', Colors.blue[50]!, Colors.blueAccent),
              const SizedBox(height: 16),
              _buildWorkerInfoItem(Icons.phone, '0911111111', 'Phone Number', Colors.green[50]!, Colors.green),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerInfoItem(IconData icon, String title, String subtitle, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancelBooking(BookingResponse booking) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.cancelBooking(booking.bookingId, accessToken: _accessToken);
        _loadBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled successfully'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _handleCompleteBooking(BookingResponse booking) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final paymentInfo = await _apiService.getPaymentAmount(booking.bookingId, accessToken: _accessToken);
      if (mounted) Navigator.pop(context); // Remove loading

      final String qrUrl = "https://img.vietqr.io/image/TPB-00000104256-compact.png?amount=${paymentInfo.amount.toInt()}&addInfo=${Uri.encodeComponent(paymentInfo.transactionCode)}";

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Required', textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Scan the QR code to pay'),
                const SizedBox(height: 16),
                Image.network(qrUrl, loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }),
                const SizedBox(height: 16),
                Text('Amount: ${paymentInfo.amount.toInt()} VNĐ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Code: ${paymentInfo.transactionCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _apiService.createPayment(
                      CreatePaymentRequest(
                        bookingId: booking.bookingId,
                        paymentMethod: 'bank_transfer',
                        transactionCode: paymentInfo.transactionCode,
                      ),
                      accessToken: _accessToken,
                    );
                    await _apiService.updateBookingStatus(booking.bookingId, 'completed', accessToken: _accessToken);
                    if (mounted) {
                      Navigator.pop(context); // Close QR dialog
                      _loadBookings(); // Refresh list
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment and Booking completed successfully!'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Finish', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openRatingDialog(BookingResponse booking) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(booking: booking),
    );

    if (result == true) {
      _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(BookingResponse booking, String newStatus) async {
    try {
      await _apiService.updateBookingStatus(booking.bookingId, newStatus, accessToken: _accessToken);
      _loadBookings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryFromPackageName(String? packageName) {
    if (packageName == null) return 'Service';
    final parts = packageName.split('-');
    if (parts.length > 1) {
      return parts.sublist(1).join('-'); 
    }
    return 'Service';
  }

  String _getPackageLabel(String? packageName) {
    if (packageName == null) return 'General';
    final parts = packageName.split('-');
    if (parts.isNotEmpty) {
      final id = parts[0];
      switch (id) {
        case '1': return '1 - 50k';
        case '2': return '2 - 100k';
        case '3': return '3 - 200k';
        case '4': return '4 - 500k';
        case '5': return '5 - Deal';
        default: return id;
      }
    }
    return 'General';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'confirmed', child: Text('Confirmed')),
              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredBookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No bookings yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredBookings.length + (_hasNextPage ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == _filteredBookings.length) {
                        return Center(
                          child: TextButton(
                            onPressed: () => _loadBookings(page: _currentPage + 1),
                            child: const Text('Load More'),
                          ),
                        );
                      }

                      final booking = _filteredBookings[index];
                      final categoryName = _getCategoryFromPackageName(booking.packageName);
                      final packageLabel = _getPackageLabel(booking.packageName);
                      final String status = (booking.status ?? '').toLowerCase();
                      final RatingResponse? existingRating = _ratedBookings[booking.bookingId];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getStatusColor(status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (['confirmed', 'in_progress', 'completed'].contains(status))
                                        TextButton.icon(
                                          onPressed: _showWorkerInfo,
                                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                          icon: const Icon(Icons.engineering, size: 14),
                                          label: const Text('Worker Info', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  packageLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${booking.bookingDate} ${booking.startTime.substring(0, 5)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 2),
                                    child: Icon(Icons.location_on, size: 18, color: Colors.black54),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      booking.address,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (booking.note != null && booking.note!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  booking.note!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              if (status == 'completed') ...[
                                const Divider(),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              'Rating: ',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                            RatingBar(
                                              rating: existingRating?.ratingScore?.toDouble(), 
                                              onRatingSelected: null,
                                              iconSize: 20,
                                            ),
                                            if (existingRating == null)
                                              TextButton(
                                                onPressed: () => _openRatingDialog(booking),
                                                child: const Text('Rate now'),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (existingRating != null && existingRating.comment != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your comment: ${existingRating.comment}',
                                        style: TextStyle(fontSize: 13, color: Colors.grey[700], fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status == 'in_progress')
                                    TextButton(
                                      onPressed: () => _handleCompleteBooking(booking),
                                      child: const Text('Complete', style: TextStyle(color: Color(0xFF5C6BC0), fontWeight: FontWeight.bold)),
                                    ),
                                  TextButton(
                                    onPressed: (status == 'pending') ? () => _handleCancelBooking(booking) : null,
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: (status == 'pending') ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewBookingForm,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
