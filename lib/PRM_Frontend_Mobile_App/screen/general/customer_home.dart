import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../screen/general/profile_screen.dart';
import '../../service/homeService.dart';
import '../../viewmodels/request/paginationRequest.dart';
import '../../viewmodels/response/homeResponse.dart';
import '../booking/booking_screen.dart';
import '../booking/create_booking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _selectedIndex = 0;
  final HomeService _homeService = HomeService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = true;
  CustomerHomeResponse? _homeData;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _secureStorage.read(key: 'access_token');
      if (token != null) {
        _homeData = await _homeService.getCustomerHome(token, PaginationRequest(pageSize: 10));
      }
    } catch (e) {
      debugPrint('Error loading customer home: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())).then((_) => setState(() => _selectedIndex = 0));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())).then((_) => setState(() => _selectedIndex = 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadHomeData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20.0),
                  child: _homeData == null ? _buildError() : _buildContent(),
                ),
              ),
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(_homeData!.name, 'Home Service', _homeData!.avatar),
        const SizedBox(height: 24),
        _buildSearchBar(),
        const SizedBox(height: 32),
        const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _homeData!.categories.items.length,
          itemBuilder: (context, index) {
            final cat = _homeData!.categories.items[index];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateBookingScreen(initialCategory: cat))),
              child: _buildCategoryCard(cat.categoryName, cat.imageUrl),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text('Special Offers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())),
          child: PromoCard(
            title: 'Deep Home Cleaning',
            subtitle: 'Get 20% off your first booking.',
            colors: const [Colors.blueAccent, Colors.lightBlue],
            imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTNYwaFbd2pE0CNk7-mOVkCMJJ5XHA8I0Vv4A&s',
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())),
          child: PromoCard(
            title: 'Sparkling Kitchen',
            subtitle: 'Professional deep degreasing.',
            colors: const [Colors.orangeAccent, Colors.deepOrange],
            imageUrl: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?q=80&w=400',
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingScreen())),
          child: PromoCard(
            title: 'AC Maintenance',
            subtitle: 'Keep your home cool and fresh.',
            colors: const [Colors.teal, Colors.greenAccent],
            imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQgbnmqjKx24Js5v-9ap5kZ__aQdA_T7Tn-9Q&s',
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String name, String subtitle, String? avatar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome, $name! 👋', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text(subtitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ]),
        CircleAvatar(
          radius: 24,
          backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
          child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person) : null,
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name, String? imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.cleaning_services, color: Colors.blue, size: 28),
                  )
                : const Icon(Icons.cleaning_services, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: const TextField(decoration: InputDecoration(hintText: 'What service do you need?', border: InputBorder.none, icon: Icon(Icons.search, color: Colors.blueAccent))),
    );
  }

  Widget _buildError() {
    return const Center(child: Text('Failed to load data. Please pull to refresh.'));
  }
}

class PromoCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final String imageUrl;

  const PromoCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<PromoCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.colors[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Decorative Circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          // Animated Round Image
          Positioned(
            right: 15,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Center(
                  child: Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.auto_awesome, size: 40, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 150,
                  child: Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Book Now',
                    style: TextStyle(
                      color: widget.colors[0],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
