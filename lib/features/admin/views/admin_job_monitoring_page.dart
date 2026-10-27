import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/job_monitoring_view_model.dart';

class AdminJobMonitoringPage extends StatefulWidget {
  const AdminJobMonitoringPage({super.key});

  @override
  State<AdminJobMonitoringPage> createState() => _AdminJobMonitoringPageState();
}

class _AdminJobMonitoringPageState extends State<AdminJobMonitoringPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JobMonitoringViewModel>().loadJobs();
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
        title: const Text('Job Monitoring'),
        actions: [
          IconButton(
            tooltip: 'Refresh jobs',
            onPressed: () => context.read<JobMonitoringViewModel>().refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<JobMonitoringViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.allJobs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.errorMessage != null && vm.allJobs.isEmpty) {
            return _buildError(vm);
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummary(vm),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: vm.searchJobs,
                  decoration: InputDecoration(
                    hintText: 'Search job, request, technician or address',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              vm.searchJobs('');
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: vm.selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter by status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All jobs')),
                    DropdownMenuItem(
                      value: 'assigned',
                      child: Text('Assigned'),
                    ),
                    DropdownMenuItem(
                      value: 'accepted',
                      child: Text('Accepted'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('In progress'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completed'),
                    ),
                    DropdownMenuItem(
                      value: 'cancelled',
                      child: Text('Cancelled'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      vm.filterByStatus(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'Jobs (${vm.filteredJobs.length})',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (vm.filteredJobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.work_off_outlined,
                          size: 52,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text('No jobs found'),
                      ],
                    ),
                  )
                else
                  ...vm.filteredJobs.map((job) => _buildJobCard(context, job)),
                if (vm.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Refresh failed: ${vm.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary(JobMonitoringViewModel vm) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 650 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: [
        _summaryCard('Total jobs', vm.totalJobs, Colors.blue),
        _summaryCard('Active jobs', vm.activeJobs, Colors.orange),
        _summaryCard('Completed', vm.completedJobs, Colors.green),
        _summaryCard('Cancelled', vm.cancelledJobs, Colors.red),
      ],
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, Map<String, dynamic> job) {
    final status = (job['status'] ?? 'unknown').toString();
    final scheduledAt = job['scheduled_at']?.toString();
    final scheduledDate = scheduledAt == null
        ? 'Not scheduled'
        : _formatDate(scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showJobDetails(context, job),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.build_circle_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      (job['category'] ?? 'Service job').toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 10),
              _detailRow(
                Icons.engineering,
                'Technician',
                (job['technician_name'] ?? 'Unknown').toString(),
              ),
              _detailRow(
                Icons.location_on_outlined,
                'Address',
                (job['address'] ?? 'Unavailable').toString(),
              ),
              _detailRow(Icons.calendar_month, 'Appointment', scheduledDate),
              const SizedBox(height: 5),
              Text(
                'Task ID: ${job['id']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Text('$label: '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();

    final Color color = switch (normalized) {
      'completed' => Colors.green,
      'in_progress' => Colors.orange,
      'accepted' => Colors.blue,
      'cancelled' => Colors.red,
      'assigned' => Colors.indigo,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> job) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Job Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogRow('Task ID', job['id']),
              _dialogRow('Request ID', job['service_request_id']),
              _dialogRow('Category', job['category']),
              _dialogRow('Address', job['address']),
              _dialogRow('Technician', job['technician_name']),
              _dialogRow('Technician ID', job['technician_id']),
              _dialogRow('Status', job['status']),
              _dialogRow(
                'Appointment',
                job['scheduled_at'] == null
                    ? 'Not scheduled'
                    : _formatDate(job['scheduled_at'].toString()),
              ),
              _dialogRow('Notes', job['notes']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text('$label: ${value ?? 'Not available'}'),
    );
  }

  Widget _buildError(JobMonitoringViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text('Unable to load jobs'),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
