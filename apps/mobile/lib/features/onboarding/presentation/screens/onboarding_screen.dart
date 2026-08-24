import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/radius.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.qr_code_scanner,
      title: 'Ultra-Fast Barcode POS',
      description:
          'Scan groceries and packaged items in under 15ms. Create instant bills with UPI dynamic QR and Bluetooth thermal receipts.',
    ),
    _OnboardingPageData(
      icon: Icons.cloud_sync,
      title: '100% Offline-First Durability',
      description:
          'Power cut or no internet? Never stop billing. Your sales, stock, and customer debt save locally and sync seamlessly to the cloud.',
    ),
    _OnboardingPageData(
      icon: Icons.account_balance_wallet,
      title: 'Smart Khata & Udhaar Ledger',
      description:
          'Track customer credits and partial payments with zero math errors. Send automated WhatsApp payment reminders.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/shop-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.go('/shop-setup'),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: KiranaColors.neutral600,
              ),
            ),
          ),
          const SizedBox(width: KiranaSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KiranaSpacing.xxl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: KiranaColors.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: KiranaColors.primaryLight.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            page.icon,
                            size: 60,
                            color: KiranaColors.primary,
                          ),
                        ),
                        const SizedBox(height: KiranaSpacing.xxl),
                        Text(
                          page.title,
                          style: KiranaTypography.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: KiranaColors.neutral900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: KiranaSpacing.md),
                        Text(
                          page.description,
                          style: KiranaTypography.bodyLarge.copyWith(
                            color: KiranaColors.neutral600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicator Dots & Action Button
            Padding(
              padding: const EdgeInsets.all(KiranaSpacing.xl),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? KiranaColors.primary
                              : KiranaColors.neutral300,
                          borderRadius: KiranaRadius.borderPill,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: KiranaSpacing.xl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AppButton(
                      label: _currentPage == _pages.length - 1
                          ? 'Setup Your Store →'
                          : 'Continue →',
                      onPressed: _onNext,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}
