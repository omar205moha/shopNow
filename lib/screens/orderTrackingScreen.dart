import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/utils/helper.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderTrackingScreen extends StatefulWidget {
  static const String routeName = '/orderTrackingScreen';

  const OrderTrackingScreen({
    super.key,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late String orderId;
  late MapController mapController;
  StreamSubscription<DocumentSnapshot>? orderSubscription;
  StreamSubscription<DocumentSnapshot>? shopperLocationSubscription;

  DocumentSnapshot? orderSnapshot;
  Map<String, dynamic>? orderData;
  DocumentSnapshot? shopSnapshot;
  DocumentSnapshot? shopperSnapshot;
  DocumentSnapshot? buyerSnapshot;

  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    mapController = MapController();

    // Get arguments passed via navigator
    final args = Get.arguments as Map<String, dynamic>;
    orderId = args['orderId'] as String;

    // Start listening to order updates
    _initializeOrderTracking();
  }

  Future<void> _initializeOrderTracking() async {
    try {
      // Get current user (buyer) ID
      final buyerId = FirebaseAuth.instance.currentUser?.uid;
      if (buyerId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User not authenticated';
        });
        return;
      }

      // Get buyer data
      final buyerDoc = FirebaseFirestore.instance.collection("users").doc(buyerId);
      buyerSnapshot = await buyerDoc.get();

      // Start listening to order updates
      final orderRef = FirebaseFirestore.instance.collection("orders").doc(orderId);
      orderSubscription = orderRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists) {
          setState(() {
            isLoading = false;
            errorMessage = 'Order not found';
          });
          return;
        }

        orderSnapshot = snapshot;
        orderData = snapshot.data() as Map<String, dynamic>;

        // Get shop data
        if (orderData!.containsKey('shopRefs')) {
          final shopRef = orderData!['shopRefs'].first;
          String shopId;

          if (shopRef is String && shopRef.contains('/')) {
            shopId = shopRef.split('/').last;
          } else if (shopRef != null && shopRef.path != null) {
            shopId = shopRef.path.split('/').last;
          } else if (orderData!.containsKey('shopRefs') &&
              orderData!['shopRefs'] is List &&
              orderData!['shopRefs'].isNotEmpty) {
            final firstShopRef = orderData!['shopRefs'][0];
            if (firstShopRef is String && firstShopRef.contains('/')) {
              shopId = firstShopRef.split('/').last;
            } else {
              shopId = firstShopRef.path.split('/').last;
            }
          } else {
            setState(() {
              isLoading = false;
              errorMessage = 'Shop reference not found in order';
            });
            return;
          }

          final shopDoc = await FirebaseFirestore.instance.collection("shops").doc(shopId).get();
          shopSnapshot = shopDoc;
        }

        // Get shopper data and subscribe to their location
        if (orderData!.containsKey('shopperId') || orderData!.containsKey('shopperRef')) {
          String shopperId;

          if (orderData!.containsKey('shopperId')) {
            shopperId = orderData!['shopperId'];
          } else {
            final shopperRef = orderData!['shopperRef'];
            if (shopperRef is String) {
              shopperId = shopperRef.split('/').last;
            } else {
              shopperId = shopperRef.path.split('/').last;
            }
          }

          // Get initial shopper data
          final shopperDoc =
              await FirebaseFirestore.instance.collection("users").doc(shopperId).get();
          shopperSnapshot = shopperDoc;

          // Subscribe to shopper's location
          if (shopperLocationSubscription != null) {
            await shopperLocationSubscription!.cancel();
          }

          shopperLocationSubscription = FirebaseFirestore.instance
              .collection("users")
              .doc(shopperId)
              .snapshots()
              .listen((shopperData) {
            setState(() {
              shopperSnapshot = shopperData;
            });
          });
        }

        setState(() {
          isLoading = false;
        });
      }, onError: (error) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading order: $error';
        });
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error initializing tracking: $e';
      });
    }
  }

  @override
  void dispose() {
    orderSubscription?.cancel();
    shopperLocationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
        title: Text(
          'Order Tracking',
          style: Helper.getTheme(context).headlineLarge,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? _buildErrorWidget()
              : _buildOrderTrackingContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(errorMessage),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isLoading = true;
                errorMessage = '';
              });
              _initializeOrderTracking();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTrackingContent() {
    if (orderData == null) {
      return const Center(child: Text('No order data available'));
    }

    // Get order status
    final orderStatus = orderData!['status'] ?? 'Processing';

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
                    'Order ${orderData!['orderId'] ?? orderId.substring(0, 8)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(orderStatus),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      orderStatus == 'in_transit' ? "On the way" : orderStatus.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                    'Store: ${(shopSnapshot?.data() as Map<String, dynamic>)['name'] ?? 'Loading...'}',
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
                    '${orderData!['items']?.length ?? 0} items · £${orderData!['total']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (orderData!['estimatedDeliveryTime'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.primaryMaterialColor),
                    const SizedBox(width: 4),
                    Text(
                      'Est. Delivery: ${_formatEstimatedTime(orderData!['estimatedDeliveryTime'])}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Map and tracking information
        Expanded(
          child: _buildTrackingView(),
        ),
      ],
    );
  }

  Widget _buildTrackingView() {
    if (_isOrderInActiveDelivery()) {
      return _buildMapViewWidget(orderData!);
    } else {
      return _buildOrderStatusView();
    }
  }

  bool _isOrderInActiveDelivery() {
    final status = orderData!['status'];
    return status == 'in_delivery' || status == 'in_transit';
  }

  Widget _buildOrderStatusView() {
    final status = orderData!['status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildOrderStatusTimeline(),
          const SizedBox(height: 24),
          if (shopperSnapshot != null) ...[
            const Text(
              'Shopper Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      (shopperSnapshot!.data() as Map<String, dynamic>?)?['profileImage'] != null
                          ? NetworkImage(
                              (shopperSnapshot!.data()! as Map<String, dynamic>)['profileImage'])
                          : null,
                  child: (shopperSnapshot!.data() as Map<String, dynamic>?)?['profileImage'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getShopperName(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Contact shopper functionality
                    final phone = (shopperSnapshot?.data() as Map<String, dynamic>)['phone'];
                    if (phone != null) {
                      // Implement call functionality
                    }
                  },
                  icon: const Icon(
                    Icons.phone,
                    color: AppColors.whiteColor,
                  ),
                  label: const Text('Contact'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMaterialColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusTimeline() {
    final List<Map<String, dynamic>> statusSteps = [
      {
        'title': 'Order Placed',
        'icon': Icons.shopping_cart_checkout,
        'completed': _isStatusCompleted('pending'),
        'timestamp': orderData!['createdAt'],
      },
      {
        'title': 'Shopper Assigned',
        'icon': Icons.person,
        'completed': _isStatusCompleted('accepted'),
        'timestamp': orderData!['assignedAt'],
      },
      {
        'title': 'Out for Delivery',
        'icon': Icons.delivery_dining,
        'completed': _isStatusCompleted('in_transit'),
        'timestamp': orderData!['pickedUpAt'],
      },
      {
        'title': 'Delivered',
        'icon': Icons.home,
        'completed': _isStatusCompleted('delivered'),
        'timestamp': orderData!['deliveredAt'],
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statusSteps.length,
      itemBuilder: (context, index) {
        final step = statusSteps[index];
        return _buildTimelineStep(
          icon: step['icon'],
          title: step['title'],
          isCompleted: step['completed'],
          isFirst: index == 0,
          isLast: index == statusSteps.length - 1,
          timestamp: step['timestamp'],
        );
      },
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required bool isCompleted,
    required bool isFirst,
    required bool isLast,
    Timestamp? timestamp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primaryMaterialColor : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppColors.primaryMaterialColor : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? Colors.black : Colors.grey,
                ),
              ),
              if (timestamp != null && isCompleted)
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              SizedBox(height: isLast ? 0 : 24),
            ],
          ),
        ),
      ],
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
                    setState(() {}); // Refresh
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

  // This function now returns Future<Widget> instead of Widget
  Future<Widget> _buildMapView(Map<String, dynamic> activeOrder) async {
    LatLng storeLocation = const LatLng(0, 0); // Default value
    LatLng deliveryLocation = const LatLng(0, 0); // Default value
    LatLng shopperLocation = const LatLng(0, 0); // Default value

    try {
      // Get store location
      if (shopSnapshot != null &&
          (shopSnapshot!.data() as Map<String, dynamic>)['address'] != null &&
          (shopSnapshot!.data() as Map<String, dynamic>)['address']['location'] != null) {
        final GeoPoint geoPoint =
            (shopSnapshot!.data() as Map<String, dynamic>)['address']['location'];
        storeLocation = LatLng(
          geoPoint.latitude,
          geoPoint.longitude,
        );
      }

      // Get delivery location
      if (activeOrder['deliveryLocation'] != null) {
        final GeoPoint deliveryGeoPoint = activeOrder['deliveryLocation'];
        deliveryLocation = LatLng(
          deliveryGeoPoint.latitude,
          deliveryGeoPoint.longitude,
        );
      } else if (buyerSnapshot != null &&
          (buyerSnapshot!.data() as Map<String, dynamic>)['address'] != null &&
          (buyerSnapshot!.data() as Map<String, dynamic>)['address']['location'] != null) {
        // Fallback to buyer's address if delivery location is not specified
        final GeoPoint buyerGeoPoint =
            (buyerSnapshot!.data() as Map<String, dynamic>)['address']['location'];
        deliveryLocation = LatLng(
          buyerGeoPoint.latitude,
          buyerGeoPoint.longitude,
        );
      }

      // Get shopper's current location
      if (shopperSnapshot != null &&
          shopperSnapshot!.data() != null &&
          (shopperSnapshot!.data() as Map<String, dynamic>)['currentLocation'] != null) {
        final GeoPoint shopperGeoPoint =
            (shopperSnapshot!.data() as Map<String, dynamic>)['currentLocation'];
        shopperLocation = LatLng(
          shopperGeoPoint.latitude,
          shopperGeoPoint.longitude,
        );
      }

      // Fetch route points from an external API
      List<LatLng> routePoints =
          await _fetchRoutePoints(storeLocation, shopperLocation, deliveryLocation);

      // Calculate center point for map
      LatLng centerPoint;
      if (shopperLocation.latitude != 0 && shopperLocation.longitude != 0) {
        centerPoint = shopperLocation;
      } else if (storeLocation.latitude != 0 && storeLocation.longitude != 0) {
        centerPoint = storeLocation;
      } else {
        centerPoint = deliveryLocation;
      }

      // Calculate estimated time of arrival
      String eta = "Calculating...";
      if (activeOrder['estimatedDeliveryTime'] != null) {
        final estimatedTime = (activeOrder['estimatedDeliveryTime'] as Timestamp).toDate();
        final now = DateTime.now();
        final difference = estimatedTime.difference(now);

        if (difference.inMinutes > 0) {
          eta = "${difference.inMinutes} min";
        } else {
          eta = "Any moment now";
        }
      }

      // Now return the actual widget
      return Column(
        children: [
          // Map
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                // Route polylines
                PolylineLayer(
                  polylines: [
                    // First segment: Store to Shopper Location
                    if (shopperLocation.latitude != 0)
                      Polyline(
                        points: _getRouteSegment(routePoints, storeLocation, shopperLocation),
                        strokeWidth: 4.0,
                        color: AppColors.primaryMaterialColor.withOpacity(0.7),
                        borderColor: Colors.white,
                        borderStrokeWidth: 1.0,
                      ),
                    // Second segment: Shopper Location to Delivery Point
                    if (shopperLocation.latitude != 0)
                      Polyline(
                        points: _getRouteSegment(routePoints, shopperLocation, deliveryLocation),
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
                    if (storeLocation.latitude != 0)
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
                    if (deliveryLocation.latitude != 0)
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

                    // Shopper location marker
                    if (shopperLocation.latitude != 0)
                      Marker(
                        point: shopperLocation,
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

          // Bottom info panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                if (shopperSnapshot != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: (shopperSnapshot!.data() as Map?)?['profileImage'] != null
                            ? NetworkImage((shopperSnapshot!.data() as Map)['profileImage'])
                            : null,
                        child: (shopperSnapshot!.data() as Map?)?['profileImage'] == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getShopperName(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              activeOrder['orderStatus'] ?? 'On the way',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // Contact shopper functionality
                          final phone = (shopperSnapshot?.data() as Map?)?['phone'];
                          if (phone != null) {
                            // Implement call functionality
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('CALL'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryMaterialColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMaterialColor.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.primaryMaterialColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated arrival',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              eta,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _calculateDistanceText(shopperLocation, deliveryLocation),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryMaterialColor,
                        ),
                      ),
                    ],
                  ),
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

  String _getShopperName() {
    if (shopperSnapshot == null || shopperSnapshot!.data() == null) {
      return 'Unknown Shopper';
    }

    Map<String, dynamic> shopperData = shopperSnapshot!.data()! as Map<String, dynamic>;
    if (shopperData.containsKey('name')) {
      if (shopperData['name'] is Map) {
        final firstName = shopperData['name']['first'] ?? '';
        final lastName = shopperData['name']['last'] ?? '';
        return '$firstName $lastName';
      } else {
        return shopperData['name'] ?? 'Unknown Shopper';
      }
    } else if (shopperData.containsKey('firstName') && shopperData.containsKey('lastName')) {
      return '${shopperData['firstName']} ${shopperData['lastName']}';
    }

    return 'Unknown Shopper';
  }

  String _calculateDistanceText(LatLng point1, LatLng point2) {
    if (point1.latitude == 0 || point2.latitude == 0) {
      return "Calculating...";
    }

    // Calculate distance between points
    final distance = _calculateDistance(point1, point2);

    if (distance < 1) {
      return "${(distance * 1000).toStringAsFixed(0)} m";
    } else {
      return "${distance.toStringAsFixed(1)} km";
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // in kilometers

    double dLat = _degreesToRadians(point2.latitude - point1.latitude);
    double dLon = _degreesToRadians(point2.longitude - point1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(point1.latitude)) *
            cos(_degreesToRadians(point2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatEstimatedTime(dynamic time) {
    if (time is Timestamp) {
      final DateTime dateTime = time.toDate();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    return 'Soon';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_transit':
      case 'in_delivery':
        return AppColors.primaryMaterialColor;
      default:
        return Colors.orange;
    }
  }

  bool _isStatusCompleted(String checkStatus) {
    final status = orderData!['status']?.toLowerCase();

    // Status progression order
    const List<String> statusOrder = [
      'pending',
      'processing',
      'accepted',
      'in_transit',
      'delivered',
    ];

    // Find indices of the statuses in the progression
    final int currentStatusIndex = statusOrder.indexOf(status ?? '');
    final int checkStatusIndex = statusOrder.indexOf(checkStatus);

    // If either status is not found in the list, handle accordingly
    if (currentStatusIndex == -1 || checkStatusIndex == -1) {
      return false;
    }

    // The status is completed if its index is less than or equal to current status index
    return checkStatusIndex <= currentStatusIndex;
  }

  Future<List<LatLng>> _fetchRoutePoints(LatLng start, LatLng current, LatLng end) async {
    // If any point is invalid (0,0), return empty list
    if (start.latitude == 0 || current.latitude == 0 || end.latitude == 0) {
      return [];
    }

    try {
      // For demo purposes, we'll simulate a route with a simple implementation

      // First segment: from start to current
      List<LatLng> segment1 = await _simulateRoutePoints(start, current);

      // Second segment: from current to end
      List<LatLng> segment2 = await _simulateRoutePoints(current, end);

      // Combine both segments
      return [...segment1, ...segment2];
    } catch (e) {
      print('Error fetching route: $e');
      // Fallback to direct lines between points
      return [start, current, end];
    }
  }

  Future<List<LatLng>> _simulateRoutePoints(LatLng start, LatLng end) async {
    List<LatLng> points = [];

    // Add start point
    points.add(start);

    // Create a few intermediate waypoints
    final latDiff = end.latitude - start.latitude;
    final lngDiff = end.longitude - start.longitude;

    // Add some random waypoints to simulate real streets
    final random = Random();
    final numPoints = 3 + random.nextInt(3); // 3-5 points

    for (int i = 1; i <= numPoints; i++) {
      // Progress ratio along the route
      final ratio = i / (numPoints + 1);

      // Base intermediate point
      double lat = start.latitude + (latDiff * ratio);
      double lng = start.longitude + (lngDiff * ratio);

      // Add some randomness to simulate real streets
      // The closer to the endpoints, the less random variation
      final randomFactor = 0.0005 * sin(ratio * pi); // Max ~50m deviation
      lat += random.nextDouble() * randomFactor * (random.nextBool() ? 1 : -1);
      lng += random.nextDouble() * randomFactor * (random.nextBool() ? 1 : -1);

      points.add(LatLng(lat, lng));
    }

    // Add end point
    points.add(end);

    return points;
  }

  List<LatLng> _getRouteSegment(List<LatLng> routePoints, LatLng start, LatLng end) {
    // For simplicity, if we don't have route points, just return direct line
    if (routePoints.isEmpty) {
      return [start, end];
    }

    // Find the closest points in the route to our start and end
    int startIdx = 0;
    int endIdx = routePoints.length - 1;
    double minStartDist = double.infinity;
    double minEndDist = double.infinity;

    for (int i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];

      // Distance to start
      final startDist = _calculateDistance(point, start);
      if (startDist < minStartDist) {
        minStartDist = startDist;
        startIdx = i;
      }

      // Distance to end
      final endDist = _calculateDistance(point, end);
      if (endDist < minEndDist) {
        minEndDist = endDist;
        endIdx = i;
      }
    }

    // Make sure startIdx is before endIdx
    if (startIdx > endIdx) {
      final temp = startIdx;
      startIdx = endIdx;
      endIdx = temp;
    }

    // Get the segment
    List<LatLng> segment = [];
    segment.add(start); // Add actual start

    // Add points from route
    for (int i = startIdx; i <= endIdx; i++) {
      segment.add(routePoints[i]);
    }

    segment.add(end); // Add actual end
    return segment;
  }
}
