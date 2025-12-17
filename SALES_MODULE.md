# Sales Management Module

## Overview

The Sales Management module provides a comprehensive system for managing product sales, including creating, updating, viewing, and tracking sales with various filtering and reporting capabilities.

## File Structure

```
lib/
├── models/
│   ├── sale.dart           # Sale domain models (Sale, SaleItem, PaymentType, etc.)
│   └── sale.g.dart         # Generated JSON serialization code
├── screens/
│   ├── sales_screen.dart   # Main sales list view with filtering and pagination
│   ├── sale_dialog.dart    # Dialog for creating/updating sales
│   ├── status_update_dialog.dart  # Dialog for updating sale status
│   └── sale_detail_dialog.dart    # Dialog for viewing sale details
└── services/
    ├── sale_service.dart   # API service for sale operations
    └── product_service.dart # API service for product operations
```

## Models

### Sale Domain Models

#### SaleStatus (Enum)
- `PENDING`: Sale is pending
- `COMPLETED`: Sale is completed
- `SHIPPED`: Sale has been shipped
- `RETURNED`: Sale has been returned
- `CANCELLED`: Sale has been cancelled

#### PaymentType
Represents payment method information:
- `id`: Unique identifier
- `name`: Payment method name
- `description`: Optional description

#### DeliveryType
Represents delivery method information:
- `id`: Unique identifier
- `name`: Delivery method name
- `description`: Optional description
- `charge`: Delivery charge

#### SaleItem
Represents individual items in a sale:
- `id`: Unique identifier
- `productId`: Associated product ID
- `productName`: Product name
- `productCategory`: Product category
- `size`: Product size
- `quantityAvailable`: Available quantity
- `quantity`: Quantity ordered
- `salePrice`: Sale price per unit
- `totalPrice`: Total price for this item

#### Sale
Main sale object containing:
- `id`: Unique identifier
- `date`: Sale date
- `totalQuantity`: Total quantity of items
- `totalPrice`: Total sale price
- `paymentTypeId`: ID of payment type used
- `deliveryTypeId`: ID of delivery type used
- `customerId`: Associated customer ID
- `status`: Current sale status
- `saleItems`: List of items in the sale
- `paymentType`: Full payment type object
- `deliveryType`: Full delivery type object
- `customer`: Full customer object

#### SaleCreate
Data model for creating a new sale:
- All sale fields plus customer details
- `customerName`: Customer name
- `customerAddress`: Customer address
- `customerMobile`: Customer phone
- `customerEmail`: Customer email

## Services

### SaleService
Handles all sale-related API operations:

```dart
// Fetch sales
Future<List<Sale>> getSales()

// Create a new sale
Future<Sale> addSale(SaleCreate sale)

// Update existing sale
Future<Sale> updateSale(String saleId, SaleCreate sale)

// Update sale status
Future<Sale> updateSaleStatus(String saleId, SaleStatusUpdate status)

// Complete/Cancel sales
Future<Sale> completeSale(int saleId)
Future<Sale> cancelSale(int saleId)

// Analytics
Future<List<Sale>> getRecentSales()
Future<dynamic> getMostSoldItems()
Future<double> getTotalSales()

// Configuration
Future<List<PaymentType>> getPaymentTypes()
Future<List<DeliveryType>> getDeliveryTypes()
```

### ProductService
Handles product-related operations:

```dart
Future<List<Product>> getProducts()
Future<Product> getProductById(int id)
```

## Screens

### SalesScreen
Main sales management interface featuring:
- **Today's Sale Summary**: Shows daily statistics
  - Total sales count
  - Total revenue
  - Total items sold
- **Filtering Options**:
  - Filter by customer name (search)
  - Filter by date (today, yesterday, this week, this month, custom range)
- **Pagination**: 10 items per page with navigation controls
- **Sales Table**: Displays all sales with columns:
  - ID
  - Customer Name
  - Total Quantity
  - Total Price
  - Date
  - Status (with color-coded badges)
  - Actions
- **Action Buttons**:
  - **View**: View sale details
  - **Update**: Edit sale information
  - **Status**: Change sale status
  - **Cancel**: Cancel the sale
  - **Print**: Print receipt (coming soon)
  - **Refresh**: Reload sales data
  - **Create New Sale**: Open creation dialog
  - **Export to Excel**: Export sales data (coming soon)

### SaleDialog (Create/Update)
Comprehensive form for creating and updating sales:

**Customer Details Section:**
- Customer name (required)
- Customer address
- Customer mobile (required)
- Customer email
- Dummy customer button for quick in-store sales

**Sale Configuration Section:**
- Date picker (defaults to today for new sales)
- Delivery type selector
- Payment type selector
- Payment reference number

**Selected Items Section:**
- Table of selected products
- Edit quantity and price for each item
- Remove item functionality
- Real-time total calculation

**Summary Section:**
- Sub total
- Delivery charge
- Total discount
- Final total price

### StatusUpdateDialog
Simple dialog for updating sale status:
- Display current sale ID and status
- Dropdown to select new status
- Confirmation button

### SaleDetailDialog
Read-only display of sale details:
- Customer information
- Sale information
- Items table
- Summary

## Features

### Implemented
✅ View all sales with detailed information
✅ Create new sales with customer and item details
✅ Update existing sales
✅ Change sale status (PENDING → COMPLETED → SHIPPED, etc.)
✅ Cancel sales
✅ Filter sales by customer name
✅ Filter sales by date (today, yesterday, week, month, custom range)
✅ Pagination (10 items per page)
✅ Today's sale summary (count, revenue, items)
✅ Real-time calculation of totals
✅ Status color-coded badges
✅ Error handling and loading states

### Coming Soon
🔄 Print receipt functionality
🔄 Print shipping label
🔄 Export to Excel
🔄 WhatsApp integration for receipt sharing
🔄 Stock management integration
🔄 Advanced filtering and search

## API Endpoints

### Sales Endpoints
```
GET    /sales/all                          # Get all sales
GET    /sales/recent                       # Get recent sales
GET    /sales/most-sold                    # Get most sold items
GET    /sales/total                        # Get total sales amount
POST   /sales/addSale                      # Create new sale
PUT    /sales/{saleId}/updateStatus        # Update sale status
PUT    /sales/{saleId}/complete            # Mark sale as completed
PUT    /sales/{saleId}/cancel              # Cancel sale
POST   /sales/{saleId}/updateSale          # Update sale details
```

### Configuration Endpoints
```
GET    /payment-types                      # Get available payment types
GET    /delivery-types                     # Get available delivery types
GET    /products/all                       # Get all products
```

## Usage Example

To integrate the sales screen into your app:

```dart
import 'package:flutter_admin_app/screens/sales_screen.dart';

// In your navigation:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SalesScreen()),
);
```

## Error Handling

The module includes comprehensive error handling:
- Network error messages displayed as snackbars
- Loading indicators during async operations
- Validation for required fields
- User-friendly error messages

## Future Enhancements

1. **Print Functionality**
   - Receipt printing with QR codes
   - Shipping label generation

2. **Excel Export**
   - Export filtered sales to Excel
   - Advanced formatting and styling

3. **WhatsApp Integration**
   - Send receipts via WhatsApp
   - Customer notifications

4. **Advanced Features**
   - Bulk actions on multiple sales
   - Sales analytics and charts
   - Inventory integration
   - Customer loyalty tracking
   - Sales performance reports

## Testing

To test the sales module:
1. Ensure API endpoints are accessible
2. Create test sales with various statuses
3. Test filtering by different date ranges
4. Verify pagination works correctly
5. Test creating and updating sales
6. Test status updates

## Notes

- All prices are formatted as currency with ₹ symbol
- Dates are formatted using intl package (MMM d, y format)
- The module uses Material Design patterns
- Responsive design for various screen sizes
- Real-time summary updates as items are added/modified
