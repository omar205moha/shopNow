/*
Widget _buildMapViewWidget(Map<String, dynamic> activeOrder) {
  return FutureBuilder<Widget>(
    future: _buildMapView(activeOrder),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // Show loading indicator while we wait for the route data
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (snapshot.hasError) {
        // Handle errors
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('Error loading map: ${snapshot.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Refresh function - you can implement this
                  // or use setState to trigger a rebuild
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      } else if (snapshot.hasData) {
        // Return the map view
        return snapshot.data!;
      } else {
        // Fallback for when we have no data yet
        return const Center(
          child: Text('No active order data available'),
        );
      }
    },
  );
}

Map<String, dynamic> _convertDocToMap(DocumentSnapshot doc) {
  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
  // Add the document ID to the map for easier reference
  data['id'] = doc.id;
  return data;
}

// This function now returns Future<Widget> instead of Widget
Future<Widget> _buildMapView(Map<String, dynamic> activeOrder) async {
  LatLng storeLocation = const LatLng(0, 0); // Default value
  LatLng deliveryLocation = const LatLng(0, 0); // Default value

  try {
    // Get shop reference from the order
    final shopId = activeOrder['shopRefs']?.first.runtimeType == String
        ? activeOrder['shopRefs']?.first?.split('/')?.last
        : activeOrder['shopRefs']?.first?.path.split('/')?.last;
    final customerId = activeOrder['buyerRef']?.path?.split('/')?.last;
    final customer = await FirebaseFirestore.instance.collection("users").doc(customerId).get();
    DocumentSnapshot<Map<String, dynamic>>? shop;
    if (shopId != null) {
      shop = await FirebaseFirestore.instance.collection("shops").doc(shopId).get();

      // Extract coordinates from GeoPoint
      if (shop.data() != null &&
          shop.data()!['address'] != null &&
          shop.data()!['address']['location'] != null) {
        final GeoPoint geoPoint = shop.data()!['address']['location'];
        storeLocation = LatLng(
          geoPoint.latitude,
          geoPoint.longitude,
        );
      }
    }

    // Extract delivery location
    if (activeOrder['deliveryLocation'] != null) {
      final GeoPoint deliveryGeoPoint = activeOrder['deliveryLocation'];
      deliveryLocation = LatLng(
        deliveryGeoPoint.latitude,
        deliveryGeoPoint.longitude,
      );
    }

    // Get current location (you may need to adapt this based on how you track location)
    LatLng currentLocation = await _getCurrentLocation();

    // Fetch route points from an external API
    List<LatLng> routePoints =
        await _fetchRoutePoints(storeLocation, currentLocation, deliveryLocation);

    // Now return the actual widget
    return Column(
      children: [
        // Order information card
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primaryMaterialColor.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${activeOrder['orderId'] ?? activeOrder['id']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaterialColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'IN PROGRESS',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.store,
                    size: 16,
                    color: AppColors.primaryMaterialColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Store: ${shop?['name'] ?? 'Unknown Store'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.primaryMaterialColor),
                  const SizedBox(width: 4),
                  Text(
                    'Customer: ${customer['name']['first'] != null ? "${customer['name']['first']} ${customer['name']['last']}" : 'Unknown Customer'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.shopping_bag, size: 16, color: AppColors.primaryMaterialColor),
                  const SizedBox(width: 4),
                  Text(
                    '${activeOrder['items'].length ?? 0} items · £${activeOrder['total'] ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Map
        Expanded(
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Route polylines - Show two route segments
              PolylineLayer(
                polylines: [
                  // First segment: Store to Current Location
                  Polyline(
                    points: _getRouteSegment(routePoints, storeLocation, currentLocation),
                    strokeWidth: 4.0,
                    color: AppColors.primaryMaterialColor.withOpacity(0.7),
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.0,
                  ),
                  // Second segment: Current Location to Delivery Point
                  Polyline(
                    points: _getRouteSegment(routePoints, currentLocation, deliveryLocation),
                    strokeWidth: 4.0,
                    color: AppColors.primaryMaterialColor,
                    borderColor: Colors.white,
                    borderStrokeWidth: 1.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Store marker
                  Marker(
                    point: storeLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.store,
                      color: Colors.blue,
                      size: 30,
                    ),
                  ),

                  // Delivery location marker
                  Marker(
                    point: deliveryLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 30,
                    ),
                  ),

                  // Current location marker
                  Marker(
                    point: currentLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaterialColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_bike,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Navigation controls
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.directions, color: AppColors.primaryMaterialColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next stop',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          activeOrder['deliveryAddress'] ?? 'Unknown Address',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Distance',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        '${activeOrder['distance'] ?? 'Unknown'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Call customer - ideally retrieve from user document
                        final phoneNumber = activeOrder['customerPhone'];
                        if (phoneNumber != null) {
                          // Implement call functionality
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer phone number not available'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.phone,
                      ),
                      label: const Text(
                        'CALL',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.primaryMaterialColor,
                        ),
                        iconColor: AppColors.primaryMaterialColor,
                        foregroundColor: AppColors.primaryMaterialColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _completeOrder(activeOrder),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaterialColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'COMPLETE DELIVERY',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  } catch (error) {
    // Return an error widget if something goes wrong
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text('Error: ${error.toString()}'),
        ],
      ),
    );
  }
}

// Helper method to fetch route points from an external API
Future<List<LatLng>> _fetchRoutePoints(LatLng start, LatLng middle, LatLng end) async {
  try {
    // First route: Start to Middle
    final routeStartToMiddle = await _getRoutePoints(start, middle);

    // Second route: Middle to End
    final routeMiddleToEnd = await _getRoutePoints(middle, end);

    // Combine routes
    final combinedRoute = [...routeStartToMiddle, ...routeMiddleToEnd];

    return combinedRoute;
  } catch (e) {
    print('Error fetching route: $e');
    // Fallback to straight line if routing fails
    return [start, middle, end];
  }
}

// Method to get route points between two coordinates
Future<List<LatLng>> _getRoutePoints(LatLng start, LatLng end) async {
  try {
    const apiKey = 'YOUR_OPENROUTESERVICE_API_KEY';
    const url = 'https://api.openrouteservice.org/v2/directions/driving-car';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': apiKey,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json, application/geo+json, application/gpx+xml'
      },
      body: jsonEncode({
        'coordinates': [
          [start.longitude, start.latitude],
          [end.longitude, end.latitude]
        ],
        'format': 'geojson'
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coordinates = data['features'][0]['geometry']['coordinates'] as List;

      // Convert to LatLng format
      return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
    } else {
      throw Exception('Failed to load route: ${response.statusCode}');
    }
  } catch (e) {
    dev.log(' =======> Error in route API call: $e');

    // OPTION 2: Fallback to a simplified route (if API fails)
    // Generate intermediate points along the straight line
    // This gives at least some curvature to make it look more like a road

    const int pointCount = 10; // Number of intermediate points
    List<LatLng> points = [];

    for (int i = 0; i <= pointCount; i++) {
      double fraction = i / pointCount;
      double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      double lng = start.longitude + (end.longitude - start.longitude) * fraction;

      // Add some slight randomness to make it look more like a road
      // Only do this for the middle points, not start and end
      if (i > 0 && i < pointCount) {
        // Small random offset (±0.0005 degrees, roughly 50 meters)
        double latOffset = (Random().nextDouble() - 0.5) * 0.0005;
        double lngOffset = (Random().nextDouble() - 0.5) * 0.0005;
        lat += latOffset;
        lng += lngOffset;
      }

      points.add(LatLng(lat, lng));
    }

    return points;
  }
}

// Helper method to get the current location
Future<LatLng> _getCurrentLocation() async {
  if (_currentLocation != null) {
    return _currentLocation!;
  }
  final location = await _locationService.getCurrentLocation();
  if (location != null) {
    setState(() {
      _currentLocation = location;
    });

    return location;
  }

  return const LatLng(51.4816, -3.1791);
}

// Helper method to extract a segment of the route between two points
List<LatLng> _getRouteSegment(List<LatLng> routePoints, LatLng start, LatLng end) {
  return routePoints;
}
*/
