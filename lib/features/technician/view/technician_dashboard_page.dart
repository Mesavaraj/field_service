import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/di/service_locator.dart';
import '../../../models/technician_task_model.dart';
import '../viewmodel/technician_dashboard_viewmodel.dart';

class TechnicianDashboardPage extends StatelessWidget {
  const TechnicianDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TechnicianDashboardViewModel>(
      create: (_) => getIt<TechnicianDashboardViewModel>()..loadTasks(),
      child: const _TechnicianDashboardBody(),
    );
  }
}

class _TechnicianDashboardBody extends StatelessWidget {
  const _TechnicianDashboardBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianDashboardViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technician Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: vm.isLoading ? null : vm.loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {
              context.go('/technician/profile');
            },
            icon: const Icon(Icons.person_outline),
          ),
          //
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text('Welcome back!', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text(
              'Here is your service task overview.',
              style: theme.textTheme.bodyMedium,
            ),

            if (vm.isOffline) ...[
              const SizedBox(height: 12),
              const _InfoBanner(
                icon: Icons.cloud_off,
                message: 'Offline mode — showing saved tasks.',
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Assigned',
                    count: vm.assignedCount,
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'In Progress',
                    count: vm.inProgressCount,
                    icon: Icons.engineering_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    title: 'Completed',
                    count: vm.completedCount,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            Text('My Tasks', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'All',
                  value: 'all',
                  selected: vm.filter,
                  onSelected: vm.setFilter,
                ),
                _FilterChip(
                  label: 'Assigned',
                  value: 'assigned',
                  selected: vm.filter,
                  onSelected: vm.setFilter,
                ),
                _FilterChip(
                  label: 'In Progress',
                  value: 'in_progress',
                  selected: vm.filter,
                  onSelected: vm.setFilter,
                ),
                _FilterChip(
                  label: 'Completed',
                  value: 'completed',
                  selected: vm.filter,
                  onSelected: vm.setFilter,
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (vm.isLoading && vm.tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vm.error != null && vm.tasks.isEmpty)
              _ErrorPanel(message: vm.error!, onRetry: vm.loadTasks)
            else if (vm.filteredTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48),
                      SizedBox(height: 12),
                      Text('No tasks found.'),
                    ],
                  ),
                ),
              )
            else
              ...vm.filteredTasks.map((task) => _TaskCard(task: task)),

            if (vm.error != null && vm.tasks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Refresh failed. Showing previously loaded data.',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Column(
          children: [
            Icon(icon, size: 26),
            const SizedBox(height: 8),
            Text('$count', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 5),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TechnicianTaskModel task;

  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await context.push(
            '/technician/task-details/${Uri.encodeComponent(task.id)}',
          );

          if (!context.mounted) return;

          await getIt<TechnicianDashboardViewModel>().loadTasks();
        },
        // onTap: () {
        //   context.push(
        //     '/technician/task-details/${Uri.encodeComponent(task.id)}',
        //   );
        // },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(task.title, style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.normalizedStatus),
                ],
              ),

              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              if (task.address.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(task.address)),
                  ],
                ),
              ],

              if (task.preferredDate?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(task.preferredDate!),
                  ],
                ),
              ],

              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status.replaceAll('_', ' '),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;

  const _InfoBanner({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
