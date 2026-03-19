class BookingResponse {
  final int bookingId;
  final String? bookingCode;
  final int customerId;
  final int? workerId;
  final int packageId;
  final String bookingDate;
  final String startTime;
  final String? endTime;
  final String address;
  final String? note;
  final double? totalPrice;
  final String? status;
  final String? createdAt;
  final String? updatedAt;
  final PackageInfo? package;
  final CustomerInfo? customer;
  final WorkerInfo? worker;
  final List<RatingInfo>? ratings;

  BookingResponse({
    required this.bookingId,
    this.bookingCode,
    required this.customerId,
    this.workerId,
    required this.packageId,
    required this.bookingDate,
    required this.startTime,
    this.endTime,
    required this.address,
    this.note,
    this.totalPrice,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.package,
    this.customer,
    this.worker,
    this.ratings,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      bookingId: json['bookingId'] as int,
      bookingCode: json['bookingCode'] as String?,
      customerId: json['customerId'] as int,
      workerId: json['workerId'] as int?,
      packageId: json['packageId'] as int,
      bookingDate: json['bookingDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String?,
      address: json['address'] as String,
      note: json['note'] as String?,
      totalPrice: json['totalPrice'] != null ? (json['totalPrice'] as num).toDouble() : null,
      status: json['status'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      package: json['package'] != null ? PackageInfo.fromJson(json['package'] as Map<String, dynamic>) : null,
      customer: json['customer'] != null ? CustomerInfo.fromJson(json['customer'] as Map<String, dynamic>) : null,
      worker: json['worker'] != null ? WorkerInfo.fromJson(json['worker'] as Map<String, dynamic>) : null,
      ratings: json['ratings'] != null
          ? (json['ratings'] as List).map((e) => RatingInfo.fromJson(e as Map<String, dynamic>)).toList()
          : null,
    );
  }
}

class PackageInfo {
  final int packageId;
  final String packageName;
  final String? description;
  final double price;
  final int durationHours;
  final CategoryInfo? category;

  PackageInfo({
    required this.packageId,
    required this.packageName,
    this.description,
    required this.price,
    required this.durationHours,
    this.category,
  });

  factory PackageInfo.fromJson(Map<String, dynamic> json) {
    return PackageInfo(
      packageId: json['packageId'] as int,
      packageName: json['packageName'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      durationHours: json['durationHours'] as int,
      category: json['category'] != null ? CategoryInfo.fromJson(json['category'] as Map<String, dynamic>) : null,
    );
  }
}

class CategoryInfo {
  final int categoryId;
  final String categoryName;

  CategoryInfo({
    required this.categoryId,
    required this.categoryName,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
    );
  }
}

class CustomerInfo {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;

  CustomerInfo({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class WorkerInfo {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;

  WorkerInfo({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
  });

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      userId: json['userId'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class RatingInfo {
  final int ratingId;
  final int ratingScore;
  final String? comment;
  final String? createdAt;

  RatingInfo({
    required this.ratingId,
    required this.ratingScore,
    this.comment,
    this.createdAt,
  });

  factory RatingInfo.fromJson(Map<String, dynamic> json) {
    return RatingInfo(
      ratingId: json['ratingId'] as int,
      ratingScore: json['ratingScore'] as int,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
