import '../../core/utils/json.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.avatar,
    this.shopName,
  });

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final String? avatar;
  final String? shopName;

  bool get isSeller {
    final r = role?.toLowerCase() ?? '';
    return r.contains('seller') || r.contains('admin') || r.contains('owner');
  }

  String get firstName => name.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromJson(Json j) {
    final profile = asJson(j['profile']);
    return AppUser(
      id: str(pick(j, ['_id', 'id'])),
      name: str(pick(j, ['name', 'fullName']) ?? pick(profile, ['name']), 'CartBoat shopper'),
      email: str(j['email']),
      phone: strOrNull(pick(j, ['phone', 'phoneNumber']) ?? pick(profile, ['phone'])),
      role: strOrNull(pick(j, ['role', 'userType', 'profileType'])),
      avatar: usableImageUrl(pick(j, ['avatar', 'image', 'photo']) ?? pick(profile, ['avatar', 'image'])),
      shopName: strOrNull(pick(j, ['shopName']) ?? pick(profile, ['shopName'])),
    );
  }
}
