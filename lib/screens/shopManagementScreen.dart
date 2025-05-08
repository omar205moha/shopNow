import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/screens/login_screen.dart';
import 'package:shop_now_mobile/utils/dialogs.dart';
import 'package:shop_now_mobile/widgets/location_picker_form_field.dart';

class ShopManagementScreen extends StatefulWidget {
  static const String routeName = '/shopManagementScreen';
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = false;
  bool isInitialized = false; // Add this flag to track initialization
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _formKey = GlobalKey<FormState>();

  late String shopId;
  DocumentReference? shopRef; // Make this nullable instead of late
  QuerySnapshot? productsRef; // Make this nullable instead of late

  // Controllers for shop profile
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddrController = TextEditingController();
  final TextEditingController _shopDescController = TextEditingController();
  LocationResult? _storelocation;
  final ImagePicker _picker = ImagePicker();
  File? _coverImageFile;
  File? _logoFile;
  String? _coverImage;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initShopData();
  }

  Future<void> _initShopData() async {
    setState(() => isLoading = true);
    try {
      final uid = _auth.currentUser!.uid;

      // First find the shop document for this user
      final shopsQuery = await _firestore
          .collection('shops')
          .where("userRef", isEqualTo: _firestore.doc("/users/$uid"))
          .limit(1)
          .get();

      if (shopsQuery.docs.isNotEmpty) {
        log(" ============> Shop exist ");
        shopId = shopsQuery.docs.first.id;
        shopRef = _firestore.collection('shops').doc(shopId);
        productsRef =
            await _firestore.collection('products').where("shopRef", isEqualTo: shopRef).get();
        await _loadShopInfo();
      } else {
        // Create a new shop if none exists
        shopRef = await _firestore.collection('shops').add({
          'name': 'My Shop',
          'userRef': _firestore.doc("/users/$uid"),
          'address': {'line1': ''},
          'createdAt': FieldValue.serverTimestamp(),
        });
        shopId = shopRef!.id;
        productsRef =
            await _firestore.collection('products').where("shopRef", isEqualTo: shopRef).get();
        _shopNameController.text = 'My Shop';
      }

      setState(() {
        isInitialized = true; // Set initialization flag
        isLoading = false;
      });
    } catch (e) {
      log('Error initializing shop: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to load shop data');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadShopInfo() async {
    final doc = await shopRef!.get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        _shopNameController.text = data['name'] ?? '';
        _storelocation = LocationResult(data['address']?['location']?.latitude ?? 5.0,
            data['address']?['location']?.longitude ?? -2.5, data['address']?['line1'] ?? '');
        _shopAddrController.text = data['address']?['line1'];
        _shopDescController.text = data['description'] ?? '';
        _coverImage = data['coverImage'];
        _logoUrl = data['logoUrl'];
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _shopNameController.dispose();
    _shopAddrController.dispose();
    _shopDescController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isCover) async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile != null) {
      setState(() {
        if (isCover) {
          _coverImageFile = File(xfile.path);
        } else {
          _logoFile = File(xfile.path);
        }
      });
    }
  }

  Future<String?> _uploadImage(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateShopProfile() async {
    if (shopRef == null) return; // Safety check

    if (!_formKey.currentState!.validate()) {
      // Show snackbar with error message
      Get.snackbar(
        "Error",
        "Please fill all required fields",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_storelocation == null) {
      Get.snackbar(
        "Error",
        "Select a location",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    setState(() => isLoading = true);
    try {
      final updates = {
        'name': _shopNameController.text.trim(),
        'address': {
          'line1': _shopAddrController.text.trim(),
          'location': GeoPoint(_storelocation!.lat, _storelocation!.lng),
        },
        'description': _shopDescController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Upload new cover image if selected
      if (_coverImageFile != null) {
        final url = await _uploadImage(
            _coverImageFile!, 'shops/$shopId/cover_${DateTime.now().millisecondsSinceEpoch}');
        if (url != null) {
          updates['coverImage'] = url;
          _coverImage = url;
        }
      }
/*
      // Upload new logo if selected
      if (_logoFile != null) {
        final url = await _uploadImage(
            _logoFile!, 'shops/$shopId/logo_${DateTime.now().millisecondsSinceEpoch}');
        if (url != null) {
          updates['logoUrl'] = url;
          _logoUrl = url;
        }
      }
      */

      await shopRef!.update(updates);
      AppDialogs.showSuccessDialog(messageText: 'Shop profile updated successfully');
    } catch (e) {
      log('Error updating shop: $e');
      AppDialogs.showErrorDialog(messageText: 'Failed to update shop profile');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || !isInitialized) {
      // Changed this condition
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shop Management',
          style: TextStyle(color: Colors.black),
        ),
        bottom: TabBar(
          controller: _tabController,
          //  indicatorColor: Colors.white,
          indicatorWeight: 3,
          //  labelColor: Colors.white,
          unselectedLabelColor: Colors.black45,
          dividerHeight: .1,
          tabs: const [
            Tab(
              text: 'PRODUCTS',
              icon: Icon(Icons.inventory),
            ),
            Tab(
              text: 'ORDERS',
              icon: Icon(Icons.shopping_bag),
            ),
            Tab(
              text: 'PROFILE',
              icon: Icon(Icons.store),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
            ),
            onPressed: () => AppDialogs.showConfirmDialog(
              messageText: 'Sign out?',
              onYesTap: () async {
                await _auth.signOut();
                await GetStorage().erase();
                Get.offAllNamed(LoginScreen.routeName);
              },
              yesButtonText: 'Yes',
              noButtonText: 'No',
            ),
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(),
          _buildOrdersTab(),
          _buildProfileTab(),
        ],
      ),
      floatingActionButton: /*_tabController.index == 0
          ?*/
          FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        backgroundColor: AppColors.primaryMaterialColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Product', style: TextStyle(color: Colors.white)),
      )

      // : null
      ,
    );
  }

  Widget _buildProductsTab() {
    if (productsRef == null) return _emptyState('Shop not properly initialized');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("products")
          .where("shopRef", isEqualTo: shopRef)
          // .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _emptyState('Error loading products');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('No products found. Add your first product!');
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;

            return _productCard(docs[i].id, data);
          },
        );
      },
    );
  }

  Widget _productCard(String id, Map<String, dynamic> p) {
    final hasDiscount = (p['price'] ?? 0) < (p['originalPrice'] ?? 0);
    final inStock = (p['stock'] ?? 0) > 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () => _showProductForm(id: id, data: p),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with badges
              Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.4,
                      child: p['imageUrl'] != null && p['imageUrl'].toString().isNotEmpty
                          ? Image.network(
                              p['imageUrl'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              (loadingProgress.expectedTotalBytes ?? 1)
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.error_outline, size: 40),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.image, size: 50, color: Colors.grey),
                              ),
                            ),
                    ),
                  ),

                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          '${(((p['originalPrice'] - p['price']) / p['originalPrice']) * 100).round()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),

                  // Stock label
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock ? Colors.green : Colors.red,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        inStock ? 'In Stock' : 'Out of Stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  // Action buttons
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => _showProductForm(id: id, data: p),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: AppColors.primaryMaterialColor,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          InkWell(
                            onTap: () => _confirmDeleteProduct(id, p['name'] ?? 'this product'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      p['name'] ?? 'Unnamed Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stock: ${p['stock'] ?? 0}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "£${p['price']?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primaryMaterialColor,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 4),
                          Text(
                            "£${p['originalPrice']?.toStringAsFixed(2) ?? '0.00'}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteProduct(String id, String name) {
    if (productsRef == null) return;

    AppDialogs.showConfirmDialog(
      titleText: 'Delete Product',
      messageText: 'Are you sure you want to delete "$name"?',
      onYesTap: () async {
        try {
          await _firestore.collection("products").doc(id).delete();

          Navigator.of(context).pop();

          Get.snackbar(
            'Succes',
            'Product deleted successfully',
            snackPosition: SnackPosition.TOP,
          );
        } catch (e) {
          AppDialogs.showErrorDialog(messageText: 'Failed to delete product');
        }
      },
      yesButtonText: 'Delete',
      noButtonText: 'Cancel',
    );
  }

  void _showProductForm({String? id, Map<String, dynamic>? data}) {
    if (productsRef == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductForm(
        productsRef: _firestore.collection("products"),
        storageRef: _storage.ref().child('products'),
        categoriesRef: FirebaseFirestore.instance.collection('categories'),
        brandsRef: FirebaseFirestore.instance.collection('brands'),
        productId: id,
        shopId: shopId,
        initialData: data,
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (shopRef == null) return _emptyState('Shop not properly initialized');

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('shopRefs', arrayContains: "/${shopRef?.path}")
          //  .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _emptyState('Error loading orders');
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('No orders yet');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final o = docs[i].data() as Map<String, dynamic>;
            final orderId = docs[i].id;
            final status = o['status'] ?? 'Pending';
            final timestamp = o['createdAt'] as Timestamp?;
            final date = timestamp?.toDate() ?? DateTime.now();

            return OrderCard(
              orderId: orderId,
              o: o,
              status: status,
              date: date,
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            GestureDetector(
              onTap: () => _pickImage(true),
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  image: _coverImageFile != null
                      ? DecorationImage(
                          image: FileImage(_coverImageFile!),
                          fit: BoxFit.cover,
                        )
                      : _coverImage != null
                          ? DecorationImage(
                              image: NetworkImage(_coverImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _coverImageFile == null && _coverImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Cover Image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white54,
                            child: IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primaryMaterialColor),
                              onPressed: () => _pickImage(true),
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Logo
            Center(
              child: GestureDetector(
                onTap: () => _pickImage(false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _logoFile != null
                            ? FileImage(_logoFile!)
                            : _logoUrl != null
                                ? NetworkImage(_logoUrl!)
                                : null,
                        child: _logoFile == null && _logoUrl == null
                            ? Icon(Icons.store, size: 60, color: Colors.grey[600])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          backgroundColor: AppColors.primaryMaterialColor,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.white),
                            onPressed: () => _pickImage(false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Form
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Shop Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                        labelText: 'Shop Name',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LocationPickerInput(
                      controller: _shopAddrController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Pick a correct location";
                        }
                        return null;
                      },
                      onLocationSelected: (location) {
                        setState(() {
                          _storelocation = location;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _shopDescController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateShopProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaterialColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _tabController.index == 0 ? Icons.inventory : Icons.shopping_bag,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProductForm extends StatefulWidget {
  final CollectionReference productsRef;
  final Reference storageRef;
  final String? productId;
  final String shopId;
  final Map<String, dynamic>? initialData;
  final CollectionReference categoriesRef;
  final CollectionReference brandsRef;

  const ProductForm({
    required this.productsRef,
    required this.storageRef,
    required this.categoriesRef,
    required this.brandsRef,
    required this.shopId,
    this.productId,
    this.initialData,
    super.key,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  final TextEditingController _newBrandController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;
  bool _hasDiscount = false;
  bool _isLoadingCategories = true;
  bool _isLoadingBrands = true;

  // Store both ID and name for categories and brands
  String? _selectedCategoryId;
  String? _selectedBrandId;
  String? _selectedCategoryName;
  String? _selectedBrandName;

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadBrands();

    if (widget.initialData != null) {
      _nameController.text = widget.initialData!['name'] ?? '';
      _descController.text = widget.initialData!['description'] ?? '';
      _priceController.text = (widget.initialData!['price'] ?? 0).toString();
      _originalPriceController.text = (widget.initialData!['originalPrice'] ?? 0).toString();
      _stockController.text = (widget.initialData!['stock'] ?? 0).toString();

      // Store references to category and brand
      _selectedCategoryId = widget.initialData!['categoryRef']?.path.split('/').last;
      _selectedBrandId = widget.initialData!['brandRef']?.path.split('/').last;
      _selectedCategoryName = widget.initialData!['categoryName'];
      _selectedBrandName = widget.initialData!['brandName'];

      _imageUrl = widget.initialData!['imageUrl'];
      _hasDiscount =
          (widget.initialData!['price'] ?? 0) < (widget.initialData!['originalPrice'] ?? 0);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final snapshot = await widget.categoriesRef.get();
      final categories = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] as String,
        };
      }).toList();

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      log('Error loading categories: $e');
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final snapshot = await widget.brandsRef.get();
      final brands = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] as String,
        };
      }).toList();

      setState(() {
        _brands = brands;
        _isLoadingBrands = false;
      });
    } catch (e) {
      log('Error loading brands: $e');
      setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _addNewCategory() async {
    if (_newCategoryController.text.trim().isEmpty) return;

    setState(() => _isLoadingCategories = true);
    try {
      final newCategory = _newCategoryController.text.trim();
      final docRef = widget.categoriesRef.doc();

      docRef.set({
        'id': docRef.id,
        'name': newCategory,
        'imageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _categories.add({
          'id': docRef.id,
          'name': newCategory,
        } as Map<String, dynamic>);
        _selectedCategoryId = docRef.id;
        _selectedCategoryName = newCategory;
        _newCategoryController.clear();
      });
      Navigator.pop(context);

      Get.snackbar(
        'Succes',
        'Category "$newCategory" added successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      log(' ======> Error adding category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add category')),
      );
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _addNewBrand() async {
    if (_newBrandController.text.trim().isEmpty) return;

    setState(() => _isLoadingBrands = true);
    try {
      final newBrand = _newBrandController.text.trim();
      final docRef = widget.brandsRef.doc();
      docRef.set({
        'id': docRef.id,
        'name': newBrand,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'logoUrl': '',
      });

      setState(() {
        _brands.add({
          'id': docRef.id,
          'name': newBrand,
        });
        _selectedBrandId = docRef.id;
        _selectedBrandName = newBrand;
        _newBrandController.clear();
      });
      Navigator.pop(context);

      Get.snackbar(
        'Succes',
        'Brand "$newBrand" added successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      log('Error adding brand: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add brand')),
      );
    } finally {
      setState(() => _isLoadingBrands = false);
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addNewCategory,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showAddBrandDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Brand'),
          content: TextField(
            controller: _newBrandController,
            decoration: const InputDecoration(
              labelText: 'Brand Name',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _addNewBrand,
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _stockController.dispose();
    _newCategoryController.dispose();
    _newBrandController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (xfile != null) {
      setState(() {
        _imageFile = File(xfile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _imageUrl;

    try {
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = widget.storageRef.child(fileName);
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      log('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      Get.snackbar(
        'Error',
        'Please select a category',
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
      );

      return;
    }

    if (_selectedBrandId == null) {
      Get.snackbar(
        'Error',
        'Please select a brand',
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = await _uploadImage();

      final price = double.tryParse(_priceController.text) ?? 0.0;
      final originalPrice =
          _hasDiscount ? (double.tryParse(_originalPriceController.text) ?? price) : price;
      final stock = int.tryParse(_stockController.text) ?? 0;

      // Create references to the selected category and brand
      final categoryRef = FirebaseFirestore.instance.doc('categories/$_selectedCategoryId');
      final brandRef = FirebaseFirestore.instance.doc('brands/$_selectedBrandId');

      final productData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': price,
        'originalPrice': originalPrice,
        'stock': stock,
        'categoryRef': categoryRef,
        'brandRef': brandRef,
        'categoryName': _selectedCategoryName,
        'brandName': _selectedBrandName,
        'updatedAt': DateTime.now(),
        'unit': 'each',
        'shopRef': FirebaseFirestore.instance.doc('shops/${widget.shopId}'),
      };

      if (imageUrl != null) {
        productData['imageUrl'] = imageUrl;
      }

      if (widget.productId != null) {
        // Update existing product
        await widget.productsRef.doc(widget.productId).update(productData);
      } else {
        // Add new product
        productData['createdAt'] = DateTime.now();
        productData['featured'] = false;
        final productId = widget.productsRef.doc().id;
        productData['id'] = productId;
        await widget.productsRef.doc(productId).set(productData);
      }

      Get.snackbar(
        'Succes',
        'Product ${widget.productId != null ? "updated" : "added"} successfully',
        colorText: Colors.white,
        backgroundColor: AppColors.primaryMaterialColor,
        snackPosition: SnackPosition.TOP,
      );

      Navigator.pop(context);
    } catch (e) {
      log(' =========> Error saving product: $e');
      Get.snackbar(
        'Error',
        'Failed to save product',
        colorText: Colors.white,
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productId != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryMaterialColor, // Using theme color instead of hardcoded
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Product' : 'Add New Product',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _isLoading
                    ? const CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 7,
                      )
                    : TextButton.icon(
                        onPressed: _saveProduct,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Center(
                      child: GestureDetector(
                        //  onTap: _pickImage,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _imageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child: _imageFile == null && _imageUrl == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate,
                                          size: 50, color: Colors.grey[600]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add Product Image',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.bottomRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white),
                                        onPressed: _pickImage,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product Details
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name*',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Category dropdown with add option
                    _isLoadingCategories
                        ? const Center(child: CircularProgressIndicator())
                        : InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Category*',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategoryId,
                                      hint: const Text('Select Category'),
                                      isExpanded: true,
                                      items: _categories.map((category) {
                                        return DropdownMenuItem<String>(
                                          value: category['id'],
                                          child: Text(category['name']),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          final selectedCategory = _categories.firstWhere(
                                            (category) => category['id'] == newValue,
                                          );
                                          setState(() {
                                            _selectedCategoryId = newValue;
                                            _selectedCategoryName = selectedCategory['name'];
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.add_circle, color: AppColors.primaryMaterialColor),
                                  onPressed: _showAddCategoryDialog,
                                  tooltip: 'Add New Category',
                                ),
                              ],
                            ),
                          ),

                    const SizedBox(height: 16),

                    // Brand dropdown with add option
                    _isLoadingBrands
                        ? const Center(child: CircularProgressIndicator())
                        : InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Brand*',
                              border: OutlineInputBorder(),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedBrandId,
                                      hint: const Text('Select Brand'),
                                      isExpanded: true,
                                      items: _brands.map((brand) {
                                        return DropdownMenuItem<String>(
                                          value: brand['id'],
                                          child: Text(brand['name']),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          final selectedBrand = _brands.firstWhere(
                                            (brand) => brand['id'] == newValue,
                                          );
                                          setState(() {
                                            _selectedBrandId = newValue;
                                            _selectedBrandName = selectedBrand['name'];
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.add_circle, color: AppColors.primaryMaterialColor),
                                  onPressed: _showAddBrandDialog,
                                  tooltip: 'Add New Brand',
                                ),
                              ],
                            ),
                          ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Price and Stock
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            decoration: const InputDecoration(
                              labelText: 'Price (£)*',
                              prefixText: '£',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock*',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid stock';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Discount toggle
                    SwitchListTile(
                      title: const Text('Apply Discount'),
                      subtitle: Text(_hasDiscount
                          ? 'Original price will be displayed with strikethrough'
                          : 'No discount applied'),
                      value: _hasDiscount,
                      activeColor: Theme.of(context).primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _hasDiscount = value;
                        });
                      },
                    ),

                    if (_hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextFormField(
                          controller: _originalPriceController,
                          decoration: const InputDecoration(
                            labelText: 'Original Price (£)*',
                            prefixText: '£',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_hasDiscount) return null;
                            if (value == null || value.isEmpty) {
                              return 'Required for discount';
                            }
                            final originalPrice = double.tryParse(value);
                            final price = double.tryParse(_priceController.text) ?? 0;
                            if (originalPrice == null) {
                              return 'Invalid price';
                            }
                            if (originalPrice <= price) {
                              return 'Must be higher than price';
                            }
                            return null;
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Order Detail Screen
class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({
    required this.orderId,
    super.key,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _orderItems = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch order data from Firestore
      final orderDoc =
          await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();

      if (!orderDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Order not found';
        });
        return;
      }

      // Fetch order items
      final itemsSnapshot =
          await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();

      log(" ======> Order data: ${itemsSnapshot.data()?['items']}");

      setState(() {
        _orderData = {'id': orderDoc.id, ...orderDoc.data() as Map<String, dynamic>};
        _orderItems = (itemsSnapshot.data()?['items'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading order: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Get.back();
            },
            child: const Icon(Icons.arrow_back_ios_rounded)),
        title: Text('Order ${widget.orderId.substring(0, 8)}'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CupertinoActivityIndicator(
          color: AppColors.primaryMaterialColor,
          radius: 7,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchOrderDetails,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderInfo(),
          const SizedBox(height: 24),
          _buildOrderItems(),
          const SizedBox(height: 24),
          _buildOrderSummary(),
          const SizedBox(height: 16),
          //  _buildActions(),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final orderStatus = _orderData!['status'] ?? 'pending';
    final orderDate = _orderData!['createdAt'] != null
        ? (_orderData!['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildStatusChip(orderStatus),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Order ID', widget.orderId),
            _buildInfoRow('Date', DateFormat('MMM dd, yyyy - HH:mm').format(orderDate)),
            if (_orderData!['customerName'] != null)
              _buildInfoRow('Customer', _orderData!['customerName']),
            if (_orderData!['customerPhone'] != null)
              _buildInfoRow('Phone', _orderData!['customerPhone']),
            if (_orderData!['deliveryAddress'] != null)
              _buildInfoRow('Address', _orderData!['deliveryAddress']),
            if (_orderData!['notes'] != null && _orderData!['notes'].isNotEmpty)
              _buildInfoRow('Notes', _orderData!['notes']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        break;
      case 'processing':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.orange;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderItems.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = _orderItems[index];
                return _buildOrderItemTile(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemTile(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final price = item['price'] ?? 0.0;
    final total = item['total'] ?? 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item['imageUrl'] != null)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(item['imageUrl']),
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.placeholderBg,
              borderRadius: BorderRadius.circular(8),
            ),
            // child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['name'] ?? 'Unknown Item',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (item['options'] != null)
                Text(
                  (item['options'] as Map<String, dynamic>)
                      .entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(', '),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              const SizedBox(height: 4),
              Text(
                '${NumberFormat.currency(symbol: '\$').format(price)} x $quantity',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$').format(total),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    final subtotal = _calculateSubtotal();
    final tax = _orderData?['tax'] ?? 0.0;
    final deliveryFee = _orderData?['deliveryFee'] ?? 0.0;
    final discount = _orderData?['discount'] ?? 0.0;
    final total = subtotal + tax + deliveryFee - discount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            _buildSummaryRow('Subtotal', subtotal),
            _buildSummaryRow('Tax', tax),
            _buildSummaryRow('Delivery Fee', deliveryFee),
            if (discount > 0) _buildSummaryRow('Discount', -discount),
            const Divider(height: 16),
            _buildSummaryRow('Total', total, isTotal: true),
            const SizedBox(height: 8),
            Text(
              'Payment: ${_orderData?['paymentMethod'] ?? 'Cash on Delivery'}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateSubtotal() {
    return _orderItems.fold(0.0, (sum, item) {
      final quantity = item['quantity'] ?? 1;
      final price = item['price'] ?? 0.0;
      return sum + quantity * (price is int ? price.toDouble() : price);
    });
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : null,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$').format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }

/*

  Widget _buildActions() {
    final orderStatus = _orderData?['status']?.toString().toLowerCase() ?? 'pending';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (orderStatus == 'pending')
          ElevatedButton.icon(
            onPressed: () => _updateOrderStatus('processing'),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Accept Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        if (orderStatus == 'processing')
          ElevatedButton.icon(
            onPressed: () => _updateOrderStatus('completed'),
            icon: const Icon(Icons.done_all),
            label: const Text('Mark Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.,
              foregroundColor: Colors.white,
            ),
          ),
        if (orderStatus == 'pending' || orderStatus == 'processing')
          ElevatedButton.icon(
            onPressed: () => _showCancelDialog(),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        IconButton(
          onPressed: () {
            // Print order functionality
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing order...')),
            );
          },
          icon: const Icon(Icons.print),
          tooltip: 'Print Order',
        ),
      ],
    );
  }

*/
  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': newStatus});

      setState(() {
        _orderData!['status'] = newStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status: ${e.toString()}')),
      );
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateOrderStatus('cancelled');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> o;
  final String status;
  final DateTime date;
  final String? shopRef;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.o,
    required this.status,
    required this.date,
    this.shopRef,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$day/$month/$year • $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> items = o['items'] ?? [];
    final int itemCount = items.length;
    final String itemSummary =
        itemCount > 0 ? "$itemCount ${itemCount == 1 ? 'item' : 'items'}" : "No items";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => OrderDetailScreen(
              orderId: orderId,
            )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Order ID and Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryMaterialColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_outlined,
                      color: AppColors.primaryMaterialColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order ${orderId.substring(0, 6)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),

              // Order Details
              Row(
                children: [
                  // Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "£${o['total']?.toStringAsFixed(2) ?? '0.00'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primaryMaterialColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Items summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Order Summary",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemSummary,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 20,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
