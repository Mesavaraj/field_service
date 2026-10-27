import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodel/customer_request_tracking_view_model.dart';

class CustomerRequestTrackingPage extends StatelessWidget {
  final Map<String, dynamic> request;

  const CustomerRequestTrackingPage({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          CustomerRequestTrackingViewModel(request: request)..loadTasks(),
      child: const _TrackingContent(),
    );
  }
}

class _TrackingContent extends StatelessWidget {
  const _TrackingContent();

  static const primary = Color(0xFF1769FF);
  static const border = Color(0xFFE2E8F0);

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'on_the_way':
        return Colors.indigo;
      case 'cancelled':
        return Colors.red;
      case 'assigned':
        return primary;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(dynamic value, BuildContext context) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Not scheduled';
    }

    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();

    final local = date.toLocal();
    final dateText =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final timeText = TimeOfDay.fromDateTime(local).format(context);

    return '$dateText at $timeText';
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmCancel(
    BuildContext context,
    CustomerRequestTrackingViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this request?'),
        content: const Text(
          'Are you sure you want to cancel this service request? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep request'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel request'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await vm.cancelRequest();

    if (context.mounted) _message(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerRequestTrackingViewModel>(
      builder: (context, vm, child) {
        final request = vm.request;
        final statusColor = _statusColor(vm.status);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          appBar: AppBar(
            title: const Text('Track your request'),
            backgroundColor: const Color(0xFFF7F9FC),
            actions: [
              IconButton(
                tooltip: 'Refresh tasks',
                onPressed: vm.isLoadingTasks ? null : vm.refresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                // Request status card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1769FF), Color(0xFF4D8DFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.home_repair_service_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request['category']?.toString() ??
                                  'Service request',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Text(
                        vm.label(vm.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        vm.statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Request ID: ${vm.requestId.isEmpty ? '—' : vm.requestId}',
                          style: const TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (request['created_at'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Created: ${_formatDate(request['created_at'], context)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Cancellation
                if (vm.canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: vm.isCancelling
                          ? null
                          : () => _confirmCancel(context, vm),
                      icon: vm.isCancelling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cancel_outlined),
                      label: Text(
                        vm.isCancelling
                            ? 'Cancelling request…'
                            : 'Cancel request',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Technician section
                _sectionCard(
                  title: 'Technician',
                  icon: Icons.engineering_outlined,
                  child: _technicianContent(vm, statusColor),
                ),

                const SizedBox(height: 16),

                // Request progress timeline
                _sectionCard(
                  title: 'Request progress',
                  icon: Icons.timeline_outlined,
                  child: vm.isCancelled
                      ? const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                            size: 30,
                          ),
                          title: Text('Request cancelled'),
                          subtitle: Text('The service process has stopped.'),
                        )
                      : Column(
                          children: List.generate(vm.steps.length, (index) {
                            final step = vm.steps[index];
                            final active = step == vm.status;
                            final complete =
                                vm.currentStep >= 0 && index < vm.currentStep;
                            final isLast = index == vm.steps.length - 1;

                            final color = complete
                                ? Colors.green
                                : active
                                ? statusColor
                                : Colors.grey.shade400;

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 28,
                                  child: Column(
                                    children: [
                                      Icon(
                                        complete
                                            ? Icons.check_circle
                                            : active
                                            ? Icons.radio_button_checked
                                            : Icons.circle_outlined,
                                        color: color,
                                        size: 23,
                                      ),
                                      if (!isLast)
                                        Container(
                                          width: 2,
                                          height: 40,
                                          color: complete
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vm.label(step),
                                          style: TextStyle(
                                            fontWeight: active
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: active ? statusColor : null,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          complete
                                              ? 'Completed'
                                              : active
                                              ? 'Current status'
                                              : 'Waiting',
                                          style: const TextStyle(
                                            color: Colors.blueGrey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                ),

                const SizedBox(height: 16),

                // Service details
                _sectionCard(
                  title: 'Service details',
                  icon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      _detailRow(
                        Icons.build_outlined,
                        'Category',
                        request['category']?.toString() ?? 'Not provided',
                      ),
                      _detailRow(
                        Icons.location_on_outlined,
                        'Service address',
                        request['address']?.toString() ?? 'Not provided',
                      ),
                      _detailRow(
                        Icons.description_outlined,
                        'Problem description',
                        request['description']?.toString() ?? 'Not provided',
                      ),
                      _detailRow(
                        Icons.calendar_month_outlined,
                        'Preferred date',
                        _formatDate(request['preferred_date'], context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Assigned tasks',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                _tasksContent(context, vm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _technicianContent(
    CustomerRequestTrackingViewModel vm,
    Color statusColor,
  ) {
    if (vm.isLoadingTasks && !vm.hasLoadedTasks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    final assignedTask = vm.tasks.isEmpty ? null : vm.tasks.first;
    final technicianName = assignedTask?['technician_name']?.toString();
    final hasTechnician =
        technicianName != null && technicianName.trim().isNotEmpty;

    final title = vm.isCancelled
        ? 'Request cancelled'
        : hasTechnician
        ? technicianName
        : 'Technician not assigned';

    final subtitle = vm.isCancelled
        ? 'There is no active technician visit.'
        : hasTechnician
        ? 'Your service technician is assigned to this request.'
        : 'We will show technician details once one is assigned.';

    final color = vm.isCancelled
        ? Colors.red
        : hasTechnician
        ? primary
        : Colors.orange;

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(
                vm.isCancelled
                    ? Icons.cancel_outlined
                    : hasTechnician
                    ? Icons.engineering
                    : Icons.person_search_outlined,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'Technician',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      height: 1.35,
                    ),
                  ),
                  if (vm.taskError != null) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Could not load technician details.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tasksContent(
    BuildContext context,
    CustomerRequestTrackingViewModel vm,
  ) {
    if (vm.isLoadingTasks && !vm.hasLoadedTasks) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vm.taskError != null && !vm.hasLoadedTasks) {
      return _emptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load assigned tasks',
        message: 'Check your connection and try again.',
        action: TextButton(onPressed: vm.refresh, child: const Text('Retry')),
      );
    }

    if (vm.tasks.isEmpty) {
      return _emptyState(
        icon: Icons.assignment_outlined,
        title: 'No technician assigned yet',
        message: 'Assigned tasks will appear here once available.',
        action: vm.taskError != null
            ? TextButton(onPressed: vm.refresh, child: const Text('Retry'))
            : null,
      );
    }

    return Column(
      children: vm.tasks.map((task) {
        final name = task['technician_name']?.toString() ?? 'Technician';
        final status = task['status']?.toString().toLowerCase() ?? 'assigned';
        final scheduledAt = task['scheduled_at'];
        final notes = task['notes']?.toString() ?? '';
        final color = _statusColor(status);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: primary.withValues(alpha: 0.10),
                  child: const Icon(Icons.engineering_outlined, color: primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _taskInfo(
                        Icons.calendar_month_outlined,
                        'Appointment: ${_formatDate(scheduledAt, context)}',
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vm.label(status),
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      if (notes.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _taskInfo(Icons.notes_outlined, 'Notes: $notes'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskInfo(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 38, color: Colors.blueGrey),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.blueGrey),
            ),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }
}
