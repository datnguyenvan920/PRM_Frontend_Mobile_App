import 'package:flutter/material.dart';
import '../../service/auth_helper.dart';
import '../../service/rating_api_service.dart';
import '../../viewmodels/request/ratingRequest.dart';
import '../../viewmodels/response/bookingResponse.dart';
import '../../widgets/rating_bar.dart';

class RatingDialog extends StatefulWidget {
  final BookingResponse booking;

  const RatingDialog({
    Key? key,
    required this.booking,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  final _commentController = TextEditingController();
  final RatingApiService _apiService = RatingApiService();
  final AuthHelper _authHelper = AuthHelper.instance;
  
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await _authHelper.getAccessToken();
      final customerId = await _authHelper.getCurrentCustomerId();

      if (token == null || customerId == null) throw Exception('Authentication failed');

      final request = CreateRatingRequest(
        bookingId: widget.booking.bookingId,
        customerId: customerId,
        ratingScore: _selectedRating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      await _apiService.createRating(request, accessToken: token);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true on success
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate Service', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(widget.booking.packageName ?? 'Service', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 24),
            const Center(child: Text('How was your experience?', style: TextStyle(fontSize: 16))),
            const SizedBox(height: 16),
            Center(
              child: RatingBar(
                rating: _selectedRating > 0 ? _selectedRating.toDouble() : null,
                onRatingSelected: (value) => setState(() => _selectedRating = value.toInt()),
                iconSize: 40,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Leave a comment (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
