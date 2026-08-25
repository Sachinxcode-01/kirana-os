class PaymentModel {
  final String id;
  final String shopId;
  final String billId;
  final String mode; // 'cash', 'upi_qr', 'card'
  final int amountPaise;
  final String status; // 'pending', 'success', 'failed'
  final String? referenceNumber;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.shopId,
    required this.billId,
    required this.mode,
    required this.amountPaise,
    this.status = 'pending',
    this.referenceNumber,
    required this.createdAt,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';

  PaymentModel copyWith({
    String? id,
    String? shopId,
    String? billId,
    String? mode,
    int? amountPaise,
    String? status,
    String? referenceNumber,
    DateTime? createdAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      billId: billId ?? this.billId,
      mode: mode ?? this.mode,
      amountPaise: amountPaise ?? this.amountPaise,
      status: status ?? this.status,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shop_id': shopId,
        'bill_id': billId,
        'mode': mode,
        'amount_paise': amountPaise,
        'status': status,
        'reference_number': referenceNumber,
        'created_at': createdAt.toIso8601String(),
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['id'] as String,
        shopId: json['shop_id'] as String,
        billId: json['bill_id'] as String,
        mode: json['mode'] as String,
        amountPaise: (json['amount_paise'] as num).toInt(),
        status: json['status'] as String? ?? 'pending',
        referenceNumber: json['reference_number'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
      );
}
