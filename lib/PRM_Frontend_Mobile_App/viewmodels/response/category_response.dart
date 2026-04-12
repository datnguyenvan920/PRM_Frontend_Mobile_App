class CategoryResponse {
  final int categoryId;
  final String categoryName;

  CategoryResponse({
    required this.categoryId,
    required this.categoryName,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryId: json['categoryId'] ?? json['CategoryId'] ?? 0,
      // Note: Handling both 'GategoryName' (from backend snippet) and standard 'categoryName'
      categoryName: json['gategoryName'] ?? json['GategoryName'] ?? json['categoryName'] ?? json['CategoryName'] ?? '',
    );
  }
}
