import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/di/service_locator.dart';
import '../../../repositorys/service_request_form_repository.dart';
import 'customer_home_view_model.dart';

class ServiceRequestViewModel extends ChangeNotifier {
  ServiceRequestViewModel({required this.category});

  final String category;
  final ServiceRequestFormRepository _repository =
      getIt<ServiceRequestFormRepository>();

  final formKey = GlobalKey<FormState>();

  final addressController = TextEditingController();
  final descriptionController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  final List<String> categories = const [
    'Electrical',
    'Plumbing',
    'AC Repair',
    'Appliance Repair',
    'Carpentry',
    'Other',
  ];

  String? selectedCategory;
  DateTime? preferredDate;
  double? latitude;
  double? longitude;

  bool isLoadingProfile = true;
  bool isGettingLocation = false;
  bool isSubmitting = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<String?> loadProfile() async {
    isLoadingProfile = true;
    _notify();

    if (category != null) selectedCategory = category;

    try {
      final profile = await _repository.loadProfile();

      if (_disposed) return null;

      addressController.text = profile['address']?.toString() ?? '';
      latitude = (profile['latitude'] as num?)?.toDouble();
      longitude = (profile['longitude'] as num?)?.toDouble();

      if (latitude != null && longitude != null) {
        await _fillAddressFromCoordinates(
          latitude!,
          longitude!,
          onlyFillEmpty: true,
        );
      }

      return null;
    } catch (e) {
      return 'Unable to load profile: $e';
    } finally {
      isLoadingProfile = false;
      _notify();
    }
  }

  Future<void> _fillAddressFromCoordinates(
    double lat,
    double lng, {
    bool onlyFillEmpty = false,
  }) async {
    try {
      final geocoding = Geocoding();
      final places = await geocoding.placemarkFromCoordinates(lat, lng);

      if (_disposed || places.isEmpty) return;

      final place = places.first;

      final city = (place.locality ?? '').trim().isNotEmpty
          ? place.locality!.trim()
          : (place.subAdministrativeArea ?? '').trim();

      final state = (place.administrativeArea ?? '').trim();
      final pin = (place.postalCode ?? '').trim();

      if (city.isNotEmpty &&
          (!onlyFillEmpty || cityController.text.trim().isEmpty)) {
        cityController.text = city;
      }

      if (state.isNotEmpty &&
          (!onlyFillEmpty || stateController.text.trim().isEmpty)) {
        stateController.text = state;
      }

      if (pin.isNotEmpty &&
          (!onlyFillEmpty || pincodeController.text.trim().isEmpty)) {
        pincodeController.text = pin;
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
  }

  Future<String> getCurrentLocation() async {
    isGettingLocation = true;
    _notify();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Please enable device location.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is required. Please enable it in settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_disposed) return 'Location request cancelled.';

      latitude = position.latitude;
      longitude = position.longitude;

      try {
        final geocoding = Geocoding();
        final places = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (!_disposed && places.isNotEmpty) {
          final place = places.first;

          final addressParts = <String>[
            if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
            if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
            if ((place.subLocality ?? '').trim().isNotEmpty)
              place.subLocality!.trim(),
          ];

          final fullAddress = addressParts.toSet().join(', ');
          if (fullAddress.isNotEmpty) {
            addressController.text = fullAddress;
          }
        }
      } catch (e) {
        debugPrint('Address lookup failed: $e');
      }

      await _fillAddressFromCoordinates(latitude!, longitude!);
      return 'Location detected. Please verify the address details.';
    } catch (e) {
      return 'Unable to get location: '
          '${e.toString().replaceFirst('Exception: ', '')}';
    } finally {
      isGettingLocation = false;
      _notify();
    }
  }

  void selectCategory(String? value) {
    selectedCategory = value;
    _notify();
  }

  void selectDate(DateTime? date) {
    preferredDate = date;
    _notify();
  }

  Future<String> submitRequest() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return 'Please correct the highlighted fields.';
    }

    if (selectedCategory == null) {
      return 'Please select a service category.';
    }

    isSubmitting = true;
    _notify();

    try {
      final requestData = <String, dynamic>{
        'category': selectedCategory,
        'description': descriptionController.text.trim(),
        'address': addressController.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'preferred_date': preferredDate?.toIso8601String(),
        'status': 'pending',
      };

      final isSynced = await _repository.submitRequest(requestData);
      await getIt<CustomerHomeViewModel>().refresh();

      if (isSynced) {
        return 'Service request submitted successfully.';
      }

      return 'Request saved locally. Synchronization is pending.';
    } catch (e) {
      return 'Unable to save request: '
          '${e.toString().replaceFirst('Exception: ', '')}';
    } finally {
      isSubmitting = false;
      _notify();
    }
  }

  void clearForm() {
    formKey.currentState?.reset();
    descriptionController.clear();
    addressController.clear();
    cityController.clear();
    stateController.clear();
    pincodeController.clear();

    selectedCategory = null;
    preferredDate = null;
    latitude = null;
    longitude = null;

    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    addressController.dispose();
    descriptionController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.dispose();
  }
}
