import 'package:field_service/features/customer/view/customer_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../viewmodel/customer_home_view_model.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomerHomeViewModel()..loadRecentRequests(),
      child: const _CustomerHomeContent(),
    );
  }
}

class _CustomerHomeContent extends StatefulWidget {
  const _CustomerHomeContent();

  @override
  State<_CustomerHomeContent> createState() => _CustomerHomeContentState();
}

class _CustomerHomeContentState extends State<_CustomerHomeContent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _CustomerDashboard(),
      const RecentRequestsWidget(),
      const CustomerProfileScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _CustomerDashboard extends StatelessWidget {
  const _CustomerDashboard();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FixMate',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Home services made simple',
                          style: TextStyle(color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Main banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1769FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need a repair?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Book a service in a few steps.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.home_repair_service_outlined,
                      color: Colors.white,
                      size: 42,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await context.push(
                      '/customer/service-request',
                    );
                    if (result == true && context.mounted) {
                      context
                          .read<CustomerHomeViewModel>()
                          .loadRecentRequests();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Service Request'),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Quick Services',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.electrical_services,
                      title: 'Electrical',
                      onTap: () async {
                        final result = await context.push(
                          '/customer/service-request',
                          extra: 'Electrical',
                        );
                        if (result == true && context.mounted) {
                          context
                              .read<CustomerHomeViewModel>()
                              .loadRecentRequests();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Plumbing',
                      onTap: () async {
                        final result = await context.push(
                          '/customer/service-request',
                          extra: 'Plumbing',
                        );
                        if (result == true && context.mounted) {
                          context
                              .read<CustomerHomeViewModel>()
                              .loadRecentRequests();
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.ac_unit,
                      title: 'Appliance Repair',
                      onTap: () async {
                        final result = await context.push(
                          '/customer/service-request',
                          extra: 'Appliance Repair',
                        );
                        if (result == true && context.mounted) {
                          context
                              .read<CustomerHomeViewModel>()
                              .loadRecentRequests();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ServiceCard(
                      icon: Icons.build_outlined,
                      title: 'Other repairs',
                      onTap: () async {
                        final result = await context.push(
                          '/customer/service-request',
                          extra: 'Other',
                        );
                        if (result == true && context.mounted) {
                          context
                              .read<CustomerHomeViewModel>()
                              .loadRecentRequests();
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                'Recent Requests',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              const _RecentRequestsList(dashboardMode: true),
            ]),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// RECENT REQUESTS TAB
// --------------------------------------------------

class RecentRequestsWidget extends StatelessWidget {
  const RecentRequestsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CustomerHomeViewModel>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'My Service Requests',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: _RecentRequestsList(dashboardMode: false),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// SHARED REQUEST LIST
// --------------------------------------------------

class _RecentRequestsList extends StatelessWidget {
  const _RecentRequestsList({required this.dashboardMode});

  final bool dashboardMode;

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerHomeViewModel>(
      builder: (context, vm, child) {
        if (vm.isLoading && vm.recentRequests.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (vm.errorMessage != null && vm.recentRequests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unable to load service requests',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(vm.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: vm.loadRecentRequests,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (vm.recentRequests.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: Colors.blueGrey,
                ),
                SizedBox(height: 10),
                Text(
                  'No service requests yet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Your requests will appear here.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final requests = dashboardMode
            ? vm.recentRequests.take(3).toList()
            : vm.recentRequests;

        return Column(
          children: requests.map((request) {
            final category =
                request['category']?.toString() ?? 'Service request';

            final status =
                request['status']?.toString().toLowerCase() ?? 'pending';

            final address = request['address']?.toString() ?? '';

            final synced = vm.isSynced(request['is_synced']);

            final statusColor = switch (status) {
              'completed' => Colors.green,
              'assigned' => Colors.blue,
              'in_progress' => Colors.orange,
              'cancelled' => Colors.red,
              _ => Colors.blueGrey,
            };

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  context.push('/customer/request-tracking', extra: request);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.home_repair_service_outlined,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Colors.blueGrey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.blueGrey),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// --------------------------------------------------
// SERVICE CARD
// --------------------------------------------------

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF1769FF)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------
// PLACEHOLDER PAGE
// --------------------------------------------------

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: const Color(0xFF1769FF)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Coming soon'),
        ],
      ),
    );
  }
}

// import 'package:field_service/features/customer/view/customer_profile_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../../core/di/service_locator.dart';
// import '../../../repositorys/auth_repository.dart';
//
// class CustomerHomeScreen extends StatefulWidget {
//   const CustomerHomeScreen({super.key});
//
//   @override
//   State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
// }
//
// class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
//   int _selectedIndex = 0;
//
//   late final List<Widget> _pages = [
//     const _CustomerDashboard(),
//     const RecentRequestsWidget(),
//     const _PlaceholderPage(
//       title: 'Notifications',
//       icon: Icons.notifications_none,
//     ),
//     CustomerProfileScreen(),
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(child: _pages[_selectedIndex]),
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (index) {
//           setState(() => _selectedIndex = index);
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.home_outlined),
//             selectedIcon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.assignment_outlined),
//             label: 'Requests',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.notifications_none),
//             label: 'Alerts',
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.person_outline),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class RecentRequestsWidget extends StatefulWidget {
//   const RecentRequestsWidget({super.key});
//
//   @override
//   State<RecentRequestsWidget> createState() => _RecentRequestsWidgetState();
// }
//
// class _RecentRequestsWidgetState extends State<RecentRequestsWidget> {
//   List<Map<String, dynamic>> _recentRequests = [];
//
//   bool _loadingRequests = true;
//   String? _errorMessage;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRecentRequests();
//   }
//
//   Future<void> _loadRecentRequests() async {
//     if (!mounted) return;
//
//     setState(() {
//       _loadingRequests = true;
//       _errorMessage = null;
//     });
//
//     try {
//       final user = getIt<AuthRepository>().currentUser;
//
//       if (user == null) {
//         throw Exception('Please sign in to view your requests.');
//       }
//
//       final requests = await getIt<ServiceRequestRepository>()
//           .getRecentRequests(user.id);
//
//       if (!mounted) return;
//
//       setState(() {
//         _recentRequests = requests;
//         _loadingRequests = false;
//       });
//     } catch (e, stackTrace) {
//       debugPrint('Unable to load requests: $e');
//       debugPrintStack(stackTrace: stackTrace);
//
//       if (!mounted) return;
//
//       setState(() {
//         _errorMessage = e.toString();
//         _loadingRequests = false;
//       });
//     }
//   }
//
//   bool _isSynced(dynamic value) {
//     // SQLite commonly stores false/true as 0/1.
//     if (value is bool) return value;
//     if (value is num) return value == 1;
//
//     if (value is String) {
//       return value == '1' || value.toLowerCase() == 'true';
//     }
//
//     return false;
//   }
//
//   Widget _buildRecentRequests() {
//     if (_loadingRequests && _recentRequests.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(24),
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     if (_errorMessage != null && _recentRequests.isEmpty) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Column(
//           children: [
//             const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
//             const SizedBox(height: 8),
//             const Text(
//               'Unable to load service requests',
//               style: TextStyle(fontWeight: FontWeight.w600),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(_errorMessage!, textAlign: TextAlign.center),
//             const SizedBox(height: 12),
//             ElevatedButton.icon(
//               onPressed: _loadRecentRequests,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }
//
//     if (_recentRequests.isEmpty) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Column(
//           children: [
//             Icon(Icons.assignment_outlined, size: 40, color: Colors.blueGrey),
//             SizedBox(height: 10),
//             Text(
//               'No service requests yet',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             SizedBox(height: 4),
//             Text(
//               'Your requests will appear here.',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: _recentRequests.map((request) {
//         final category = request['category']?.toString() ?? 'Service request';
//
//         final status = request['status']?.toString() ?? 'pending';
//
//         final address = request['address']?.toString() ?? '';
//
//         final isSynced = _isSynced(request['is_synced']);
//
//         return Card(
//           margin: const EdgeInsets.only(bottom: 10),
//           child: ListTile(
//             leading: const CircleAvatar(
//               child: Icon(Icons.home_repair_service_outlined),
//             ),
//             title: Text(category),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 if (address.isNotEmpty) ...[
//                   const SizedBox(height: 4),
//                   Text(address),
//                 ],
//                 const SizedBox(height: 4),
//                 Text('Status: ${status.toUpperCase()}'),
//                 if (!isSynced)
//                   const Text(
//                     'Waiting to sync',
//                     style: TextStyle(color: Colors.orange),
//                   ),
//               ],
//             ),
//             isThreeLine: true,
//             onTap: () {
//               context.push('/customer/request-tracking', extra: request);
//             },
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return _buildRecentRequests();
//   }
// }
//
// class _CustomerDashboard extends StatefulWidget {
//   const _CustomerDashboard();
//
//   @override
//   State<_CustomerDashboard> createState() => _CustomerDashboardState();
// }
//
// class _CustomerDashboardState extends State<_CustomerDashboard> {
//   List<Map<String, dynamic>> _recentRequests = [];
//   bool _loadingRequests = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadRecentRequests();
//   }
//
//   Future<void> _loadRecentRequests() async {
//     try {
//       final user = getIt<AuthRepository>().currentUser;
//
//       if (user == null) {
//         if (mounted) {
//           setState(() => _loadingRequests = false);
//         }
//         return;
//       }
//
//       final requests = await getIt<ServiceRequestRepository>()
//           .getRecentRequests(user.id);
//
//       if (!mounted) return;
//
//       setState(() {
//         _recentRequests = requests;
//         _loadingRequests = false;
//       });
//     } catch (e) {
//       debugPrint('Unable to load requests: $e');
//
//       if (mounted) {
//         setState(() => _loadingRequests = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return CustomScrollView(
//       slivers: [
//         SliverPadding(
//           padding: const EdgeInsets.all(20),
//           sliver: SliverList(
//             delegate: SliverChildListDelegate([
//               // Header
//               Row(
//                 children: [
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'FixMate',
//                           style: TextStyle(
//                             fontSize: 26,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         SizedBox(height: 4),
//                         Text(
//                           'Home services made simple',
//                           style: TextStyle(color: Colors.blueGrey),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 28),
//
//               // Main action
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1769FF),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Need a repair?',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 22,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             'Book a service in a few steps.',
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(width: 12),
//                     Icon(
//                       Icons.home_repair_service_outlined,
//                       color: Colors.white,
//                       size: 42,
//                     ),
//                   ],
//                 ),
//               ),
//
//               const SizedBox(height: 16),
//
//               SizedBox(
//                 width: double.infinity,
//                 child: FilledButton.icon(
//                   onPressed: () {
//                     context.push('/customer/service-request');
//                   },
//                   icon: const Icon(Icons.add),
//                   label: const Text('Create Service Request'),
//                 ),
//               ),
//
//               const SizedBox(height: 28),
//
//               // Services
//               const Text(
//                 'Quick Services',
//                 style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 14),
//
//               Row(
//                 children: [
//                   Expanded(
//                     child: _ServiceCard(
//                       icon: Icons.electrical_services,
//                       title: 'Electrical',
//                       onTap: () {
//                         context.push(
//                           '/customer/service-request',
//                           extra: 'Electrical',
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _ServiceCard(
//                       icon: Icons.water_drop_outlined,
//                       title: 'Plumbing',
//                       onTap: () {
//                         context.push(
//                           '/customer/service-request',
//                           extra: 'Plumbing',
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _ServiceCard(
//                       icon: Icons.ac_unit,
//                       title: 'Appliance',
//                       onTap: () {
//                         context.push(
//                           '/customer/service-request',
//                           extra: 'Appliance',
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: _ServiceCard(
//                       icon: Icons.build_outlined,
//                       title: 'Other repairs',
//                       onTap: () {
//                         context.push(
//                           '/customer/service-request',
//                           extra: 'Other',
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//
//               const SizedBox(height: 28),
//
//               // Recent requests
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Recent Requests',
//                     style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
//                   ),
//                 ],
//               ),
//               _buildRecentRequests(),
//             ]),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildRecentRequests() {
//     if (_loadingRequests && _recentRequests.isEmpty) {
//       return const Center(
//         child: Padding(
//           padding: EdgeInsets.all(24),
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }
//
//     if (_recentRequests.isEmpty) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: const Column(
//           children: [
//             Icon(Icons.assignment_outlined, size: 40, color: Colors.blueGrey),
//             SizedBox(height: 10),
//             Text(
//               'No service requests yet',
//               style: TextStyle(fontWeight: FontWeight.w600),
//             ),
//             SizedBox(height: 4),
//             Text(
//               'Your requests will appear here.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: Colors.blueGrey),
//             ),
//           ],
//         ),
//       );
//     }
//
//     return Column(
//       children: _recentRequests.map((request) {
//         final category = request['category']?.toString() ?? 'Service request';
//         final status = request['status']?.toString().toLowerCase() ?? 'pending';
//         final address = request['address']?.toString() ?? '';
//
//         final isSynced =
//             request['is_synced'] == true || request['is_synced'] == 1;
//
//         final statusColor = switch (status) {
//           'completed' => Colors.green,
//           'assigned' => Colors.blue,
//           'in_progress' => Colors.orange,
//           'cancelled' => Colors.red,
//           _ => Colors.blueGrey,
//         };
//
//         return Card(
//           margin: const EdgeInsets.only(bottom: 12),
//           elevation: 0,
//           color: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//             side: const BorderSide(color: Color(0xFFE2E8F0)),
//           ),
//           clipBehavior: Clip.antiAlias,
//           child: InkWell(
//             onTap: () {
//               context.push('/customer/request-tracking', extra: request);
//             },
//             child: Padding(
//               padding: const EdgeInsets.all(14),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Container(
//                     width: 46,
//                     height: 46,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFEFF6FF),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Icon(
//                       Icons.home_repair_service_outlined,
//                       color: Color(0xFF2563EB),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           category,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         if (address.isNotEmpty) ...[
//                           const SizedBox(height: 5),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Icon(
//                                 Icons.location_on_outlined,
//                                 size: 16,
//                                 color: Colors.blueGrey,
//                               ),
//                               const SizedBox(width: 4),
//                               Expanded(
//                                 child: Text(
//                                   address,
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.blueGrey,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                         const SizedBox(height: 10),
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 6,
//                           crossAxisAlignment: WrapCrossAlignment.center,
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 10,
//                                 vertical: 5,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: statusColor.withValues(alpha: 0.10),
//                                 borderRadius: BorderRadius.circular(20),
//                               ),
//                               child: Text(
//                                 status.replaceAll('_', ' ').toUpperCase(),
//                                 style: TextStyle(
//                                   color: statusColor,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.w700,
//                                 ),
//                               ),
//                             ),
//                             if (!isSynced)
//                               const Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Icon(
//                                     Icons.sync,
//                                     size: 14,
//                                     color: Colors.orange,
//                                   ),
//                                   SizedBox(width: 4),
//                                   Text(
//                                     'Waiting to sync',
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.orange,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   const Icon(Icons.chevron_right, color: Colors.blueGrey),
//                 ],
//               ),
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   // Widget _buildRecentRequests() {
//   //   if (_loadingRequests && _recentRequests.isEmpty) {
//   //     return const Center(
//   //       child: Padding(
//   //         padding: EdgeInsets.all(24),
//   //         child: CircularProgressIndicator(),
//   //       ),
//   //     );
//   //   }
//   //
//   //   if (_recentRequests.isEmpty) {
//   //     return Container(
//   //       width: double.infinity,
//   //       padding: const EdgeInsets.all(24),
//   //       decoration: BoxDecoration(
//   //         border: Border.all(color: const Color(0xFFE2E8F0)),
//   //         borderRadius: BorderRadius.circular(16),
//   //       ),
//   //       child: const Column(
//   //         children: [
//   //           Icon(Icons.assignment_outlined, size: 40, color: Colors.blueGrey),
//   //           SizedBox(height: 10),
//   //           Text(
//   //             'No service requests yet',
//   //             style: TextStyle(fontWeight: FontWeight.w600),
//   //           ),
//   //           SizedBox(height: 4),
//   //           Text(
//   //             'Your requests will appear here.',
//   //             textAlign: TextAlign.center,
//   //           ),
//   //         ],
//   //       ),
//   //     );
//   //   }
//   //
//   //   return Column(
//   //     children: _recentRequests.map((request) {
//   //       final category = request['category']?.toString() ?? 'Service request';
//   //       final status = request['status']?.toString() ?? 'pending';
//   //       final address = request['address']?.toString() ?? '';
//   //
//   //       return GestureDetector(
//   //         onTap: () {
//   //           context.push('/customer/request-tracking', extra: request);
//   //         },
//   //         child: Card(
//   //           margin: const EdgeInsets.only(bottom: 10),
//   //           child: ListTile(
//   //             leading: const CircleAvatar(
//   //               child: Icon(Icons.home_repair_service_outlined),
//   //             ),
//   //             title: Text(category),
//   //             subtitle: Column(
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               children: [
//   //                 if (address.isNotEmpty) Text(address),
//   //                 const SizedBox(height: 4),
//   //                 Text('Status: ${status.toUpperCase()}'),
//   //                 if (request['is_synced'] == 0 ||
//   //                     request['is_synced'] == false)
//   //                   const Text(
//   //                     'Waiting to sync',
//   //                     style: TextStyle(color: Colors.orange),
//   //                   ),
//   //               ],
//   //             ),
//   //             isThreeLine: true,
//   //           ),
//   //         ),
//   //       );
//   //     }).toList(),
//   //   );
//   // }
// }
//
// class _ServiceCard extends StatelessWidget {
//   const _ServiceCard({
//     required this.icon,
//     required this.title,
//     required this.onTap,
//   });
//
//   final IconData icon;
//   final String title;
//   final VoidCallback onTap;
//
//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
//         decoration: BoxDecoration(
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Column(
//           children: [
//             Icon(icon, size: 30, color: const Color(0xFF1769FF)),
//             const SizedBox(height: 10),
//             Text(
//               title,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class _PlaceholderPage extends StatelessWidget {
//   const _PlaceholderPage({required this.title, required this.icon});
//
//   final String title;
//   final IconData icon;
//
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: 48, color: const Color(0xFF1769FF)),
//           const SizedBox(height: 12),
//           Text(
//             title,
//             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           const Text('Coming soon'),
//         ],
//       ),
//     );
//   }
// }
