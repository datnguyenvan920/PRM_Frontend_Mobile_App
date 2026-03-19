class PaymentResponse {
  final int paymentId;
  final int bookingId;
  final String? bookingCode;
  final double? bookingTotalPrice;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? transactionCode;
  final String? paidAt;

  PaymentResponse({
    required this.paymentId,
    required this.bookingId,
    this.bookingCode,
    this.bookingTotalPrice,
    this.paymentMethod,
    this.paymentStatus,
    this.transactionCode,
    this.paidAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      paymentId: json['paymentId'] as int,
      bookingId: json['bookingId'] as int,
      bookingCode: json['bookingCode'] as String?,
      bookingTotalPrice: json['bookingTotalPrice'] != null
          ? double.parse(json['bookingTotalPrice'].toString())
          : null,
      paymentMethod: json['paymentMethod'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      transactionCode: json['transactionCode'] as String?,
      paidAt: json['paidAt'] as String?,
    );
  }
}