class PaymentMethod {
  final String id;
  final String type;
  final String last4;

  PaymentMethod({required this.id, required this.type, required this.last4});

  factory PaymentMethod.fromMap(Map<String, dynamic> data) => PaymentMethod(
        id: data['id'],
        type: data['type'],
        last4: data['last4'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'last4': last4,
      };
}
