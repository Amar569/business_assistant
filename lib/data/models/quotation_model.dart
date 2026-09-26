import 'dart:convert';
import 'package:business_assistant/domain/entities/quotation_entity.dart';

class QuotationModel extends QuotationEntity {
  QuotationModel({
    required super.id,
    required super.quotationNumber,
    required super.customerId,
    required super.customerName,
    required super.date,
    super.validUntil,
    required super.subtotal,
    required super.tax,
    required super.taxRate,
    required super.total,
    required super.status,
    required super.items,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory QuotationModel.fromEntity(QuotationEntity entity) {
    return QuotationModel(
      id: entity.id,
      quotationNumber: entity.quotationNumber,
      customerId: entity.customerId,
      customerName: entity.customerName,
      date: entity.date,
      validUntil: entity.validUntil,
      subtotal: entity.subtotal,
      tax: entity.tax,
      taxRate: entity.taxRate,
      total: entity.total,
      status: entity.status,
      items: entity.items,
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory QuotationModel.fromMap(Map<String, dynamic> map) {
    final itemsList = (jsonDecode(map['items'] as String) as List)
        .map((itemMap) => QuotationItemEntity(
              id: itemMap['id'] as String,
              description: itemMap['description'] as String,
              quantity: itemMap['quantity'] as int,
              rate: (itemMap['rate'] as num).toDouble(),
              amount: (itemMap['amount'] as num).toDouble(),
            ))
        .toList();

    return QuotationModel(
      id: map['id'] as String,
      quotationNumber: map['quotationNumber'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String,
      date: map['date'] as String,
      validUntil: map['validUntil'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      taxRate: (map['taxRate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      items: itemsList,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationNumber': quotationNumber,
      'customerId': customerId,
      'customerName': customerName,
      'date': date,
      'validUntil': validUntil,
      'subtotal': subtotal,
      'tax': tax,
      'taxRate': taxRate,
      'total': total,
      'status': status,
      'items': jsonEncode(items
          .map((item) => {
                'id': item.id,
                'description': item.description,
                'quantity': item.quantity,
                'rate': item.rate,
                'amount': item.amount,
              })
          .toList()),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
