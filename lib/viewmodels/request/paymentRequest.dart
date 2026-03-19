class CreatePaymentRequest {
  final int bookingId;
  final String paymentMethod;
  final String? transactionCode;

  CreatePaymentRequest({
    required this.bookingId,
    required this.paymentMethod,
    this.transactionCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'bookingId': bookingId,
      'paymentMethod': paymentMethod,
    };
    if (transactionCode != null) {
      map['transactionCode'] = transactionCode;
    }
    return map;
  }
}

class UpdatePaymentStatusRequest {
  final String paymentStatus; // "paid", "failed", "pending"
  final String? transactionCode;

  UpdatePaymentStatusRequest({
    required this.paymentStatus,
    this.transactionCode,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'paymentStatus': paymentStatus,
    };
    if (transactionCode != null) {
      map['transactionCode'] = transactionCode;
    }
    return map;
  }
}