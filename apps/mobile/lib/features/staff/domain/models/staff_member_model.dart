enum StaffRole {
  owner,
  manager,
  cashier,
  inventoryStaff,
}

extension StaffRoleExtension on StaffRole {
  String get value {
    switch (this) {
      case StaffRole.owner:
        return 'owner';
      case StaffRole.manager:
        return 'manager';
      case StaffRole.cashier:
        return 'cashier';
      case StaffRole.inventoryStaff:
        return 'inventory_staff';
    }
  }

  String get label {
    switch (this) {
      case StaffRole.owner:
        return 'OWNER';
      case StaffRole.manager:
        return 'MANAGER';
      case StaffRole.cashier:
        return 'CASHIER';
      case StaffRole.inventoryStaff:
        return 'INVENTORY STAFF';
    }
  }

  static StaffRole fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'owner':
        return StaffRole.owner;
      case 'manager':
        return StaffRole.manager;
      case 'cashier':
        return StaffRole.cashier;
      case 'inventory_staff':
      case 'inventorystaff':
      case 'inventory staff':
        return StaffRole.inventoryStaff;
      default:
        return StaffRole.cashier;
    }
  }
}

enum StaffStatus {
  active,
  pending,
  deactivated,
}

extension StaffStatusExtension on StaffStatus {
  String get value {
    switch (this) {
      case StaffStatus.active:
        return 'active';
      case StaffStatus.pending:
        return 'pending';
      case StaffStatus.deactivated:
        return 'deactivated';
    }
  }

  String get label {
    switch (this) {
      case StaffStatus.active:
        return 'ACTIVE';
      case StaffStatus.pending:
        return 'PENDING';
      case StaffStatus.deactivated:
        return 'DEACTIVATED';
    }
  }

  static StaffStatus fromString(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'active':
        return StaffStatus.active;
      case 'pending':
        return StaffStatus.pending;
      case 'deactivated':
      case 'inactive':
        return StaffStatus.deactivated;
      default:
        return StaffStatus.active;
    }
  }
}

class StaffMemberModel {
  final String id;
  final String shopId;
  final String? userId;
  final String email;
  final String? displayName;
  final String? phone;
  final StaffRole role;
  final StaffStatus status;
  final DateTime createdAt;

  const StaffMemberModel({
    required this.id,
    required this.shopId,
    this.userId,
    required this.email,
    this.displayName,
    this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  bool get isOwner => role == StaffRole.owner;
  bool get isActive => status == StaffStatus.active;
  bool get isPending => status == StaffStatus.pending;
  bool get isDeactivated => status == StaffStatus.deactivated;

  StaffMemberModel copyWith({
    String? id,
    String? shopId,
    String? userId,
    String? email,
    String? displayName,
    String? phone,
    StaffRole? role,
    StaffStatus? status,
    DateTime? createdAt,
  }) {
    return StaffMemberModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory StaffMemberModel.fromJson(Map<String, dynamic> json) {
    return StaffMemberModel(
      id: json['id'] as String,
      shopId: json['shop_id'] as String,
      userId: json['user_id'] as String?,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String?,
      phone: json['phone'] as String?,
      role: StaffRoleExtension.fromString(json['role'] as String? ?? 'cashier'),
      status: StaffStatusExtension.fromString(
          json['status'] as String? ?? 'active'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'user_id': userId,
      'email': email,
      'display_name': displayName,
      'phone': phone,
      'role': role.value,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
