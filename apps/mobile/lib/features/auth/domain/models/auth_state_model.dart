enum AuthStatus {
  initializing,
  unauthenticated,
  authenticatedWithoutShop,
  authenticatedWithShop,
  authenticating,
  error,
  sessionExpired,
}

class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final String role;
  final String? shopId;
  final String? shopName;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.role = 'owner',
    this.shopId,
    this.shopName,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? role,
    String? shopId,
    String? shopName,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
    );
  }
}

class AuthStateModel {
  final AuthStatus status;
  final UserModel? user;
  final String? activeShopId;
  final String? activeShopName;
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.activeShopId,
    this.activeShopName,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      (status == AuthStatus.authenticatedWithShop ||
          status == AuthStatus.authenticatedWithoutShop) &&
      user != null;

  bool get hasActiveShop =>
      status == AuthStatus.authenticatedWithShop &&
      activeShopId != null &&
      activeShopId!.isNotEmpty;

  bool get isInitializing => status == AuthStatus.initializing;
  bool get isAuthenticating => status == AuthStatus.authenticating;

  factory AuthStateModel.initializing() =>
      const AuthStateModel(status: AuthStatus.initializing);

  factory AuthStateModel.unauthenticated() =>
      const AuthStateModel(status: AuthStatus.unauthenticated);

  factory AuthStateModel.authenticatedWithoutShop(UserModel user) =>
      AuthStateModel(
        status: AuthStatus.authenticatedWithoutShop,
        user: user,
      );

  factory AuthStateModel.authenticatedWithShop({
    required UserModel user,
    required String shopId,
    required String shopName,
  }) =>
      AuthStateModel(
        status: AuthStatus.authenticatedWithShop,
        user: user,
        activeShopId: shopId,
        activeShopName: shopName,
      );

  factory AuthStateModel.error(String message) =>
      AuthStateModel(status: AuthStatus.error, errorMessage: message);

  factory AuthStateModel.sessionExpired() =>
      const AuthStateModel(status: AuthStatus.sessionExpired);
}
