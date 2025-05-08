// lib/widgets/product_form.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductForm extends StatefulWidget {
  final CollectionReference productsRef;
  final String? productId;
  final Map<String, dynamic>? initialData;
  const ProductForm({
    super.key,
    required this.productsRef,
    this.productId,
    this.initialData,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _origPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  bool _featured = false;

  List<QueryDocumentSnapshot>? _categories;
  List<QueryDocumentSnapshot>? _brands;
  DocumentReference? _selectedCategory;
  DocumentReference? _selectedBrand;

  @override
  void initState() {
    super.initState();
    _loadLists();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _nameCtrl.text = d['name'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _priceCtrl.text = (d['price'] ?? '').toString();
      _origPriceCtrl.text = (d['originalPrice'] ?? '').toString();
      _stockCtrl.text = (d['stock'] ?? '').toString();
      _unitCtrl.text = d['unit'] ?? '';
      _imageCtrl.text = d['imageUrl'] ?? '';
      _featured = d['featured'] ?? false;
      _selectedCategory = d['categoryRef'];
      _selectedBrand = d['brandRef'];
    }
  }

  Future<void> _loadLists() async {
    final cats = await FirebaseFirestore.instance.collection('categories').get();
    final brs = await FirebaseFirestore.instance.collection('brands').get();
    setState(() {
      _categories = cats.docs;
      _brands = brs.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.productId == null ? 'Add Product' : 'Edit Product',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceCtrl,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
              ),
              TextFormField(
                controller: _origPriceCtrl,
                decoration: const InputDecoration(labelText: 'Original Price'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
              ),
              TextFormField(
                controller: _stockCtrl,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null,
              ),
              TextFormField(
                controller: _unitCtrl,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextFormField(
                controller: _imageCtrl,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Text('Featured'),
                Checkbox(value: _featured, onChanged: (v) => setState(() => _featured = v!)),
              ]),
              const SizedBox(height: 8),
              if (_categories != null)
                DropdownButtonFormField<DocumentReference>(
                  value: _selectedCategory,
                  items: _categories!
                      .map((doc) => DropdownMenuItem(
                            value: doc.reference,
                            child: Text(doc['name']),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  decoration: const InputDecoration(labelText: 'Category'),
                  validator: (v) => v == null ? 'Select one' : null,
                ),
              if (_brands != null)
                DropdownButtonFormField<DocumentReference>(
                  value: _selectedBrand,
                  items: _brands!
                      .map((doc) => DropdownMenuItem(
                            value: doc.reference,
                            child: Text(doc['name']),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBrand = v),
                  decoration: const InputDecoration(labelText: 'Brand'),
                  validator: (v) => v == null ? 'Select one' : null,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _save,
                child: const Text('Save'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.parse(_priceCtrl.text.trim()),
      'originalPrice': double.parse(_origPriceCtrl.text.trim()),
      'unit': _unitCtrl.text.trim(),
      'stock': int.parse(_stockCtrl.text.trim()),
      'featured': _featured,
      'imageUrl': _imageCtrl.text.trim(),
      'categoryRef': _selectedCategory,
      'categoryName': null,
      'brandRef': _selectedBrand,
      'brandName': null,
      'updatedAt': DateTime.now(),
      'createdAt':
          widget.initialData != null ? widget.initialData!['createdAt'].toDate() : DateTime.now(),
      'sellerRef': widget.productsRef.parent,
    };
    if (widget.productId != null) {
      await widget.productsRef.doc(widget.productId).update(data);
    } else {
      await widget.productsRef.doc().set(data);
    }
    Navigator.pop(context);
  }
}

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    return Scaffold(
      appBar: AppBar(title: Text('Order $orderId')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: orderRef.snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.active) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }
          final o = snapshot.data!.data()! as Map<String, dynamic>;
          final items = o['items'] as List<dynamic>;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Status: \${o['status']}", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text("Total: £\${o['total']}", style: TextStyle(fontSize: 16)),
                const Divider(height: 24),
                const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final it = items[i] as Map<String, dynamic>;
                      return ListTile(
                        title: Text(it['name']),
                        subtitle: const Text("Qty: \${it['quantity']}  •  Unit: \${it['unit']}"),
                        trailing: const Text("£\${it['price']}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
