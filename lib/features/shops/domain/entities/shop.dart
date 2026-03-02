class Shop {
  final int id;
  final String name;
  final String address;
  final String? workingHours;
  final String? contacts;
  final String? phone;
  final String? email;
  final String? website;
  final double? price;
  final int? quantity;
  final double? lat;
  final double? lng;
  final int? distanceM;

  Shop({
    required this.id,
    required this.name,
    required this.address,
    this.workingHours,
    this.contacts,
    this.phone,
    this.email,
    this.website,
    this.price,
    this.quantity,
    this.lat,
    this.lng,
    this.distanceM,
  });

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, address: $address, workingHours: $workingHours, contacts: $contacts, phone: $phone, email: $email, website: $website, price: $price, quantity: $quantity, lat: $lat, lng: $lng, distanceM: $distanceM)';
  }
}