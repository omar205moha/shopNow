import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_now_mobile/models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class MainCartController extends GetxController {
  final RxList<CartItem> _cartItems = <CartItem>[].obs;

  List<CartItem> get cartItems => _cartItems;

  // Calculate total items in cart
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  // Calculate total price of items in cart
  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  // Add product to cart
  void addToCart(Product product, int quantity) {
    final existingIndex = _cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // Product already exists in cart, update quantity
      final existingItem = _cartItems[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      _cartItems[existingIndex] = updatedItem;
    } else {
      // Product doesn't exist in cart, add new item
      _cartItems.add(CartItem(
        product: product,
        quantity: quantity,
      ));
    }

    // save cart to local storage or user account here
    saveCartToLocalStorage();
  }

  // Update item quantity in cart
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere(
      (item) => item.product.id == productId,
    );

    if (index >= 0) {
      final item = _cartItems[index];
      _cartItems[index] = item.copyWith(quantity: quantity);
      saveCartToLocalStorage();
    }
  }

  // Remove item from cart
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    saveCartToLocalStorage();
  }

  // Clear entire cart
  void clearCart() {
    _cartItems.clear();
    saveCartToLocalStorage();
  }

  // Save cart to local storage (example placeholder)
  void saveCartToLocalStorage() {
    // For now, this is just a placeholder
  }

  // Load cart from local storage (example placeholder)
  void loadCartFromLocalStorage() {
    // For now, this is just a placeholder
  }

  @override
  void onInit() {
    super.onInit();
    loadCartFromLocalStorage();
  }
}
