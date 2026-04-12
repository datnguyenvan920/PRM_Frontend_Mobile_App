import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../service/booking_api_service.dart';
import '../../service/homeService.dart';
import '../../service/auth_helper.dart';
import '../../viewmodels/request/bookingRequest.dart';
import '../../viewmodels/request/paginationRequest.dart';
import '../../viewmodels/response/homeResponse.dart';

class ServicePackage {
  final String id;
  final String label;
  final double price;

  ServicePackage({required this.id, required this.label, required this.price});
}

class CreateBookingScreen extends StatefulWidget {
  final ServiceCategoryDto? initialCategory;

  const CreateBookingScreen({Key? key, this.initialCategory}) : super(key: key);

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  
  // Services
  final BookingApiService _apiService = BookingApiService();
  final HomeService _homeService = HomeService();
  final AuthHelper _authHelper = AuthHelper.instance;

  // Data
  List<ServiceCategoryDto> _categories = [];
  ServiceCategoryDto? _selectedCategory;
  bool _isLoadingCategories = true;

  final List<ServicePackage> _packages = [
    ServicePackage(id: '1', label: 'Basic Package', price: 50000),
    ServicePackage(id: '2', label: 'Standard Package', price: 100000),
    ServicePackage(id: '3', label: 'Premium Package', price: 200000),
    ServicePackage(id: '4', label: 'Full Service', price: 500000),
    ServicePackage(id: '5', label: 'Custom Deal', price: 0),
  ];
  ServicePackage? _selectedPackage;

  // Step 3 state
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  String _currentAddress = "Tap map to pick location";
  bool _isLocating = true;
  bool _isSearching = false;
  bool _isSubmitting = false;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory;
      _currentStep = 2;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final token = await _authHelper.getAccessToken();
      if (token == null) return;
      final homeData = await _homeService.getCustomerHome(token, PaginationRequest(pageSize: 50));
      if (mounted) {
        setState(() {
          _categories = homeData.categories.items;
          _isLoadingCategories = false;
          
          // If we have an initial category, try to find the matching one from the loaded list to ensure proper state
          if (_selectedCategory != null) {
             try {
               _selectedCategory = _categories.firstWhere((c) => c.categoryId == _selectedCategory!.categoryId);
             } catch (_) {}
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- Step 3 Logic ---
  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() { _currentAddress = "Location services disabled"; _isLocating = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() { _currentAddress = "Permission denied"; _isLocating = false; });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _currentAddress = "Permissions permanently denied"; _isLocating = false; });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng userLatLng = LatLng(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = userLatLng;
          _isLocating = false;
        });
        _mapController.move(userLatLng, 15.0);
        _getAddressFromLatLng(userLatLng);
      }
    } catch (e) {
      if (mounted) setState(() {
        _isLocating = false;
        if (_currentPosition == null) {
          _currentPosition = const LatLng(21.0285, 105.8542); // Fallback to Hanoi
          _mapController.move(_currentPosition!, 15.0);
        }
      });
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;
    setState(() => _isSearching = true);
    
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=1');
    
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'HomeServiceApp/1.0' 
      });

      if (response.statusCode == 200 && mounted) {
        final List data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final LatLng newPos = LatLng(lat, lon);
          
          setState(() {
            _currentPosition = newPos;
            _currentAddress = data[0]['display_name'];
            _isSearching = false;
          });
          _mapController.move(newPos, 15.0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location not found')),
          );
          setState(() => _isSearching = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18');
    try {
      final response = await http.get(url, headers: {'User-Agent': 'HomeServiceApp/1.0'});
      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        setState(() {
          _currentAddress = data['display_name'] ?? "Unknown address";
          _searchController.text = _currentAddress;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDateTime, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDateTime));
    if (time == null) return;
    setState(() => _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submitBooking() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a location')));
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final token = await _authHelper.getAccessToken();
      final customerId = await _authHelper.getCurrentCustomerId();
      final dateStr = '${_selectedDateTime.year}-${_selectedDateTime.month.toString().padLeft(2, '0')}-${_selectedDateTime.day.toString().padLeft(2, '0')}';
      final timeStr = '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}:00';
      final packageIdStr = "${_selectedPackage!.id}-${_selectedCategory!.categoryName}";

      final request = CreateBookingRequest(
        customerId: customerId!,
        workerId: 6, // Default worker
        packageId: packageIdStr,
        bookingDate: dateStr,
        startTime: timeStr,
        address: _currentAddress,
        note: _notesController.text.trim(),
        totalPrice: _selectedPackage!.price > 0 ? _selectedPackage!.price : null,
      );

      await _apiService.createBooking(request, accessToken: token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Successful!'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // --- UI Steps ---
  Widget _buildStep1() {
    return _isLoadingCategories
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory?.categoryId == cat.categoryId;
              return GestureDetector(
                onTap: () => setState(() { _selectedCategory = cat; _currentStep = 2; }),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey[200]!, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.08), shape: BoxShape.circle),
                        child: (cat.imageUrl != null)
                            ? Image.network(cat.imageUrl!, width: 48, height: 48, errorBuilder: (_, __, ___) => const Icon(Icons.cleaning_services, size: 40))
                            : const Icon(Icons.cleaning_services, size: 40, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 12),
                      Text(cat.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            },
          );
  }

  Widget _buildStep2() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pkg = _packages[index];
        final isSelected = _selectedPackage?.id == pkg.id;
        return ListTile(
          onTap: () => setState(() { _selectedPackage = pkg; _currentStep = 3; _determinePosition(); }),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey[300]!, width: 2)),
          tileColor: isSelected ? Colors.blue[50] : Colors.white,
          leading: Icon(Icons.stars, color: isSelected ? Colors.blueAccent : Colors.grey),
          title: Text(pkg.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(pkg.price > 0 ? '${pkg.price.toInt()} VNĐ' : 'Deal', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pick your Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for address...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                suffixIcon: _isSearching 
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear()),
              ),
              onSubmitted: _searchLocation,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentPosition ?? const LatLng(21.0285, 105.8542),
                      initialZoom: 15,
                      onPositionChanged: (pos, hasGesture) { if (hasGesture && pos.center != null) _currentPosition = pos.center!; },
                      onMapEvent: (e) { if (e is MapEventMoveEnd && _currentPosition != null) _getAddressFromLatLng(_currentPosition!); },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.projectprm.app',
                      ),
                      if (_currentPosition != null) MarkerLayer(markers: [Marker(point: _currentPosition!, child: const Icon(Icons.location_pin, color: Colors.red, size: 40))]),
                    ],
                  ),
                ),
                if (_isLocating)
                  Container(
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                // Floating Controls
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: "location_btn",
                        mini: true,
                        onPressed: _determinePosition,
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.my_location, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoom_in_btn",
                        mini: true,
                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.add, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: "zoom_out_btn",
                        mini: true,
                        onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.remove, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_currentAddress, style: const TextStyle(fontSize: 13, color: Colors.blueAccent))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [const Icon(Icons.calendar_today), const SizedBox(width: 12), Text('${_selectedDateTime.day}/${_selectedDateTime.month} at ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}')]),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          TextField(controller: _notesController, maxLines: 3, decoration: InputDecoration(hintText: 'Any special instructions...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _isSubmitting ? null : _submitBooking, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String title = "Step 1: Choose Service";
    if (_currentStep == 2) title = "Step 2: Choose Price";
    if (_currentStep == 3) title = "Step 3: Location & Time";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: _currentStep > 1 ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _currentStep--)) : const CloseButton(),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _currentStep / 3, backgroundColor: Colors.grey[200], color: Colors.blueAccent),
          Expanded(
            child: IndexedStack(
              index: _currentStep - 1,
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
        ],
      ),
    );
  }
}
