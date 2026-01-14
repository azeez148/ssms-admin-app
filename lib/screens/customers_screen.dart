import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({Key? key}) : super(key: key);

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerService _customerService = CustomerService();

  List<Customer> allCustomers = [];
  List<Customer> filteredCustomers = [];

  bool isLoading = true;
  String? errorMessage;

  // Filters
  String searchFilter = '';

  // Pagination (SAME AS SALES)
  int currentPage = 1;
  static const int itemsPerPage = 10;

  // Styling
  final Color primaryColor = const Color(0xFF2A2D3E);
  final Color surfaceColor = const Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final customers = await _customerService.getCustomers();

      setState(() {
        allCustomers = customers..sort((a, b) => b.id.compareTo(a.id));
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading customers: $e';
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Customer> filtered = List.from(allCustomers);

    if (searchFilter.isNotEmpty) {
      filtered = filtered
          .where((c) =>
              c.name.toLowerCase().contains(searchFilter.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredCustomers = filtered;
      currentPage = 1;
    });
  }

  void _openDialog([Customer? customer]) async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (context) => CustomerDialog(customer: customer),
    );

    if (result != null) {
      if (customer == null) {
        await _customerService.createCustomer(result);
      } else {
        await _customerService.updateCustomer(result);
      }
      _loadCustomers();
    }
  }

  void _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Customer'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirm == true) {
      await _customerService.deleteCustomer(customer.id);
      _loadCustomers();
    }
  }

  void _openWhatsApp(String mobile) async {
    if (mobile.isNotEmpty) {
      final url = Uri.parse('https://wa.me/$mobile/?text=${Uri.encodeComponent("Hi, This is Admin from Adrenaline sports store")}');
      try {
        await launchUrl(url);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch WhatsApp: $e'),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Mobile Number'),
          content: const Text('This customer does not have a mobile number.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 800;

    // Pagination logic (same as Sales)
    final totalPages = (filteredCustomers.length / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex =
        (startIndex + itemsPerPage).clamp(0, filteredCustomers.length);
    final paginatedCustomers =
        filteredCustomers.sublist(startIndex, endIndex);

    return Scaffold(
      backgroundColor: surfaceColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Customers',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: _loadCustomers,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                )
              ],
            ),
          ),

          // Filters
          Transform.translate(
            offset: const Offset(0, -25),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isMobile
                  ? Column(
                      children: [
                        _buildSearch(),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => _openDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildSearch()),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                      ],
                    ),
            ),
          ),

          // List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)))
                    : filteredCustomers.isEmpty
                        ? _buildEmpty()
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              children: [
                                Expanded(
                                  child: isMobile
                                      ? ListView.builder(
                                          itemCount: paginatedCustomers.length,
                                          itemBuilder: (_, i) =>
                                              _buildMobileCard(paginatedCustomers[i]),
                                        )
                                      : SingleChildScrollView(
                                          child: DataTable(
                                            columns: const [
                                              DataColumn(label: Text('ID')),
                                              DataColumn(label: Text('Name')),
                                              DataColumn(label: Text('Mobile')),
                                              DataColumn(label: Text('Email')),
                                              DataColumn(label: Text('Actions')),
                                            ],
                                            rows: paginatedCustomers.map((c) {
                                              return DataRow(cells: [
                                                DataCell(Text(c.id.toString())),
                                                DataCell(Text(c.name)),
                                                DataCell(Text(c.mobile)),
                                                DataCell(Text(c.email ?? '')),
                                                DataCell(Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.edit),
                                                      onPressed: () => _openDialog(c),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(Icons.delete),
                                                      onPressed: () => _deleteCustomer(c),
                                                    ),
                                                    IconButton(
                                                      icon: const FaIcon(FontAwesomeIcons.whatsapp),
                                                      onPressed: () => _openWhatsApp(c.mobile),
                                                    ),
                                                  ],
                                                )),
                                              ]);
                                            }).toList(),
                                          ),
                                        ),
                                ),
                                if (totalPages > 1)
                                  _buildPaginationControls(totalPages),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return TextField(
      onChanged: (val) {
        searchFilter = val;
        _applyFilters();
      },
      decoration: InputDecoration(
        hintText: 'Search customer',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text("Page $currentPage of $totalPages"),
          IconButton(
            onPressed: currentPage < totalPages ? () => setState(() => currentPage++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(child: Text("No customers found"));
  }

  Widget _buildMobileCard(Customer c) {
    return Card(
      child: ListTile(
        title: Text(c.name),
        subtitle: Text(c.mobile),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDialog(c)),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteCustomer(c)),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp),
              onPressed: () => _openWhatsApp(c.mobile),
            ),
          ],
        ),
      ),
    );
  }
}


class CustomerDialog extends StatefulWidget {
  final Customer? customer;
  const CustomerDialog({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<CustomerDialog> {
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController mobileController;
  late TextEditingController emailController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.customer?.name ?? '');
    addressController = TextEditingController(text: widget.customer?.address ?? '');
    mobileController = TextEditingController(text: widget.customer?.mobile ?? '');
    emailController = TextEditingController(text: widget.customer?.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: mobileController,
              decoration: const InputDecoration(labelText: 'Mobile'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final customer = Customer(
              id: widget.customer?.id ?? 0,
              name: nameController.text.trim(),
              address: addressController.text.trim(),
              mobile: mobileController.text.trim(),
              email: emailController.text.trim(),
            );
            Navigator.pop(context, customer);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
