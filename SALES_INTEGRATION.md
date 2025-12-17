# Sales Screen Integration Guide

## Quick Start

The Sales Management screen has been fully developed based on the Angular references provided. Here's how to integrate it into your Flutter admin app.

## What Was Created

### 1. **Domain Models** (`lib/models/sale.dart` and `sale.g.dart`)
- Complete Dart models for all sale-related data
- JSON serialization support
- Enum for SaleStatus
- Models for: Sale, SaleItem, PaymentType, DeliveryType, Customer, SaleSummary

### 2. **Services** (`lib/services/`)
- **SaleService**: Complete API integration for all sale operations
- **ProductService**: Product retrieval for sale creation

### 3. **Screens** (`lib/screens/`)
- **SalesScreen**: Main sales management interface
  - Today's summary statistics
  - Advanced filtering (customer name, date ranges)
  - Pagination (10 items per page)
  - Real-time data updates
  
- **SaleDialog**: Create/update sales
  - Customer details input
  - Sale configuration
  - Item selection and pricing
  - Real-time calculation
  
- **StatusUpdateDialog**: Quick status updates
- **SaleDetailDialog**: View sale details

## Integration Steps

### Step 1: Add the SalesScreen to Your Navigation

```dart
// In your main app file or navigation
import 'package:flutter_admin_app/screens/sales_screen.dart';

// Add to your navigation menu or drawer
ListTile(
  leading: const Icon(Icons.shopping_cart),
  title: const Text('Sales'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SalesScreen()),
    );
  },
),
```

### Step 2: Verify API Service Configuration

The app already uses `ApiService` singleton. Ensure your backend API is configured correctly:

```dart
// Default: https://api.adrenalinesportsstore.in/
// Can be overridden with:
const String.fromEnvironment('API_URL')
```

### Step 3: Update Dependencies (if needed)

The sales module uses:
- `intl` (already included) - for date formatting
- `dio` (already included) - for API calls
- `json_annotation` and `json_serializable` (already included) - for JSON serialization

## API Endpoints Required

Make sure your backend has these endpoints:

```
Sales Management
├── GET /sales/all - Get all sales
├── GET /sales/recent - Get recent sales
├── GET /sales/most-sold - Get most sold items
├── GET /sales/total - Get total sales
├── POST /sales/addSale - Create sale
├── PUT /sales/{id}/updateStatus - Update status
├── PUT /sales/{id}/complete - Complete sale
├── PUT /sales/{id}/cancel - Cancel sale
└── POST /sales/{id}/updateSale - Update sale

Configuration
├── GET /payment-types - Payment methods
├── GET /delivery-types - Delivery methods
└── GET /products/all - Products for selection
```

## Key Features

### Today's Summary
Shows real-time statistics:
- Total sales count
- Total revenue
- Total items sold

### Filtering
- **Customer Name**: Real-time search
- **Date Range**: 
  - All time
  - Today
  - Yesterday
  - This week
  - This month
  - Custom date range

### Pagination
- 10 items per page
- Navigation buttons for prev/next/page numbers

### Actions
- View sale details
- Update sale
- Change status
- Cancel sale
- Print receipt (placeholder for future implementation)
- Export to Excel (placeholder for future implementation)

## Customization Points

### Change Items Per Page
In `SalesScreen`:
```dart
static const int itemsPerPage = 10; // Change this value
```

### Modify Date Formats
Dates use `intl` package format: `'MMM d, y'` (e.g., "Jan 15, 2024")

### Update Status Colors
In `_buildStatusBadge()` method, modify the color mapping:
```dart
switch (status) {
  case SaleStatus.pending:
    backgroundColor = Colors.orange.shade100;
    break;
  // ... customize other colors
}
```

### Add Custom Dialogs
Extend `StatusUpdateDialog` or `SaleDetailDialog` as needed

## Testing the Module

1. **List Sales**
   - Navigate to Sales screen
   - Should show all sales with today's summary

2. **Create Sale**
   - Click "Create New Sale"
   - Fill customer details (or use Dummy Customer)
   - Products available through ProductService
   - Verify price calculations
   - Save and verify in list

3. **Filter Sales**
   - Test customer name search
   - Test date range filters
   - Verify pagination works

4. **Update Status**
   - Click "Status" on any sale
   - Change status
   - Verify in list updates

5. **Cancel Sale**
   - Click "Cancel" on any sale
   - Confirm dialog appears
   - Verify sale status changes to CANCELLED

## Common Issues & Solutions

### Issue: "Products not loading"
**Solution**: Check ProductService and ensure `/products/all` endpoint exists

### Issue: "API timeout errors"
**Solution**: Check network connectivity and API service baseUrl configuration

### Issue: "JSON deserialization errors"
**Solution**: Ensure backend returns data in correct format matching models

### Issue: "Pagination not working"
**Solution**: Verify `filteredSales` list is properly populated after filtering

## Future Enhancements Ready

The structure is prepared for:
- Print receipt functionality (HTML/PDF generation)
- Excel export (csv generation)
- WhatsApp integration (URL scheme)
- Advanced filtering
- Bulk operations
- Sales analytics

## File Summary

| File | Purpose | Lines |
|------|---------|-------|
| `sale.dart` | Domain models | ~450 |
| `sale.g.dart` | JSON serialization | ~300 |
| `sale_service.dart` | API integration | ~170 |
| `product_service.dart` | Product API | ~30 |
| `sales_screen.dart` | Main UI | ~650 |
| `sale_dialog.dart` | Create/Update UI | ~550 |
| `status_update_dialog.dart` | Status update | ~70 |
| `sale_detail_dialog.dart` | View details | ~150 |

**Total: ~2,370 lines of production code**

## Support & Troubleshooting

For issues or questions:
1. Check the `SALES_MODULE.md` file for detailed documentation
2. Review error messages in the console
3. Verify API endpoints are accessible
4. Check network connectivity
5. Ensure backend is returning correct data format

## Next Steps

1. ✅ Integrate SalesScreen into your navigation
2. ⏳ Implement print functionality (using `pdf` package)
3. ⏳ Implement Excel export (using `excel` package)
4. ⏳ Add WhatsApp integration
5. ⏳ Add advanced analytics and reporting

Enjoy your new Sales Management module! 🎉
