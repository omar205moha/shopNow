import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/screens/login_screen.dart';
import 'package:shop_now_mobile/services/location_service.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShopperDashboardScreen extends StatefulWidget {
  static const String routeName = '/shopperDashboardScreen';
  const ShopperDashboardScreen({super.key});

  @override
  State<ShopperDashboardScreen> createState() => _ShopperDashboardScreenState();
}

class _ShopperDashboardScreenState extends State<ShopperDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isMapView = false;
  MapController mapController = MapController();

  // Locations for navigation
  LatLng storeLocation = const LatLng(51.4821, -3.1811);
  LatLng deliveryLocation = const LatLng(51.4619, -3.1644);
  LatLng currentLocation = const LatLng(51.4750, -3.1750);

  // Firestore references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String _currentShopperId;
  bool isShopperVerified = false, _loading = false;

  // Stream controllers
  Stream<QuerySnapshot>? _pendingOrdersStream;
  Stream<QuerySnapshot>? _acceptedOrdersStream;
  Stream<QuerySnapshot>? _activeOrdersStream;
  Stream<QuerySnapshot>? _completedOrdersStream;

  final LocationService _locationService = LocationService();
  LatLng? _currentLocation;
  Stream<LatLng>? _locationStream;
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    _currentShopperId = _auth.currentUser?.uid ?? '';
    getShopperVerificationStatus();
    _tabController = TabController(length: 4, vsync: this);

    _initStreams();

    _initLocationService();
  }

  void _initLocationService() async {
    // Request permission
    bool hasPermission = await _locationService.requestLocationPermission();

    if (hasPermission) {
      // Get initial position
      _currentLocation = await _locationService.getCurrentLocation();

      if (_currentLocation != null) {
        await FirebaseFirestore.instance.collection('users').doc(_currentShopperId).update({
          "currentLocation": GeoPoint(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          )
        });
      }
      /*

      // Set up real-time location tracking
      _locationStream = _locationService.getLocationUpdates();
      _locationSubscription = _locationStream?.listen((LatLng position) async {
        setState(() {
          _currentLocation = position;
        });

        await FirebaseFirestore.instance.collection('users').doc(_currentShopperId).update({
          "currentLocation": GeoPoint(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
          )
        });
      });
   
   */
    }
  }

  getShopperVerificationStatus() async {
    setState(() {
      _loading = true;
    });
    final data = await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentShopperId)
        .collection('shopperProfile')
        .get();

    isShopperVerified = data.docs.first['verificationStatus'] == 'approved';

    setState(() {
      _loading = false;
    });
  }

  void _initStreams() {
    // Stream for pending orders (available to all shoppers)
    _pendingOrdersStream =
        _firestore.collection('orders').where('status', isEqualTo: 'pending').snapshots();

    // Stream for orders accpeted by this shopper
    _acceptedOrdersStream = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'accepted')
        .where('shopperRef',
            isEqualTo: FirebaseFirestore.instance.collection("users").doc(_currentShopperId))
        .snapshots();

    // Stream for in transit orders accepted to this shopper
    _activeOrdersStream = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'in_transit')
        .where('shopperRef',
            isEqualTo: FirebaseFirestore.instance.collection("users").doc(_currentShopperId))
        .snapshots();

    // Stream for completed orders by this shopper
    _completedOrdersStream = _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .where('shopperRef',
            isEqualTo: FirebaseFirestore.instance.collection("users").doc(_currentShopperId))
        // .orderBy('deliveredAt', descending: true)
        .snapshots();

    setState(() {});
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    try {
      // Update order in Firestore
      await _firestore.collection('orders').doc(order['id']).update({
        'status': "accepted",
        'shopperRef': FirebaseFirestore.instance.collection("users").doc(_currentShopperId),
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Succes",
        "Order ${order['id']} accepted! Navigation started.",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryMaterialColor,
      );
    } catch (e) {
      dev.log(" ==========> Error accepting order: $e ");
      Get.snackbar(
        "Error",
        "Error placing order: $e",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _startOrderDelivery(Map<String, dynamic> order) async {
    try {
      final shopId = order['shopRefs'].first.runtimeType == String
          ? order['shopRefs'].first.split('/').last
          : order['shopRefs'].first.path.split('/').last;

      final shop = await FirebaseFirestore.instance.collection("shops").doc(shopId).get();

      // Update order in Firestore
      await _firestore.collection('orders').doc(order['id']).update({
        'status': "in_transit",
        'pickedUpAt': FieldValue.serverTimestamp(),
      });

      // Update map locations for navigation
      setState(() {
        storeLocation = LatLng(
          shop['address']['location'].latitude,
          shop['address']['location'].longitude,
        );
        deliveryLocation = LatLng(
          order['deliveryLocation'].latitude,
          order['deliveryLocation'].longitude,
        );
        isMapView = true;
      });

      Get.snackbar(
        "Succes",
        "Order ${order['id']} accepted! Navigation started.",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryMaterialColor,
      );
    } catch (e) {
      dev.log(" ==========> Error accepting order: $e ");
      Get.snackbar(
        "Error",
        "Error placing order: $e",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

/*
  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    // In a real app, you might want to mark this order as rejected by this shopper
    // so it doesn't appear again in their list, but still allows other shoppers to take it
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['orderId']} rejected.'),
        backgroundColor: AppColors.alertColor,
      ),
    );
  }
*/

  Future<void> _completeOrder(Map<String, dynamic> order) async {
    try {
      // Update order in Firestore
      await _firestore.collection('orders').doc(order['id']).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        isMapView = false;
      });

      Get.snackbar(
        "Succes",
        'Order ${order['id']} completed!',
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: AppColors.primaryMaterialColor,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Error completing order: $e",
        snackPosition: SnackPosition.TOP,
        colorText: Colors.white,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Shopper Dashboard',
          style: Helper.getTheme(context).headlineLarge,
        ),
        actions: [
          IconButton(
            color: AppColors.primaryMaterialColor,
            icon: Icon(
              isMapView ? Icons.list : Icons.map,
            ),
            onPressed: () {
              setState(() {
                isMapView = !isMapView;
              });
            },
          ),
          IconButton(
            onPressed: () {
              AppDialogs.showConfirmDialog(
                messageText: 'Are you sure you want to sign out?',
                onYesTap: () async {
                  await FirebaseAuth.instance.signOut();
                  await GetStorage().erase();
                  Get.offAllNamed(LoginScreen.routeName);
                },
                yesButtonText: 'Yes',
                noButtonText: 'No',
              );
            },
            icon: Icon(
              Icons.logout_outlined,
              color: AppColors.primaryMaterialColor,
            ),
          ),
        ],
        bottom: !_loading && isShopperVerified
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryMaterialColor,
                labelColor: AppColors.primaryMaterialColor,
                unselectedLabelColor: AppColors.bodyTextColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                dividerHeight: .1,
                tabs: const [
                  Tab(text: 'PENDING'),
                  Tab(text: 'ACCEPTED'),
                  Tab(text: 'ACTIVE'),
                  Tab(text: 'COMPLETED'),
                ],
              )
            : null,
      ),
      body: _loading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: AppColors.orangeColor,
              ),
            )
          : !isShopperVerified
              ? Center(
                  child: Column(
                    spacing: 15,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.pending_actions,
                        size: 70.0,
                        color: AppColors.primaryMaterialColor,
                      ),
                      const Text(
                        "Your account is being verified",
                        style: TextStyle(fontSize: 20.0),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _activeOrdersStream,
                    builder: (context, snapshot) {
                      if (isMapView && snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        var activeOrder = _convertDocToMap(snapshot.data!.docs[0]);
                        return _buildMapViewWidget(activeOrder);
                      } else {
                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOrdersStreamList(
                              _pendingOrdersStream,
                              isPending: true,
                            ),
                            _buildOrdersStreamList(
                              _acceptedOrdersStream,
                              isActive: true,
                            ),
                            _buildOrdersStreamList(
                              _activeOrdersStream,
                              isIntransit: true,
                            ),
                            _buildOrdersStreamList(_completedOrdersStream),
                          ],
                        );
                      }
                    },
                  ),
                ),
    );
  }

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
                      'Order ${(activeOrder['id'] as String).substring(0, 7)}',
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

  Widget _buildOrdersStreamList(
    Stream<QuerySnapshot>? ordersStream, {
    bool isPending = false,
    bool isActive = false,
    bool isIntransit = false,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !isIntransit) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPending ? Icons.hourglass_empty : Icons.check_circle_outline,
                  size: 80,
                  color: AppColors.primaryMaterialColor,
                ),
                const SizedBox(height: 16),
                Text(
                  isPending
                      ? 'No pending orders'
                      : isActive
                          ? 'No active orders'
                          : isIntransit
                              ? 'No orders in transit'
                              : 'No completed orders yet',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Convert documents to list of maps
        final orders = snapshot.data!.docs.map((doc) => _convertDocToMap(doc)).toList();

        return ListView.builder(
          itemCount: orders.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order, isPending: isPending, isActive: isActive);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order,
      {bool isPending = false, bool isActive = false}) {
    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(order['buyerRef'].path.split('/').last).get(),
      builder: (context, customerSnapshot) {
        String customerName = 'Loading...';
        String customerPhone = '';

        if (customerSnapshot.hasData && customerSnapshot.data!.exists) {
          final customerData = customerSnapshot.data!.data() as Map<String, dynamic>;
          customerName = customerData['name']['first'] != null
              ? "${customerData['name']['first']} ${customerData['name']['last']}"
              : 'Unknown Customer';
          customerPhone = customerData['phone'] ?? '';
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ${order['id'].substring(0, 5)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: order['status'] == 'pending'
                            ? AppColors.blueSkyColor
                            : order['status'] == 'active'
                                ? Colors.green
                                : AppColors.primaryMaterialColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        order['status'] != null
                            ? order['status'] == 'in_transit'
                                ? 'On the way'
                                : order['status']?.toUpperCase()
                            : 'UNKNOWN',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaterialColor.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.store, color: AppColors.primaryMaterialColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['shopRefs']?.length} stores',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${order['items']?.length ?? 0} items · £${order['total'] ?? '0.00'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryMaterialColor.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: AppColors.primaryMaterialColor),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (isPending || isActive)
                          Text(
                            'Distance: ${order['distance'] ?? 'Unknown'} · Time: ${order['estimatedTime'] ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (isPending)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        /*  Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rejectOrder(order),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.alertColor,
                              side: const BorderSide(color: Colors.red),
                            ),
                            child: const Text('REJECT'),
                          ),
                        ),
                        const SizedBox(width: 16),*/
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _acceptOrder(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMaterialColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('ACCEPT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _startOrderDelivery(order);
                      },
                      icon: const Icon(
                        Icons.navigation,
                        color: AppColors.whiteColor,
                      ),
                      label: const Text('NAVIGATE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMaterialColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
