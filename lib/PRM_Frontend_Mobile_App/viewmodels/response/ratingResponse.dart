class RatingResponse {
  final int ratingId;
  final int bookingId;
  final String? bookingCode;
  final int customerId;
  final String? customerName;
  final int workerId;
  final String? workerName;
  final int? ratingScore;
  final String? comment;
  final String? createdAt;

  RatingResponse({
    required this.ratingId,
    required this.bookingId,
    this.bookingCode,
    required this.customerId,
    this.customerName,
    required this.workerId,
    this.workerName,
    this.ratingScore,
    this.comment,
    this.createdAt,
  });

  factory RatingResponse.fromJson(Map<String, dynamic> json) {
    return RatingResponse(
      ratingId: json['ratingId'] ?? json['RatingId'] ?? 0,
      bookingId: json['bookingId'] ?? json['BookingId'] ?? 0,
      bookingCode: json['bookingCode'] ?? json['BookingCode'],
      customerId: json['customerId'] ?? json['CustomerId'] ?? 0,
      customerName: json['customerName'] ?? json['CustomerName'],
      workerId: json['workerId'] ?? json['WorkerId'] ?? 0,
      workerName: json['workerName'] ?? json['WorkerName'],
      ratingScore: json['ratingScore'] ?? json['RatingScore'],
      comment: json['comment'] ?? json['Comment'],
      createdAt: json['createdAt'] ?? json['CreatedAt'],
    );
  }
}
