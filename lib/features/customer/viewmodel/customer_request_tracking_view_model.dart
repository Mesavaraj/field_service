import 'package:field_service/core/di/service_locator.dart';
import 'package:flutter/foundation.dart';

import '../../../repositorys/customer_request_tracking_repository.dart';

class CustomerRequestTrackingViewModel extends ChangeNotifier {
  CustomerRequestTrackingViewModel({required this.request});
  final Map<String, dynamic> request;
  final _repository = getIt<CustomerRequestTrackingRepository>();

  final List<String> steps = const [
    'pending',
    'assigned',
    'on_the_way',
    'in_progress',
    'completed',
  ];

  List<Map<String, dynamic>> tasks = [];

  bool isLoadingTasks = false;
  bool isCancelling = false;
  bool hasLoadedTasks = false;
  String? taskError;

  bool _disposed = false;

  static const primaryColorValue = 0xFF1769FF;

  String get status =>
      (request['status'] ?? 'pending').toString().toLowerCase().trim();

  bool get isCancelled => status == 'cancelled';

  bool get canCancel => const ['pending', 'assigned'].contains(status);

  int get currentStep => steps.indexOf(status);

  String get requestId => request['id']?.toString() ?? '';

  String get statusMessage {
    switch (status) {
      case 'assigned':
        return 'A technician has been assigned to your request.';
      case 'on_the_way':
        return 'Your technician is travelling to your location.';
      case 'in_progress':
        return 'Your technician is working on the service.';
      case 'completed':
        return 'Your service request has been completed.';
      case 'cancelled':
        return 'This request has been cancelled.';
      default:
        return 'Your request has been submitted and is awaiting assignment.';
    }
  }

  String label(String value) {
    switch (value.toLowerCase().trim()) {
      case 'pending':
        return 'Request submitted';
      case 'assigned':
        return 'Technician assigned';
      case 'on_the_way':
        return 'Technician on the way';
      case 'in_progress':
        return 'Job in progress';
      case 'completed':
        return 'Job completed';
      case 'cancelled':
        return 'Request cancelled';
      default:
        return value
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) => word.isEmpty
                  ? word
                  : '${word[0].toUpperCase()}${word.substring(1)}',
            )
            .join(' ');
    }
  }

  Future<void> loadTasks() async {
    if (_disposed) return;

    isLoadingTasks = true;
    taskError = null;
    _notify();

    try {
      if (requestId.isEmpty) {
        throw Exception('Request ID is missing.');
      }

      final result = await _repository.getCustomerTasks(requestId);

      if (_disposed) return;
      tasks = result;
      hasLoadedTasks = true;
    } catch (e) {
      if (_disposed) return;
      taskError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingTasks = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    await loadTasks();
  }

  Future<String> cancelRequest() async {
    if (!canCancel) {
      return 'This request can no longer be cancelled.';
    }

    if (requestId.isEmpty) {
      return 'Request ID is missing.';
    }

    isCancelling = true;
    _notify();

    try {
      await _repository.cancelRequest(requestId);

      request['status'] = 'cancelled';
      await loadTasks();

      return 'Service request cancelled.';
    } catch (e) {
      return 'Could not cancel request: '
          '${e.toString().replaceFirst('Exception: ', '')}';
    } finally {
      isCancelling = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
