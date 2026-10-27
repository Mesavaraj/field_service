import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/di/service_locator.dart';
import '../../../repositorys/customer_profile_repository.dart';

class CustomerProfileViewModel extends ChangeNotifier {
  CustomerProfileViewModel();

  final formKey = GlobalKey<FormState>();

  final _repository = getIt<CustomerProfileRepository>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  bool isLoading = true;
  bool isGettingLocation = false;
  bool isSaving = false;

  double? latitude;
  double? longitude;

  String? errorMessage;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<String?> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    _notify();

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final profile = await _repository.getProfile(user.id);

      if (_disposed) return null;

      nameController.text = profile['full_name']?.toString() ?? '';
      emailController.text = profile['email']?.toString() ?? '';
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
      errorMessage = 'Unable to load profile: $e';
      return errorMessage;
    } finally {
      isLoading = false;
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

      final state = place.administrativeArea?.trim() ?? '';
      final pin = place.postalCode?.trim() ?? '';

      if (!onlyFillEmpty || cityController.text.trim().isEmpty) {
        if (city.isNotEmpty) cityController.text = city;
      }

      if (!onlyFillEmpty || stateController.text.trim().isEmpty) {
        if (state.isNotEmpty) stateController.text = state;
      }

      if (!onlyFillEmpty || pincodeController.text.trim().isEmpty) {
        if (pin.isNotEmpty) pincodeController.text = pin;
      }
    } catch (e) {
      debugPrint('Reverse geocoding failed: $e');
    }
  }

  Future<String?> getCurrentLocation() async {
    isGettingLocation = true;
    _notify();

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();

      if (!enabled) {
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

      if (_disposed) return null;

      latitude = position.latitude;
      longitude = position.longitude;

      try {
        final geocoding = Geocoding();
        final places = await geocoding.placemarkFromCoordinates(
          latitude!,
          longitude!,
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
      return 'Unable to get location: $e';
    } finally {
      isGettingLocation = false;
      _notify();
    }
  }

  Future<String?> saveProfile() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return 'Please correct the highlighted fields.';
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return 'Please sign in again.';
    }

    isSaving = true;
    _notify();

    try {
      await _repository.saveProfile(
        userId: user.id,
        fullName: nameController.text.trim(),
        address: addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
      );

      return 'Profile saved online and offline.';
    } catch (e) {
      return 'Profile may be saved locally, but online sync failed: $e';
    } finally {
      isSaving = false;
      _notify();
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  void dispose() {
    _disposed = true;
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.dispose();
  }
}
