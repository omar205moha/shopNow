import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String line1;
  final String? city;
  final String? postal;
  final String? country;
  final GeoPoint? location;

  Address({
    required this.line1,
    this.city,
    this.postal,
    this.country,
    this.location,
  });

  factory Address.fromMap(Map<String, dynamic> data) => Address(
        line1: data['line1'],
        city: data['city'],
        postal: data['postal'],
        country: data['country'],
        location: data['location'],
      );

  Map<String, dynamic> toMap() => {
        'line1': line1,
        if (city != null) 'city': city,
        if (postal != null) 'postal': postal,
        if (country != null) 'country': country,
        if (location != null) 'location': location,
      };
}
