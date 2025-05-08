import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shop_now_mobile/const/app_colors.dart';

class LocationResult {
  final double lat;
  final double lng;
  final String address;
  LocationResult(this.lat, this.lng, this.address);
}

/// Dialog with an interactive OpenStreetMap picker.
class LocationPickerDialog extends StatefulWidget {
  const LocationPickerDialog({super.key});
  @override
  State<LocationPickerDialog> createState() => LocationPickerDialogState();
}

class LocationPickerDialogState extends State<LocationPickerDialog> {
  late LatLng _picked;
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    // Center initially on Cardiff
    _picked = const LatLng(51.4750, -3.1750);
    _mapController = MapController();
  }

  /// Uses Nominatim to reverse-geocode lat/lng into an address string.

  Future<String> _reverseGeocode(LatLng p) async {
    final dio = Dio();
    final url = 'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${p.latitude}&lon=${p.longitude}'
        '&accept-language=en';

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {'User-Agent': 'shop_now_app'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return (data['display_name'] as String?) ?? '${p.latitude}, ${p.longitude}';
      } else {
        log('Reverse geocoding failed with status: ${response.statusCode}');
        return '${p.latitude}, ${p.longitude} (Error)';
      }
    } catch (e) {
      log('Error during reverse geocoding: $e');
      return '${p.latitude}, ${p.longitude} (Error)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .5,
        child: Column(
          children: [
            // Map
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15.0), topRight: Radius.circular(15.0)),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _picked,
                    initialZoom: 13,
                    onTap: (_, latlng) => setState(() => _picked = latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _picked,
                          child: Icon(Icons.location_on,
                              color: AppColors.primaryMaterialColor, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Cancel / Select buttons
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      final addr = await _reverseGeocode(_picked);
                      Navigator.of(context).pop(LocationResult(
                        _picked.latitude,
                        _picked.longitude,
                        addr,
                      ));
                    },
                    child: const Text('Select Location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocationPickerInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String? value)? validator;
  final void Function(LocationResult location)? onLocationSelected;
  final bool enabled;
  final String? initialValue;
  final FormFieldState<String>? formFieldState;
  final AutovalidateMode autovalidateMode;

  const LocationPickerInput({
    super.key,
    this.controller,
    this.validator,
    this.onLocationSelected,
    this.enabled = true,
    this.initialValue,
    this.formFieldState,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });

  @override
  State<LocationPickerInput> createState() => _LocationPickerInputState();
}

class _LocationPickerInputState extends State<LocationPickerInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant LocationPickerInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && widget.controller != _controller) {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    // Dispose only the internal controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLocation() async {
    if (!widget.enabled) return;

    final result = await showDialog<LocationResult>(
      context: context,
      builder: (_) => const LocationPickerDialog(),
    );

    if (result != null) {
      _controller.text = result.address;
      widget.onLocationSelected?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _controller.text,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (FormFieldState<String> field) {
        // Keep track of changes to the controller
        _controller.addListener(() {
          if (field.value != _controller.text) {
            if (mounted) {
              field.didChange(_controller.text);
            }
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? AppColors.placeholderBg
                      : AppColors.placeholderBg.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(25),
                  border: field.hasError ? Border.all(color: Colors.red, width: 1.0) : null,
                ),
                alignment: Alignment.centerLeft,
                child: TextField(
                  controller: _controller,
                  enabled: false, // Always disabled as we use the GestureDetector
                  style: TextStyle(
                    color:
                        widget.enabled ? AppColors.greyDark : AppColors.greyDark.withOpacity(0.6),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Select a location',
                    hintStyle: TextStyle(color: AppColors.greyDark.withOpacity(0.6)),
                    border: InputBorder.none,
                    suffixIcon: Icon(
                      Icons.location_on,
                      color: widget.enabled ? AppColors.primaryMaterialColor : AppColors.greyLight,
                    ),
                  ),
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Text(
                  field.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}
