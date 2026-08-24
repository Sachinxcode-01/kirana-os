import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kirana_mobile/core/extensions/num_extensions.dart';
import 'package:kirana_mobile/core/theme/colors.dart';
import 'package:kirana_mobile/core/theme/spacing.dart';
import 'package:kirana_mobile/core/theme/typography.dart';
import 'package:kirana_mobile/core/widgets/app_button.dart';

// --- DOMAIN ENTITIES ---
class CartItemEntity {
  final String id;
  final String productId;
  final String productName;
  final int unitPricePaise;
  final double quantity;

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPricePaise,
    required this.quantity,
  });

  int get totalPaise => (unitPricePaise * quantity).round();

  CartItemEntity copyWith({double? quantity}) {
    return CartItemEntity(
      id: id,
      productId: productId,
      productName: productName,
      unitPricePaise: unitPricePaise,
      quantity: quantity ?? this.quantity,
    );
  }
}

// --- CART NOTIFIER ---
class CartNotifier extends StateNotifier<List<CartItemEntity>> {
  CartNotifier()
      : super([
          const CartItemEntity(
            id: 'ci_1',
            productId: 'p_1',
            productName: 'Aashirvaad Atta 5kg',
            unitPricePaise: 24500, // ₹245.00
            quantity: 1,
          ),
          const CartItemEntity(
            id: 'ci_2',
            productId: 'p_2',
            productName: 'Tata Salt 1kg',
            unitPricePaise: 2800, // ₹28.00
            quantity: 2,
          ),
          const CartItemEntity(
            id: 'ci_3',
            productId: 'p_3',
            productName: 'Maggi 2-Min Noodles 70g',
            unitPricePaise: 1400, // ₹14.00
            quantity: 4,
          ),
        ]);

  void addItem(CartItemEntity item) {
    final existingIndex =
        state.indexWhere((element) => element.productId == item.productId);
    if (existingIndex >= 0) {
      final current = state[existingIndex];
      state = [
        ...state.sublist(0, existingIndex),
        current.copyWith(quantity: current.quantity + item.quantity),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void updateQuantity(String id, double qty) {
    if (qty <= 0) {
      removeItem(id);
    } else {
      state = [
        for (final item in state)
          if (item.id == id) item.copyWith(quantity: qty) else item,
      ];
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemEntity>>((ref) {
  return CartNotifier();
});

final cartTotalPaiseProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.totalPaise);
});

// --- PRESENTATION SCREEN ---
class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalPaise = ref.watch(cartTotalPaiseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Terminal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/barcode'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => ref.read(cartProvider.notifier).clearCart(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cart Items List
          Expanded(
            child: cart.isEmpty
                ? const Center(
                    child: Text('Cart is empty. Scan product to begin.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(KiranaSpacing.md),
                    itemCount: cart.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: KiranaSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = cart[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(KiranaSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: KiranaTypography.titleMedium,
                                    ),
                                    const SizedBox(height: KiranaSpacing.xxs),
                                    Text(
                                      '${item.unitPricePaise.toRupeesString()} each',
                                      style: KiranaTypography.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon:
                                        const Icon(Icons.remove_circle_outline),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            item.id, item.quantity - 1),
                                  ),
                                  Text(
                                    item.quantity.toInt().toString(),
                                    style: KiranaTypography.labelLarge,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                            item.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                              const SizedBox(width: KiranaSpacing.md),
                              Text(
                                item.totalPaise.toRupeesString(),
                                style: KiranaTypography.priceTabular,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Total Bar & Checkout Button
          Container(
            padding: const EdgeInsets.all(KiranaSpacing.lg),
            decoration: const BoxDecoration(
              color: KiranaColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Grand Total',
                            style: KiranaTypography.labelSmall),
                        Text(
                          totalPaise.toRupeesString(),
                          style: KiranaTypography.displayTotal.copyWith(
                            color: KiranaColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KiranaSpacing.lg),
                  AppButton(
                    label: 'CHECKOUT (${cart.length})',
                    icon: Icons.payments_outlined,
                    onPressed:
                        cart.isEmpty ? null : () => context.push('/payments'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
