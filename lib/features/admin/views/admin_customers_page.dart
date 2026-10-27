import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/customer_view_model.dart';

class AdminCustomersPage extends StatefulWidget {
  const AdminCustomersPage({super.key});

  @override
  State<AdminCustomersPage> createState() => _AdminCustomersPageState();
}

class _AdminCustomersPageState extends State<AdminCustomersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CustomerViewModel>().loadCustomers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            onPressed: () => context.read<CustomerViewModel>().refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<CustomerViewModel>(
        builder: (context, vm, child) {
          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Card(
                //   child: ListTile(
                //     leading: const CircleAvatar(child: Icon(Icons.people)),
                //     title: const Text('Registered Customers'),
                //     subtitle: const Text(
                //       'Customers with a profile in Supabase',
                //     ),
                //     trailing: Text(
                //       '${vm.customers.length}',
                //       style: const TextStyle(
                //         fontSize: 22,
                //         fontWeight: FontWeight.bold,
                //       ),
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: vm.searchCustomers,
                  decoration: InputDecoration(
                    hintText: 'Search by customer name or ID',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              vm.searchCustomers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (vm.isLoading && vm.customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (vm.errorMessage != null)
                  _errorView(vm)
                else if (vm.customers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.person_search, size: 55, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No customers found'),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Customers (${vm.customers.length})',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...vm.customers.map(
                    (customer) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(_initial(customer['full_name'])),
                        ),
                        title: Text(
                          (customer['full_name'] ?? 'Unnamed customer')
                              .toString(),
                        ),
                        subtitle: Text(
                          'ID: ${customer['id']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _showCustomerDetails(context, vm, customer),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(CustomerViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 45),
          const SizedBox(height: 12),
          const Text('Unable to load customers'),
          const SizedBox(height: 8),
          Text(vm.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: vm.refresh, child: const Text('Retry')),
        ],
      ),
    );
  }

  Future<void> _showCustomerDetails(
    BuildContext context,
    CustomerViewModel vm,
    Map<String, dynamic> customer,
  ) async {
    final customerId = customer['id'].toString();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text((customer['full_name'] ?? 'Customer').toString()),
          content: SizedBox(
            width: 450,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: vm.getCustomerRequests(customerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    'Could not load request history:\n${snapshot.error}',
                  );
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Text(
                    'No service requests found for this customer.',
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.home_repair_service),
                        title: Text(
                          (request['category'] ?? 'Service request').toString(),
                        ),
                        subtitle: Text(
                          '${request['address'] ?? 'No address'}\n'
                          'Status: ${request['status'] ?? 'Unknown'}',
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _initial(dynamic value) {
    final name = (value ?? '').toString().trim();
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class AdminCustomersPage extends StatefulWidget {
//   const AdminCustomersPage({super.key});
//
//   @override
//   State<AdminCustomersPage> createState() => _AdminCustomersPageState();
// }
//
// class _AdminCustomersPageState extends State<AdminCustomersPage> {
//   final SupabaseClient _client = Supabase.instance.client;
//   final TextEditingController _searchController = TextEditingController();
//
//   List<Map<String, dynamic>> _customers = [];
//   bool _loading = true;
//   String? _error;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadCustomers();
//   }
//
//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadCustomers() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//
//     try {
//       final result = await _client
//           .from('profiles')
//           .select('id, full_name, role')
//           .eq('role', 'customer')
//           .order('full_name');
//
//       if (!mounted) return;
//
//       setState(() {
//         _customers = List<Map<String, dynamic>>.from(result);
//         _loading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//
//       setState(() {
//         _error = e.toString();
//         _loading = false;
//       });
//     }
//   }
//
//   List<Map<String, dynamic>> get _filteredCustomers {
//     final query = _searchController.text.trim().toLowerCase();
//
//     if (query.isEmpty) return _customers;
//
//     return _customers.where((customer) {
//       final name = (customer['full_name'] ?? '').toString().toLowerCase();
//
//       final id = (customer['id'] ?? '').toString().toLowerCase();
//
//       return name.contains(query) || id.contains(query);
//     }).toList();
//   }
//
//   Future<void> _showCustomerRequests(Map<String, dynamic> customer) async {
//     try {
//       final result = await _client
//           .from('service_requests')
//           .select('id, category, address, status, created_at')
//           .eq('customer_id', customer['id'])
//           .order('created_at', ascending: false);
//
//       if (!mounted) return;
//
//       final requests = List<Map<String, dynamic>>.from(result);
//
//       await showModalBottomSheet<void>(
//         context: context,
//         isScrollControlled: true,
//         builder: (sheetContext) {
//           return SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.all(20),
//               child: SizedBox(
//                 height: MediaQuery.of(sheetContext).size.height * 0.65,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${customer['full_name'] ?? 'Customer'} '
//                       '— Service History',
//                       style: const TextStyle(
//                         fontSize: 19,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     Expanded(
//                       child: requests.isEmpty
//                           ? const Center(
//                               child: Text('No service requests found.'),
//                             )
//                           : ListView.builder(
//                               itemCount: requests.length,
//                               itemBuilder: (context, index) {
//                                 final request = requests[index];
//
//                                 return Card(
//                                   child: ListTile(
//                                     leading: const Icon(
//                                       Icons.home_repair_service,
//                                     ),
//                                     title: Text(
//                                       (request['category'] ?? 'Service Request')
//                                           .toString(),
//                                     ),
//                                     subtitle: Text(
//                                       '${request['address'] ?? 'No address'}\n'
//                                       'Status: ${request['status'] ?? 'pending'}',
//                                     ),
//                                     isThreeLine: true,
//                                   ),
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       );
//     } catch (e) {
//       if (!mounted) return;
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Unable to load service history: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final customers = _filteredCustomers;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Customer Management'),
//         actions: [
//           IconButton(
//             tooltip: 'Refresh',
//             onPressed: _loading ? null : _loadCustomers,
//             icon: const Icon(Icons.refresh),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (_) => setState(() {}),
//                 decoration: InputDecoration(
//                   hintText: 'Search customer name or ID',
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon: IconButton(
//                     onPressed: () {
//                       _searchController.clear();
//                       setState(() {});
//                     },
//                     icon: const Icon(Icons.clear),
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: _loading
//                   ? const Center(child: CircularProgressIndicator())
//                   : _error != null
//                   ? Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(20),
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(
//                               Icons.error_outline,
//                               size: 40,
//                               color: Colors.red,
//                             ),
//                             const SizedBox(height: 12),
//                             Text(_error!, textAlign: TextAlign.center),
//                             const SizedBox(height: 12),
//                             ElevatedButton(
//                               onPressed: _loadCustomers,
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   : customers.isEmpty
//                   ? const Center(child: Text('No customers found.'))
//                   : RefreshIndicator(
//                       onRefresh: _loadCustomers,
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         itemCount: customers.length,
//                         itemBuilder: (context, index) {
//                           final customer = customers[index];
//
//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 10),
//                             child: ListTile(
//                               leading: const CircleAvatar(
//                                 child: Icon(Icons.person_outline),
//                               ),
//                               title: Text(
//                                 (customer['full_name'] ?? 'Unnamed Customer')
//                                     .toString(),
//                               ),
//                               subtitle: Text(
//                                 'ID: ${customer['id']}',
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               trailing: const Icon(Icons.chevron_right),
//                               onTap: () => _showCustomerRequests(customer),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
