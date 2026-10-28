import 'dart:async';

import 'package:field_service/features/technician/view/technician_live_map.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/format_schedule.dart';
import '../viewmodel/technician_dashboard_viewmodel.dart';
import '../viewmodel/technician_task_details_viewmodel.dart';

class TechnicianTaskDetailsPage extends StatelessWidget {
  final String taskId;

  const TechnicianTaskDetailsPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TechnicianTaskDetailsViewModel>(
      create: (_) =>
          getIt<TechnicianTaskDetailsViewModel>(param1: taskId)..loadTask(),
      child: const _TaskDetailsBody(),
    );
  }
}

class _TaskDetailsBody extends StatelessWidget {
  const _TaskDetailsBody();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (val, v) async {
        await getIt<TechnicianDashboardViewModel>().loadTasks();
        context.go('/technician');
      },
      child: Consumer<TechnicianTaskDetailsViewModel>(
        builder: (context, vm, child) {
          final task = vm.task;

          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: const Text('Task Details'),
              centerTitle: false,
              actions: [
                IconButton(
                  tooltip: 'Refresh task',
                  onPressed: vm.isLoading ? null : vm.loadTask,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            body: vm.isLoading && task == null
                ? const Center(child: CircularProgressIndicator())
                : task == null
                ? _ErrorView(
                    message: vm.error ?? 'No task details found.',
                    onRetry: vm.loadTask,
                  )
                : RefreshIndicator(
                    onRefresh: vm.loadTask,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (vm.isOffline) ...[
                          const _OfflineBanner(),
                          const SizedBox(height: 16),
                        ],

                        _TaskHeader(
                          title: task.title,
                          id: task.id,
                          status: task.status,
                        ),
                        const SizedBox(height: 16),

                        _SectionCard(
                          title: 'Request information',
                          icon: Icons.assignment_outlined,
                          children: [
                            _DetailTile(
                              icon: Icons.description_outlined,
                              label: 'Description',
                              value: task.description,
                            ),
                            _DetailTile(
                              icon: Icons.person_outline_rounded,
                              label: 'Customer ID',
                              value: task.customerId,
                            ),
                            _DetailTile(
                              icon: Icons.calendar_month_outlined,
                              label: 'Preferred date',
                              value: task.preferredDate ?? 'Not specified',
                            ),
                            _DetailTile(
                              icon: Icons.event_available_rounded,
                              label: 'Scheduled job date & time',
                              value: formatSchedule(task.scheduledAt),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _SectionCard(
                          title: 'Service location',
                          icon: Icons.location_on_outlined,
                          children: [
                            _DetailTile(
                              icon: Icons.place_outlined,
                              label: 'Address',
                              value: task.address,
                            ),
                            if (task.latitude != null && task.longitude != null)
                              _DetailTile(
                                icon: Icons.gps_fixed_rounded,
                                label: 'Coordinates',
                                value: '${task.latitude}, ${task.longitude}',
                              ),
                            const SizedBox(height: 8),
                            if (task.latitude != null && task.longitude != null)
                              SizedBox(
                                height: 410,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: TechnicianLiveMapScreen(
                                    customerLatitude: task.latitude!,
                                    customerLongitude: task.longitude!,
                                    customerAddress: task.address,
                                    taskTitle: task.title,
                                    taskStatus: task.status,
                                    onOpenFullScreen: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                            appBar: AppBar(
                                              title: const Text(
                                                'Live Technician Tracking',
                                              ),
                                            ),
                                            body: SafeArea(
                                              child: TechnicianLiveMapScreen(
                                                customerLatitude:
                                                    task.latitude!,
                                                customerLongitude:
                                                    task.longitude!,
                                                customerAddress: task.address,
                                                taskTitle: task.title,
                                                taskStatus: task.status,
                                                fullScreen: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            else
                              const Text('Customer location is not available.'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (vm.error != null) ...[
                          Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (task.isAssigned)
                          FilledButton.icon(
                            onPressed: vm.isUpdating
                                ? null
                                : () =>
                                      _updateStatus(context, vm, 'in_progress'),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start Work'),
                          ),

                        if (task.isInProgress)
                          FilledButton.icon(
                            onPressed: vm.isUpdating
                                ? null
                                : () => _updateStatus(context, vm, 'completed'),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Complete Work'),
                          ),

                        if (task.isCompleted) const _CompletedBanner(),

                        if (vm.isUpdating) ...[
                          const SizedBox(height: 12),
                          const Center(child: CircularProgressIndicator()),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    TechnicianTaskDetailsViewModel vm,
    String status,
  ) async {
    try {
      final offline = await vm.updateStatus(status);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offline
                ? 'Status saved offline. It will sync when connected.'
                : 'Task status updated successfully.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }
}

class _TaskHeader extends StatelessWidget {
  final String title;
  final String id;
  final String status;

  const _TaskHeader({
    required this.title,
    required this.id,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.surfaceContainerHighest],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: colors.primary,
                child: Icon(Icons.handyman_outlined, color: colors.onPrimary),
              ),
              const Spacer(),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Request ID: $id',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final Color color = normalized == 'completed'
        ? Colors.green
        : normalized == 'in_progress'
        ? Colors.orange
        : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 5),
                SelectableText(
                  value.isEmpty ? 'Not provided' : value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMap extends StatefulWidget {
  final double? serviceLatitude;
  final double? serviceLongitude;

  const _LocationMap({
    required this.serviceLatitude,
    required this.serviceLongitude,
  });

  @override
  State<_LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<_LocationMap> {
  final MapController _mapController = MapController();

  Position? _technicianPosition;
  StreamSubscription<Position>? _subscription;
  bool _tracking = false;
  String? _locationError;

  bool get _hasServiceLocation =>
      widget.serviceLatitude != null &&
      widget.serviceLongitude != null &&
      widget.serviceLatitude!.isFinite &&
      widget.serviceLongitude!.isFinite &&
      widget.serviceLatitude! >= -90 &&
      widget.serviceLatitude! <= 90 &&
      widget.serviceLongitude! >= -180 &&
      widget.serviceLongitude! <= 180;

  LatLng get _initialCenter => _hasServiceLocation
      ? LatLng(widget.serviceLatitude!, widget.serviceLongitude!)
      : const LatLng(20.5937, 78.9629);

  Future<void> _toggleTracking() async {
    if (_tracking) {
      await _subscription?.cancel();
      _subscription = null;

      if (!mounted) return;
      setState(() => _tracking = false);
      return;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Enable your device location services first.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is denied. Allow location access in settings.',
        );
      }

      final current = await Geolocator.getCurrentPosition();
      if (!mounted) return;

      setState(() {
        _technicianPosition = current;
        _tracking = true;
        _locationError = null;
      });

      _subscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (position) {
              if (!mounted) return;
              setState(() => _technicianPosition = position);
            },
            onError: (Object error) {
              if (!mounted) return;
              setState(() {
                _locationError = 'Location tracking error: $error';
                _tracking = false;
              });
            },
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _locationError = error.toString());
    }
  }

  void _centerOnTechnician() {
    final position = _technicianPosition;
    if (position == null) return;

    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _technicianPosition;

    final markers = <Marker>[
      if (_hasServiceLocation)
        Marker(
          point: LatLng(widget.serviceLatitude!, widget.serviceLongitude!),
          width: 48,
          height: 48,
          child: const Icon(Icons.location_on, color: Colors.red, size: 42),
        ),
      if (position != null)
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 48,
          height: 48,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 34),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: _hasServiceLocation ? 15 : 5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fsm',
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        if (!_hasServiceLocation)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Service coordinates are not available. Showing the general map.',
            ),
          ),
        if (position != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Your location: ${position.latitude.toStringAsFixed(5)}, '
              '${position.longitude.toStringAsFixed(5)}',
            ),
          ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _locationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _toggleTracking,
                icon: Icon(
                  _tracking ? Icons.stop_circle_outlined : Icons.gps_fixed,
                ),
                label: Text(_tracking ? 'Stop tracking' : 'Start live GPS'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Center on technician',
              onPressed: position == null ? null : _centerOnTechnician,
              icon: const Icon(Icons.my_location),
            ),
          ],
        ),
      ],
    );
  }
}

class _LiveLocationControls extends StatelessWidget {
  const _LiveLocationControls();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Use the map above to start or stop GPS tracking. '
      'Your current position will update while tracking is active.',
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('Offline mode'),
        subtitle: Text(
          'Showing saved task data. Pending updates will retry later.',
        ),
      ),
    );
  }
}

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('Task completed'),
        subtitle: Text('This task has been marked completed.'),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../../core/di/service_locator.dart';
// import '../viewmodel/technician_task_details_viewmodel.dart';
//
// class TechnicianTaskDetailsPage extends StatelessWidget {
//   final String taskId;
//
//   const TechnicianTaskDetailsPage({super.key, required this.taskId});
//
//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider<TechnicianTaskDetailsViewModel>(
//       create: (_) =>
//           getIt<TechnicianTaskDetailsViewModel>(param1: taskId)..loadTask(),
//       child: const _TaskDetailsBody(),
//     );
//   }
// }
//
// // /// Allows the page to create a task-specific ViewModel through GetIt.
// // abstract class TaskDetailsViewModelFactory {
// //   TechnicianTaskDetailsViewModel create(String taskId);
// // }
//
// // class _TaskDetailsBody extends StatelessWidget {
// //   const _TaskDetailsBody();
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final vm = context.watch<TechnicianTaskDetailsViewModel>();
// //     final task = vm.task;
// //
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('Task Details')),
// //       body: _buildBody(context, vm, task),
// //     );
// //   }
// //
// //   Widget _buildBody(
// //     BuildContext context,
// //     TechnicianTaskDetailsViewModel vm,
// //     TechnicianTaskModel? task,
// //   ) {
// //     if (vm.isLoading && task == null) {
// //       return const Center(child: CircularProgressIndicator());
// //     }
// //
// //     if (task == null) {
// //       return Center(
// //         child: Padding(
// //           padding: const EdgeInsets.all(24),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               const Icon(Icons.error_outline, size: 48),
// //               const SizedBox(height: 12),
// //               Text(vm.error ?? 'Unable to load task.'),
// //               const SizedBox(height: 12),
// //               FilledButton(onPressed: vm.loadTask, child: const Text('Retry')),
// //             ],
// //           ),
// //         ),
// //       );
// //     }
// //
// //     return RefreshIndicator(
// //       onRefresh: vm.loadTask,
// //       child: ListView(
// //         physics: const AlwaysScrollableScrollPhysics(),
// //         padding: const EdgeInsets.all(16),
// //         children: [
// //           if (vm.isOffline)
// //             const Card(
// //               child: ListTile(
// //                 leading: Icon(Icons.cloud_off_outlined),
// //                 title: Text('Offline mode'),
// //                 subtitle: Text(
// //                   'Showing saved task data. Pending updates will retry later.',
// //                 ),
// //               ),
// //             ),
// //           Card(
// //             child: Padding(
// //               padding: const EdgeInsets.all(16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     task.title,
// //                     style: Theme.of(context).textTheme.headlineSmall,
// //                   ),
// //                   const SizedBox(height: 12),
// //                   _StatusChip(status: task.normalizedStatus),
// //                   const Divider(height: 28),
// //                   _DetailRow(
// //                     icon: Icons.description_outlined,
// //                     label: 'Description',
// //                     value: task.description,
// //                   ),
// //                   _DetailRow(
// //                     icon: Icons.person_outline,
// //                     label: 'Customer ID',
// //                     value: task.customerId,
// //                   ),
// //                   _DetailRow(
// //                     icon: Icons.location_on_outlined,
// //                     label: 'Service address',
// //                     value: task.address,
// //                   ),
// //                   _DetailRow(
// //                     icon: Icons.calendar_today_outlined,
// //                     label: 'Preferred date',
// //                     value: task.preferredDate ?? 'Not specified',
// //                   ),
// //                   if (task.latitude != null && task.longitude != null)
// //                     _DetailRow(
// //                       icon: Icons.my_location,
// //                       label: 'Coordinates',
// //                       value: '${task.latitude}, ${task.longitude}',
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ),
// //           const SizedBox(height: 20),
// //           if (vm.error != null)
// //             Padding(
// //               padding: const EdgeInsets.only(bottom: 12),
// //               child: Text(
// //                 vm.error!,
// //                 style: TextStyle(color: Theme.of(context).colorScheme.error),
// //               ),
// //             ),
// //           if (task.isAssigned)
// //             FilledButton.icon(
// //               onPressed: vm.isUpdating
// //                   ? null
// //                   : () => _updateStatus(context, vm, 'in_progress'),
// //               icon: const Icon(Icons.play_arrow),
// //               label: const Text('Start Work'),
// //             ),
// //           if (task.isInProgress)
// //             FilledButton.icon(
// //               onPressed: vm.isUpdating
// //                   ? null
// //                   : () => _updateStatus(context, vm, 'completed'),
// //               icon: const Icon(Icons.check_circle_outline),
// //               label: const Text('Complete Work'),
// //             ),
// //           if (task.isCompleted)
// //             const Card(
// //               child: ListTile(
// //                 leading: Icon(Icons.check_circle, color: Colors.green),
// //                 title: Text('Task completed'),
// //                 subtitle: Text('This task has been marked completed.'),
// //               ),
// //             ),
// //           if (vm.isUpdating)
// //             const Padding(
// //               padding: EdgeInsets.all(16),
// //               child: Center(child: CircularProgressIndicator()),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Future<void> _updateStatus(
// //     BuildContext context,
// //     TechnicianTaskDetailsViewModel vm,
// //     String status,
// //   ) async {
// //     try {
// //       final offline = await vm.updateStatus(status);
// //
// //       if (!context.mounted) return;
// //
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         SnackBar(
// //           content: Text(
// //             offline
// //                 ? 'Status saved offline. It will sync when connected.'
// //                 : 'Task status updated.',
// //           ),
// //         ),
// //       );
// //     } catch (e) {
// //       if (!context.mounted) return;
// //
// //       ScaffoldMessenger.of(context)
// //           .showSnackBar(SnackBar(content: Text('Update failed: $e')));
// //     }
// //   }
// // }
// class _TaskDetailsBody extends StatelessWidget {
//   const _TaskDetailsBody();
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<TechnicianTaskDetailsViewModel>(
//       builder: (context, vm, child) {
//         if (vm.isLoading) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator()),
//           );
//         }
//
//         if (vm.error != null) {
//           return Scaffold(
//             appBar: AppBar(title: const Text('Task Details')),
//             body: Center(child: Text(vm.error!)),
//           );
//         }
//
//         final task = vm.task;
//
//         if (task == null) {
//           return Scaffold(
//             appBar: AppBar(title: const Text('Task Details')),
//             body: const Center(child: Text('No task details found.')),
//           );
//         }
//
//         return Scaffold(
//           appBar: AppBar(title: const Text('Task Details')),
//           body: ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               Text('Task ID: ${task.id}'),
//               const SizedBox(height: 12),
//               Text('Title: ${task.title}'),
//               const SizedBox(height: 12),
//               Text('Description: ${task.description}'),
//               const SizedBox(height: 12),
//               Text('Status: ${task.status}'),
//               const SizedBox(height: 12),
//               Text('Address: ${task.address}'),
//               const SizedBox(height: 12),
//               Text('Customer ID: ${task.customerId}'),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// // class _DetailRow extends StatelessWidget {
// //   final IconData icon;
// //   final String label;
// //   final String value;
// //
// //   const _DetailRow({
// //     required this.icon,
// //     required this.label,
// //     required this.value,
// //   });
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Padding(
// //       padding: const EdgeInsets.only(bottom: 16),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Icon(icon, size: 20),
// //           const SizedBox(width: 12),
// //           Expanded(
// //             child: Column(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Text(label, style: Theme.of(context).textTheme.labelMedium),
// //                 const SizedBox(height: 4),
// //                 SelectableText(value.isEmpty ? 'Not provided' : value),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }
// //
// // class _StatusChip extends StatelessWidget {
// //   final String status;
// //
// //   const _StatusChip({required this.status});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Chip(
// //       avatar: const Icon(Icons.circle, size: 10),
// //       label: Text(status.replaceAll('_', ' ')),
// //     );
// //   }
// // }
