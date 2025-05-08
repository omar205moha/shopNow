/*

class CartController extends GetxController {
  final RxList<CartItem> _items = <CartItem>[].obs;
  final RxDouble _discount = 0.0.obs;

  List<CartItem> get items => _items;
  double get discount => _discount.value;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get total {
    return subtotal + 2.0 - _discount.value; // 2.0 is delivery cost
  }

  void addItem(CartItem item) {
    final existingItemIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingItemIndex >= 0) {
      _items[existingItemIndex] = CartItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: _items[existingItemIndex].quantity + item.quantity,
        image: item.image,
      );
    } else {
      _items.add(item);
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
  }

  void updateQuantity(String id, int quantity) {
    final itemIndex = _items.indexWhere((item) => item.id == id);
    if (itemIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(itemIndex);
      } else {
        _items[itemIndex] = CartItem(
          id: _items[itemIndex].id,
          name: _items[itemIndex].name,
          price: _items[itemIndex].price,
          quantity: quantity,
          image: _items[itemIndex].image,
        );
      }
    }
  }

  void applyDiscount(double discount) {
    _discount.value = discount;
  }

  Future<void> clearCart() async {
    _items.clear();
    _discount.value = 0;
  }
}

*/
