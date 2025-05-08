import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_page_names.dart';

class MyOrdersScreen extends StatefulWidget {
  static const routeName = "/myOrdersScren";

  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _getBuyerOrdersStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios,
            )),
        title: const Text('My Orders'),
        //  backgroundColor: AppColors.primaryMaterialColor,
        //  foregroundColor: Colors.white,
      ),
      body: _buildOrdersStreamList(_ordersStream),
    );
  }

  _getBuyerOrdersStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // For buyer, we query where buyerRef matches the current user
    _ordersStream = _firestore
        .collection('orders')
        .where('buyerRef', isEqualTo: _firestore.collection('users').doc(currentUser.uid))
        //.orderBy('createdAt', descending: true)
        .snapshots();

    // setState(() {});
  }

  Widget _buildOrdersStreamList(Stream<QuerySnapshot>? ordersStream) {
    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: AppColors.primaryMaterialColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You haven\'t placed any orders yet',
                  style: TextStyle(
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
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Get.toNamed(
            AppPageNames.orderTrackingScreen,
            arguments: {
              'orderId': order['id'],
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
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
                              ? "On the way"
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
              if (order['deliveryPersonRef'] != null)
                FutureBuilder<DocumentSnapshot>(
                  future: _firestore.doc(order['deliveryPersonRef'].path).get(),
                  builder: (context, driverSnapshot) {
                    String driverName = 'Awaiting driver...';

                    if (driverSnapshot.hasData && driverSnapshot.data!.exists) {
                      final driverData = driverSnapshot.data!.data() as Map<String, dynamic>;
                      driverName = driverData['name']['first'] != null
                          ? "${driverData['name']['first']} ${driverData['name']['last']}"
                          : 'Unknown Driver';
                    }

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryMaterialColor.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.delivery_dining, color: AppColors.primaryMaterialColor),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Driver: $driverName',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (order['status'] == 'active' && order['estimatedTime'] != null)
                              Text(
                                'ETA: ${order['estimatedTime']}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
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
                    child: Icon(Icons.schedule, color: AppColors.primaryMaterialColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order placed: ${_formatTimestamp(order['createdAt'])}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (order['status'] == 'completed')
                        Text(
                          'Delivered: ${_formatTimestamp(order['completedAt'])}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Track order button for active orders
              if (order['status'] == 'active')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton.icon(
                    onPressed: () => _trackOrder(order),
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('TRACK ORDER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaterialColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ),

              // Reorder button for completed orders
              if (order['status'] == 'completed')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: OutlinedButton.icon(
                    onPressed: () => _reorder(order),
                    icon: Icon(Icons.replay, color: AppColors.primaryMaterialColor),
                    label: const Text('ORDER AGAIN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryMaterialColor,
                      side: BorderSide(color: AppColors.primaryMaterialColor),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _convertDocToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else {
        return 'Invalid timestamp';
      }

      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Error formatting date';
    }
  }

  void _trackOrder(Map<String, dynamic> order) {
    // Navigate to order tracking screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Track Order'),
            backgroundColor: AppColors.primaryMaterialColor,
            foregroundColor: Colors.white,
          ),
          body: const Center(
            child: Text('Order tracking map would be shown here'),
          ),
        ),
      ),
    );
  }

  void _reorder(Map<String, dynamic> order) {
    // Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Creating a new order with the same items...')),
    );

  }
}
