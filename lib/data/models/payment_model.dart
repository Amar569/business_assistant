import 'package:business_assistant/domain/entities/payment_entity.dart';

class PaymentModel extends PaymentEntity {
  const PaymentModel({
    required super.id,
    required super.invoiceId,
    required super.customerId,
    required super.amount,
    required super.paymentDate,
    required super.paymentMethod,
    super.transactionId,
    required super.status,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      invoiceId: json['invoiceId'] as String,
      customerId: json['customerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate'] as String),
      paymentMethod: json['paymentMethod'] as String,
      transactionId: json['transactionId'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromEntity(PaymentEntity entity) {
    return PaymentModel(
      id: entity.id,
      invoiceId: entity.invoiceId,
      customerId: entity.customerId,
      amount: entity.amount,
      paymentDate: entity.paymentDate,
      paymentMethod: entity.paymentMethod,
      transactionId: entity.transactionId,
      status: entity.status,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'customerId': customerId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String,
      invoiceId: map['invoiceId'] as String,
      customerId: map['customerId'] as String,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      paymentMethod: map['paymentMethod'] as String,
      transactionId: map['transactionId'] as String?,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
