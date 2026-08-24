import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';
import 'package:kirana_mobile/core/widgets/app_text_field.dart';

// --- DOMAIN LAYER ---
class UserEntity {
  final String id;
  final String phone;
  final String role;
  final String displayName;

  const UserEntity({
    required this.id,
    required this.phone,
    required this.role,
    required this.displayName,
  });
}

abstract class AuthRepository {
  Future<UserEntity> loginWithPhoneOtp(String phone, String otp);
  Future<bool> verifyQuickPin(String pin);
  Future<void> logout();
}

// --- DATA LAYER ---
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserEntity> loginWithPhoneOtp(String phone, String otp) async {
    return UserEntity(
      id: 'usr_1',
      phone: phone,
      role: 'owner',
      displayName: 'Shop Owner',
    );
  }

  @override
  Future<bool> verifyQuickPin(String pin) async => pin.length == 4;

  @override
  Future<void> logout() async {}
}

// --- PRESENTATION LAYER ---
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  final bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KiranaSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(KiranaSpacing.xl),
                  decoration: const BoxDecoration(
                    color: KiranaColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront,
                    size: 56,
                    color: KiranaColors.primary,
                  ),
                ),
                const SizedBox(height: KiranaSpacing.xl),
                Text(
                  'KiranaOS',
                  style: KiranaTypography.displayTotal.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'Fast Retail Point of Sale',
                  style: KiranaTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KiranaSpacing.xxl),
                AppTextField(
                  label: 'Phone Number',
                  hint: 'Enter 10-digit mobile number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_android),
                ),
                if (_otpSent) ...[
                  const SizedBox(height: KiranaSpacing.lg),
                  AppTextField(
                    label: 'OTP Verification',
                    hint: 'Enter 6-digit OTP',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ],
                const SizedBox(height: KiranaSpacing.xl),
                AppButton(
                  label: _otpSent ? 'Verify & Login' : 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: () {
                    setState(() {
                      if (!_otpSent) {
                        _otpSent = true;
                      } else {
                        // Logged in
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
