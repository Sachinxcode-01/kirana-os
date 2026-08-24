enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
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
  final String shopId;

  const UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.role = 'cashier',
    required this.shopId,
  });
}

class AuthStateModel {
  final AuthStatus status;
  final UserModel? user;
  final String? activeShopId;
  final String? errorMessage;

  const AuthStateModel({
    required this.status,
    this.user,
    this.activeShopId,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isInitializing => status == AuthStatus.initializing;

  factory AuthStateModel.initializing() =>
      const AuthStateModel(status: AuthStatus.initializing);

  factory AuthStateModel.unauthenticated() =>
      const AuthStateModel(status: AuthStatus.unauthenticated);

  factory AuthStateModel.authenticated(UserModel user, String shopId) =>
      AuthStateModel(
          status: AuthStatus.authenticated, user: user, activeShopId: shopId);

  factory AuthStateModel.error(String message) =>
      AuthStateModel(status: AuthStatus.error, errorMessage: message);

  factory AuthStateModel.sessionExpired() =>
      const AuthStateModel(status: AuthStatus.sessionExpired);
}
