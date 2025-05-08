import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/screens/login_screen.dart';
import 'package:shop_now_mobile/screens/shopManagementScreen.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';
import 'package:shop_now_mobile/utils/helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  static const String routeName = '/adminDashboardScreen';
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;
  final _searchCtrl = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String _orderFilter = 'All';
  String _shopperFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Search...'),
                style: const TextStyle(color: Colors.white),
              )
            : Text('Admin Dashboard', style: Helper.getTheme(context).headlineLarge),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: AppColors.primaryMaterialColor),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchCtrl.clear();
              });
            },
          ),
          CircleAvatar(
              backgroundColor: Colors.white,
              child: Text('A', style: TextStyle(color: AppColors.primaryMaterialColor))),
          IconButton(
            icon: Icon(Icons.logout_outlined, color: AppColors.primaryMaterialColor),
            onPressed: () => AppDialogs.showConfirmDialog(
                messageText: 'Sign out?',
                onYesTap: () async {
                  await _auth.signOut();
                  await GetStorage().erase();
                  Get.offAllNamed(LoginScreen.routeName);
                },
                yesButtonText: 'Yes',
                noButtonText: 'No'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryMaterialColor,
          labelColor: AppColors.primaryMaterialColor,
          unselectedLabelColor: AppColors.bodyTextColor,
          tabs: const [Tab(text: 'DASHBOARD'), Tab(text: 'ORDERS'), Tab(text: 'SHOPPERS')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_dashboardTab(), _ordersTab(), _shoppersTab()],
      ),
    );
  }

  Widget _dashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Overview',
            style:
                TextStyle(color: AppColors.orangeColor, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').where('role', isEqualTo: 'buyer').snapshots(),
          builder: (_, snapB) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').where('role', isEqualTo: 'seller').snapshots(),
              builder: (_, snapS) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where('role', isEqualTo: 'shopper')
                      .snapshots(),
                  builder: (_, snapSh) {
                    final buyers = snapB.data?.docs.length ?? 0;
                    final sellers = snapS.data?.docs.length ?? 0;
                    final shoppers = snapSh.data?.docs.length ?? 0;
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 7,
                      childAspectRatio: 1.7,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ElegantStatCard(
                          label: "Buyers",
                          value: buyers,
                          icon: Icons.people,
                        ),
                        ElegantStatCard(
                          label: "Sellers",
                          value: sellers,
                          icon: Icons.store,
                        ),
                        ElegantStatCard(
                          label: "Shoppers",
                          value: shoppers,
                          icon: Icons.people,
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('orders')
                              .where('createdAt',
                                  isGreaterThan: DateTime.now().subtract(const Duration(days: 1)))
                              .snapshots(),
                          builder: (_, snapO) {
                            final today = snapO.data?.docs.length ?? 0;
                            return ElegantStatCard(
                              label: 'Orders Today',
                              value: today,
                              icon: Icons.shopping_cart,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
        const OrderStatisticsWidget(),
        const SizedBox(height: 24),
        const Text('Recent Orders',
            style: TextStyle(
              color: AppColors.orangeColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('orders')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (_, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text('No orders');
            return ElegantOrdersList(
              docs: docs,
              padding: const EdgeInsets.only(bottom: 24),
              showHeader: false,
            );
          },
        ),
      ]),
    );
  }

  Widget _ordersTab() {
    final filterOptions = ['All', 'Pending', 'Validated', 'In Transit', 'Delivered'];

    return Column(
      children: [
        // Search and filter header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field with rounded corners
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search orders...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Filter chips in scrollable row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterOptions
                      .map((option) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option),
                              selected: _orderFilter == option.toLowerCase(),
                              selectedColor: AppColors.orangeColor.withOpacity(0.15),
                              checkmarkColor: AppColors.orangeColor,
                              labelStyle: TextStyle(
                                color: _orderFilter == option
                                    ? AppColors.orangeColor
                                    : Colors.grey.shade800,
                                fontWeight:
                                    _orderFilter == option ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _orderFilter == option
                                      ? AppColors.orangeColor
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              onSelected: (selected) =>
                                  setState(() => _orderFilter = selected ? option : _orderFilter),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        // Orders list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore.collection('orders').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = _filterOrders(snapshot);

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final order = docs[index].data() as Map<String, dynamic>;
                    return OrderCard(
                        orderId: order['id'],
                        o: order,
                        status: order['status'],
                        date: (order['createdAt'] as Timestamp).toDate());
                  }
                  //   _buildOrderCard(docs[index]),
                  );
            },
          ),
        ),
      ],
    );
  }

// Extract filtering logic for better readability
  List<QueryDocumentSnapshot> _filterOrders(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data!.docs.where((doc) {
      final order = doc.data() as Map<String, dynamic>;
      final matchSearch =
          _searchCtrl.text.isEmpty || order['id'].toString().contains(_searchCtrl.text);
      final matchFilter = _orderFilter == 'All' || order['status'] == _orderFilter.toLowerCase();
      return matchSearch && matchFilter;
    }).toList();
  }

// Extracted empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isNotEmpty || _orderFilter != 'All'
                ? 'Try adjusting your filters'
                : 'Your orders will appear here',
            style: const TextStyle(color: AppColors.orangeColor),
          ),
        ],
      ),
    );
  }

// Extracted order card widget
  Widget _buildOrderCard(QueryDocumentSnapshot doc) {
    final order = doc.data() as Map<String, dynamic>;
    final statusColor = _getStatusColor(order['status']);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.to(() => OrderDetailScreen(orderId: order['id'])),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order ${order['id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('dd MMM').format(order['createdAt'].toDate()),
                    style: const TextStyle(color: AppColors.orangeColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '£${order['total']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orangeColor,
                    ),
                  ),
                  Chip(
                    label: Text(
                      order['status'],
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: statusColor.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Validated':
        return Colors.blue;
      case 'In Transit':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _shoppersTab() {
    final filterOptions = ['All', 'Approved', 'Pending'];

    return Column(
      children: [
        // Search and filter header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field with rounded corners
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search shoppers...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 16),

              // Filter chips in scrollable row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: filterOptions
                      .map((option) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option),
                              selected: _shopperFilter == option,
                              selectedColor: AppColors.orangeColor.withOpacity(0.15),
                              checkmarkColor: AppColors.orangeColor,
                              labelStyle: TextStyle(
                                color: _shopperFilter == option
                                    ? AppColors.orangeColor
                                    : Colors.grey.shade800,
                                fontWeight:
                                    _shopperFilter == option ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: _shopperFilter == option
                                      ? AppColors.orangeColor
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              onSelected: (selected) => setState(
                                  () => _shopperFilter = selected ? option : _shopperFilter),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),

        // Shoppers list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').where('role', isEqualTo: 'shopper').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final docs = _filterShoppers(snapshot);

              if (docs.isEmpty) {
                return _buildShopperEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) => _buildShopperCard(docs[index]),
              );
            },
          ),
        ),
      ],
    );
  }

// Extract filtering logic for better readability
  List<QueryDocumentSnapshot> _filterShoppers(AsyncSnapshot<QuerySnapshot> snapshot) {
    return snapshot.data!.docs.where((doc) {
      final shopper = doc.data() as Map<String, dynamic>;
      final matchSearch = _searchCtrl.text.isEmpty ||
          shopper['name']['first']
              .toString()
              .toLowerCase()
              .contains(_searchCtrl.text.toLowerCase()) ||
          shopper['name']['last'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase());
      return matchSearch;
    }).toList();
  }

// Extracted empty state widget
  Widget _buildShopperEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No shoppers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchCtrl.text.isNotEmpty || _shopperFilter != 'All'
                ? 'Try adjusting your filters'
                : 'Shoppers will appear here once registered',
            style: const TextStyle(color: AppColors.orangeColor),
          ),
        ],
      ),
    );
  }

// Extracted shopper card widget
  Widget _buildShopperCard(QueryDocumentSnapshot doc) {
    final shopper = doc.data() as Map<String, dynamic>;

    return FutureBuilder<QuerySnapshot>(
      future: doc.reference.collection('shopperProfile').get(),
      builder: (context, profileSnapshot) {
        if (!profileSnapshot.hasData) {
          return _buildShopperCardSkeleton();
        }

        // Check if there are any profile documents
        if (profileSnapshot.data!.docs.isEmpty) {
          return _buildIncompleteProfileCard(shopper);
        }

        final profile = profileSnapshot.data!.docs.first.data() as Map<String, dynamic>;
        final status = profile['verificationStatus'];

        // Handle filtering
        if (_shopperFilter != 'All' &&
            ((status == 'approved' ? 'Approved' : 'Pending') != _shopperFilter)) {
          return const SizedBox();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.orangeColor.withOpacity(0.1),
                      child: Text(
                        '${shopper['name']['first'][0]}${shopper['name']['last'][0]}',
                        style: const TextStyle(
                          color: AppColors.orangeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${shopper['name']['first']} ${shopper['name']['last']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                status == 'approved' ? Icons.done_all : Icons.pending_actions,
                                color: AppColors.orangeColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status == 'approved' ? 'Approved' : 'Pending Approval',
                                style: const TextStyle(
                                  color: AppColors.orangeColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Action button
                    (status == 'pending')
                        ? ElevatedButton(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(shopper['id'])
                                  .collection('shopperProfile')
                                  //  .where('verificationStatus', isEqualTo: 'approved')
                                  // .where('availability', isEqualTo: true)
                                  .get()
                                  .then((querySnapshot) {
                                for (var doc in querySnapshot.docs) {
                                  doc.reference.update({'verificationStatus': 'approved'});
                                }
                              }).catchError((error) {
                                log(" ========> Error updating documents: $error");
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Approve',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.delivery_dining,
                            color: AppColors.primaryMaterialColor,
                            size: 30,
                          ),
                  ],
                ),

                // Additional details (can be expanded)
                if (shopper.containsKey('email') || profile.containsKey('phone'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        if (shopper.containsKey('email'))
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    size: 16, color: AppColors.orangeColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    shopper['email'] ?? 'No email',
                                    style: TextStyle(color: Colors.grey.shade700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (shopper.containsKey('phone'))
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    size: 16, color: AppColors.orangeColor),
                                const SizedBox(width: 8),
                                Text(
                                  shopper['phone'] ?? 'No phone',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

// Loading skeleton for shopper card
  Widget _buildShopperCardSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Skeleton avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),

            // Skeleton text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 120,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Card for shoppers with incomplete profiles
  Widget _buildIncompleteProfileCard(Map<String, dynamic> shopper) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                '${shopper['firstName'][0]}${shopper['lastName'][0]}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${shopper['firstName']} ${shopper['lastName']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Profile incomplete',
                    style: TextStyle(color: AppColors.orangeColor),
                  ),
                ],
              ),
            ),

            // Info icon
            Icon(
              Icons.info_outline,
              color: Colors.amber.shade800,
            ),
          ],
        ),
      ),
    );
  }
}

class ElegantStatCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool animate;
  final Duration animationDuration;

  const ElegantStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.orangeColor,
    this.backgroundColor,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<ElegantStatCard> createState() => _ElegantStatCardState();
}

class _ElegantStatCardState extends State<ElegantStatCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<int> _countAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _countAnimation = IntTween(begin: 0, end: widget.value).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.animate) {
      // Add a tiny delay to make the animation feel more natural when multiple cards are displayed
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ElegantStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _countAnimation = IntTween(begin: oldWidget.value, end: widget.value).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
        ),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = widget.iconColor ?? AppColors.orangeColor;
    final backgroundColor = widget.backgroundColor ?? theme.cardColor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Card(
              elevation: 4,
              shadowColor: iconColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: iconColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor,
                      backgroundColor.withOpacity(0.9),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.icon,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_countAnimation.value}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.headlineMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ElegantOrdersList extends StatelessWidget {
  final List<DocumentSnapshot> docs;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;
  final bool showHeader;
  final Function(String orderId)? onOrderTap;

  const ElegantOrdersList({
    super.key,
    required this.docs,
    this.physics = const NeverScrollableScrollPhysics(),
    this.padding,
    this.showHeader = true,
    this.onOrderTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat.currency(symbol: '£', decimalDigits: 2);

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 64,
              color: AppColors.orangeColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No orders yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orders',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${docs.length} ${docs.length == 1 ? 'order' : 'orders'}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
        ListView.builder(
          shrinkWrap: true,
          physics: physics,
          padding: padding,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final orderData = docs[index].data() as Map<String, dynamic>;
            final orderId = orderData['id'] as String;
            final orderTotal = orderData['total'] as num;
            final orderStatus = orderData['status'] as String;
            final createdAt = (orderData['createdAt'] as Timestamp).toDate();

            // Determine status color
            Color statusColor;
            IconData statusIcon;

            switch (orderStatus.toLowerCase()) {
              case 'completed':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle;
                break;
              case 'processing':
                statusColor = Colors.orange;
                statusIcon = Icons.sync;
                break;
              case 'shipped':
                statusColor = Colors.blue;
                statusIcon = Icons.local_shipping;
                break;
              case 'cancelled':
                statusColor = Colors.red;
                statusIcon = Icons.cancel;
                break;
              default:
                statusColor = Colors.grey;
                statusIcon = Icons.hourglass_empty;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Card(
                elevation: .5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.dividerColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => onOrderTap != null
                      ? onOrderTap!(orderId)
                      : Get.to(() => OrderDetailScreen(orderId: orderId)),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.orangeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: AppColors.orangeColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Order ${orderId.substring(0, 5)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Chip(
                              elevation: 1.0,
                              backgroundColor: statusColor.withOpacity(0.1),
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              avatar: Icon(
                                statusIcon,
                                color: AppColors.orangeColor,
                                size: 16,
                              ),
                              label: Text(
                                orderStatus.capitalize ?? "",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.orangeColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(orderTotal),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.orangeColor,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Order Date',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(createdAt),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Optional: Add more order details here
                        // You could add items count, shipping address, etc.
/*
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.orangeColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: Icon(Icons.visibility,
                                color: AppColors.primaryMaterialColor, size: 16),
                            label: const Text('View Details'),
                            onPressed: () => onOrderTap != null
                                ? onOrderTap!(orderId)
                                : Get.to(
                                    () => OrderDetailScreen(
                                      orderId: orderId,
                                    ),
                                  ),
                          ),
                        ),
                    */
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class OrderStatisticsWidget extends StatefulWidget {
  const OrderStatisticsWidget({super.key});

  @override
  State<OrderStatisticsWidget> createState() => _OrderStatisticsWidgetState();
}

class _OrderStatisticsWidgetState extends State<OrderStatisticsWidget> {
  // Default to weekly view
  String _selectedTimeFrame = 'Weekly';

  // To store the fetched orders
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  // Statistics calculated from orders
  int _totalOrders = 0;
  double _totalRevenue = 0;
  int _pendingOrders = 0;
  int _deliveredOrders = 0;

  // Data for charts
  List<FlSpot> _revenueData = [];
  List<Map<String, dynamic>> _statusData = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Define the date range based on selected timeframe
      DateTime endDate = DateTime.now();
      DateTime startDate;

      switch (_selectedTimeFrame) {
        case 'Daily':
          startDate = DateTime.now().subtract(const Duration(days: 1));
          break;
        case 'Weekly':
          startDate = DateTime.now().subtract(const Duration(days: 7));
          break;
        case 'Monthly':
          startDate = DateTime.now().subtract(const Duration(days: 30));
          break;
        case 'Yearly':
          startDate = DateTime.now().subtract(const Duration(days: 365));
          break;
        default:
          startDate = DateTime.now().subtract(const Duration(days: 7));
      }

      // Fetch orders from Firestore
      final ordersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .orderBy('createdAt', descending: false)
          .get();

      // Convert to list of maps
      final orders = ordersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return data;
      }).toList();

      // Calculate statistics
      _calculateStatistics(orders);

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching orders: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> orders) {
    _totalOrders = orders.length;
    _totalRevenue = 0;
    _pendingOrders = 0;
    _deliveredOrders = 0;

    // Maps to store daily/weekly/monthly data
    Map<String, double> revenueByPeriod = {};
    Map<String, int> countByStatus = {};

    // Format pattern based on selected time frame
    String dateFormat;
    switch (_selectedTimeFrame) {
      case 'Daily':
        dateFormat = 'HH:00'; // Hourly
        break;
      case 'Weekly':
        dateFormat = 'E'; // Day of week
        break;
      case 'Monthly':
        dateFormat = 'dd/MM'; // Day of month
        break;
      case 'Yearly':
        dateFormat = 'MMM'; // Month
        break;
      default:
        dateFormat = 'E'; // Default to day of week
    }

    // Process each order
    for (var order in orders) {
      // Add to total revenue
      _totalRevenue += (order['total'] ?? 0).toDouble();

      // Count by status
      final status = order['status'] ?? 'unknown';
      countByStatus[status] = (countByStatus[status] ?? 0) + 1;

      if (status == 'pending') {
        _pendingOrders++;
      } else if (status == 'delivered') {
        _deliveredOrders++;
      }

      // Group by period for charts
      Timestamp createdTimestamp = order['createdAt'];
      DateTime createdDate = createdTimestamp.toDate();
      String periodKey = DateFormat(dateFormat).format(createdDate);

      // Add to revenue by period
      revenueByPeriod[periodKey] =
          (revenueByPeriod[periodKey] ?? 0) + (order['total'] ?? 0).toDouble();
    }

    // Convert revenue data to spots for line chart
    _revenueData = [];
    List<String> sortedKeys = revenueByPeriod.keys.toList()..sort();
    for (int i = 0; i < sortedKeys.length; i++) {
      String key = sortedKeys[i];
      _revenueData.add(FlSpot(i.toDouble(), revenueByPeriod[key] ?? 0));
    }

    // Convert status data for pie chart
    _statusData = countByStatus.entries.map((entry) {
      return {
        'status': entry.key,
        'count': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      //  padding: const EdgeInsets.all(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildTimeFrameSelector(),
          const SizedBox(height: 20),
          _isLoading ? const Center(child: CircularProgressIndicator()) : _buildStatisticCards(),
          const SizedBox(height: 20),
          _isLoading ? const SizedBox.shrink() : _buildCharts(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Order Statistics',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _fetchOrders,
        ),
      ],
    );
  }

  Widget _buildTimeFrameSelector() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((timeFrame) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(timeFrame),
              selected: _selectedTimeFrame == timeFrame,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedTimeFrame = timeFrame;
                  });
                  _fetchOrders();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatisticCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Total Orders',
          value: '$_totalOrders',
          icon: Icons.shopping_bag,
        ),
        _buildStatCard(
          title: 'Total Revenue',
          value: '\$${_totalRevenue.toStringAsFixed(2)}',
          icon: Icons.attach_money,
        ),
        _buildStatCard(
          title: 'Pending Orders',
          value: '$_pendingOrders',
          icon: Icons.pending_actions,
        ),
        _buildStatCard(
          title: 'Delivered Orders',
          value: '$_deliveredOrders',
          icon: Icons.done_all,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primaryMaterialColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppColors.primaryMaterialColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Column(
      children: [
        _buildRevenueChart(),
        const SizedBox(height: 20),
        _buildOrderStatusChart(),
      ],
    );
  }

  Widget _buildRevenueChart() {
    // Get labels for x-axis based on timeframe
    List<String> xLabels = [];
    switch (_selectedTimeFrame) {
      case 'Daily':
        xLabels = List.generate(24, (index) => '$index:00');
        break;
      case 'Weekly':
        xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        break;
      case 'Monthly':
        xLabels = List.generate(30, (index) => '${index + 1}');
        break;
      case 'Yearly':
        xLabels = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        break;
      default:
        xLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _revenueData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final index = value.toInt();
                              if (index >= 0 && index < xLabels.length) {
                                return Text(xLabels[index]);
                              }
                              return const Text('');
                            },
                            reservedSize: 22,
                          )),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              return Text('\$${value.toInt()}');
                            },
                            reservedSize: 40,
                          )),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _revenueData,
                            isCurved: true,
                            color: AppColors.orangeColor,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.orangeColor.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusChart() {
    // Define colors for each status directly within the function
    final Map<String, Color> statusColors = {
      'pending': AppColors.yellowColor,
      'processing': AppColors.blueSkyColor,
      'shipped': Colors.green.shade700,
      'delivered': AppColors.primaryMaterialColor,
      'cancelled': AppColors.alertColor,
      // Add more status-color mappings as needed
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status Distribution',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: _statusData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sections: _statusData.map((data) {
                                final status = data['status'] as String;
                                final count = data['count'] as int;
                                final color = statusColors[status] ??
                                    Colors.blue; // Default color if status is not found
                                return PieChartSectionData(
                                  color: color,
                                  value: count.toDouble(),
                                  title: '$count',
                                  radius: 80,
                                  titleStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 20.0,
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _statusData.map((data) {
                              final status = data['status'] as String;
                              final color = statusColors[status] ?? Colors.blue; // Default color
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status.capitalize ?? "",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
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


// Usage example:
// 
// class OrdersScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Orders')),
//       body: SingleChildScrollView(
//         child: OrderStatisticsWidget(),
//       ),
//     );
//   }
// }

/*
class OrderCard extends StatelessWidget {
  final String orderId;
  final String orderStatus;
  final double orderTotal;
  final DateTime createdAt;
  final Function(String)? onOrderTap;
  final IconData statusIcon;
  final Color statusColor;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.orderStatus,
    required this.orderTotal,
    required this.createdAt,
    required this.statusIcon,
    required this.statusColor,
    this.onOrderTap,
   
  });

  String get _capitalizeStatus {
    if (orderStatus.isEmpty) return "";
    return orderStatus[0].toUpperCase() + orderStatus.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: .5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => onOrderTap != null
              ? onOrderTap!(orderId)
              : _navigateToOrderDetails(),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(theme),
                const SizedBox(height: 16),
                _buildOrderInfo(theme),
                const SizedBox(height: 12),
                _buildViewDetailsButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.orangeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: AppColors.orangeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Order ${orderId.substring(0, 5)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Chip(
          elevation: 1.0,
          backgroundColor: statusColor.withOpacity(0.1),
          side: BorderSide.none,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          avatar: Icon(
            statusIcon,
            color: AppColors.orangeColor,
            size: 16,
          ),
          label: Text(
            _capitalizeStatus,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.orangeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currencyFormat.format(orderTotal),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.orangeColor,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Order Date',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(createdAt),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewDetailsButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.orangeColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(Icons.visibility,
            color: AppColors.primaryMaterialColor, size: 16),
        label: const Text('View Details'),
        onPressed: () => onOrderTap != null
            ? onOrderTap!(orderId)
            : _navigateToOrderDetails(),
      ),
    );
  }

  void _navigateToOrderDetails() {
    // Import your navigation library at the top of the file
    // This example assumes you're using Get for navigation
    // Get.to(() => OrderDetailScreen(orderId: orderId));
    
    // If you're using Navigator:
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => OrderDetailScreen(orderId: orderId)),
    // );
  }
}
*/