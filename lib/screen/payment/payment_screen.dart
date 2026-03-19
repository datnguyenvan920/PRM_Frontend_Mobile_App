import 'package:flutter/material.dart';
import 'package:projectprm/models/booking.dart';
import 'package:projectprm/service/payment_api_service.dart';
import 'package:projectprm/viewmodels/request/paymentRequest.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking; // Truyền booking vào để biết đang thanh toán cho đơn nào

  const PaymentScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentApiService _paymentService = PaymentApiService();
  final TextEditingController _transactionController = TextEditingController();

  String _selectedMethod = 'cash'; // Mặc định là tiền mặt
  bool _isLoading = false;

  @override
  void dispose() {
    _transactionController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isLoading = true);
    try {
      // 1. Gọi API tạo Payment (Trạng thái mặc định là pending)
      final createRequest = CreatePaymentRequest(
        bookingId: int.parse(widget.booking.id), // Đảm bảo id của bạn parse được sang int
        paymentMethod: _selectedMethod,
        transactionCode: _transactionController.text.trim().isEmpty ? null : _transactionController.text.trim(),
      );

      final paymentResponse = await _paymentService.createPayment(createRequest);

      // 2. Nếu là Bank hoặc Momo và có nhập mã giao dịch -> Update thành 'paid'
      if ((_selectedMethod == 'bank_transfer' || _selectedMethod == 'momo') &&
          _transactionController.text.trim().isNotEmpty) {

        final updateRequest = UpdatePaymentStatusRequest(
          paymentStatus: 'paid',
          transactionCode: _transactionController.text.trim(),
        );
        await _paymentService.updatePaymentStatus(paymentResponse.paymentId, updateRequest);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanh toán thành công!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Trả về true để màn hình trước biết đã thanh toán xong
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentOption(String title, String methodValue, IconData icon) {
    final isSelected = _selectedMethod == methodValue;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.transparent, width: 2),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
        onTap: () {
          setState(() {
            _selectedMethod = methodValue;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán dịch vụ'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin Booking
            Card(
              color: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dịch vụ: ${widget.booking.serviceName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Mã đơn: ${widget.booking.id}', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Chọn phương thức thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildPaymentOption('Tiền mặt', 'cash', Icons.money),
            const SizedBox(height: 8),
            _buildPaymentOption('Chuyển khoản Ngân hàng', 'bank_transfer', Icons.account_balance),
            const SizedBox(height: 8),
            _buildPaymentOption('Ví điện tử Momo', 'momo', Icons.account_balance_wallet),

            const SizedBox(height: 24),

            // Hiển thị ô nhập mã giao dịch nếu chọn Bank/Momo
            if (_selectedMethod == 'bank_transfer' || _selectedMethod == 'momo') ...[
              const Text('Nhập mã giao dịch (Sau khi chuyển khoản):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _transactionController,
                decoration: InputDecoration(
                  hintText: 'VD: FT21123456...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.receipt),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('XÁC NHẬN THANH TOÁN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}