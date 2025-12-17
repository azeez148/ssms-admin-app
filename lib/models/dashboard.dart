import 'package:json_annotation/json_annotation.dart';

part 'dashboard.g.dart';

@JsonSerializable()
class SaleResponse {
  final int? id;
  final int? product_id;
  final String? product_name;
  final int? quantity;
  final int? total_amount;
  final String? sale_date;
  
  // Additional fields from actual backend response
  final int? total_price;
  final String? date;
  final List<SaleItem>? sale_items;
  final String? status;
  final int? customer_id;
  final int? shop_id;

  SaleResponse({
    this.id,
    this.product_id,
    this.product_name,
    this.quantity,
    this.total_amount,
    this.sale_date,
    this.total_price,
    this.date,
    this.sale_items,
    this.status,
    this.customer_id,
    this.shop_id,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) => _$SaleResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SaleResponseToJson(this);
  
  // Get the actual amount (prefer total_price from backend)
  int getAmount() => total_price ?? total_amount ?? 0;
  
  // Get the actual date
  String? getDate() => date ?? sale_date;
  
  // Get product name from sale_items if not available at top level
  String? getProductName() {
    if (product_name != null && product_name!.isNotEmpty) {
      return product_name;
    }
    if (sale_items != null && sale_items!.isNotEmpty) {
      return sale_items!.first.product_name;
    }
    return null;
  }
  
  // Get quantity from sale_items if available
  int getQuantity() {
    if (quantity != null && quantity! > 0) {
      return quantity!;
    }
    if (sale_items != null && sale_items!.isNotEmpty) {
      return sale_items!.fold<int>(0, (sum, item) => sum + (item.quantity ?? 0));
    }
    return 0;
  }
}

@JsonSerializable()
class SaleItem {
  final int? id;
  final int? product_id;
  final String? product_name;
  final String? product_category;
  final int? quantity;
  final int? sale_price;
  final int? total_price;

  SaleItem({
    this.id,
    this.product_id,
    this.product_name,
    this.product_category,
    this.quantity,
    this.sale_price,
    this.total_price,
  });

  factory SaleItem.fromJson(Map<String, dynamic> json) => _$SaleItemFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemToJson(this);
}

@JsonSerializable()
class PurchaseResponse {
  final int? id;
  final int? product_id;
  final String? product_name;
  final int? quantity;
  final int? total_amount;
  final String? purchase_date;
  final int? total_price;
  final String? date;

  PurchaseResponse({
    this.id,
    this.product_id,
    this.product_name,
    this.quantity,
    this.total_amount,
    this.purchase_date,
    this.total_price,
    this.date,
  });

  factory PurchaseResponse.fromJson(Map<String, dynamic> json) => _$PurchaseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PurchaseResponseToJson(this);
  
  int getAmount() => total_price ?? total_amount ?? 0;
  String? getDate() => date ?? purchase_date;
}

@JsonSerializable()
class Dashboard {
  final Map<String, dynamic>? total_sales;
  final int? total_products;
  final int? total_categories;
  final Map<String, dynamic>? most_sold_items;
  final List<SaleResponse>? recent_sales;
  final Map<String, dynamic>? total_purchases;
  final List<PurchaseResponse>? recent_purchases;

  Dashboard({
    this.total_sales,
    this.total_products,
    this.total_categories,
    this.most_sold_items,
    this.recent_sales,
    this.total_purchases,
    this.recent_purchases,
  });

  factory Dashboard.fromJson(Map<String, dynamic> json) => _$DashboardFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardToJson(this);
}
