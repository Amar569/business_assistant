import 'dart:convert';
import 'package:business_assistant/domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.customerId,
    required super.date,
    super.dueDate,
    required super.subtotal,
    required super.tax,
    required super.taxRate,
    required super.total,
    required super.status,
    required super.items,
    super.notes,
    required super.createdAt,
    super.updatedAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      customerId: json['customerId'] as String,
      date: json['date'] as String,
      dueDate: json['dueDate'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      items: (json['items'] as List)
          .map(
              (item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
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
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'date': date,
      'dueDate': dueDate,
      'subtotal': subtotal,
      'tax': tax,
      'taxRate': taxRate,
      'total': total,
      'status': status,
      'items':
          items.map((item) => (item as InvoiceItemModel).toJson()).toList(),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InvoiceModel.fromEntity(InvoiceEntity entity) {
    return InvoiceModel(
      id: entity.id,
      invoiceNumber: entity.invoiceNumber,
      customerId: entity.customerId,
      date: entity.date,
      dueDate: entity.dueDate,
      subtotal: entity.subtotal,
      tax: entity.tax,
      taxRate: entity.taxRate,
      total: entity.total,
      status: entity.status,
      items: entity.items
          .map((item) => InvoiceItemModel.fromEntity(item))
          .toList(),
      notes: entity.notes,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'customerId': customerId,
      'date': date,
      'dueDate': dueDate,
      'subtotal': subtotal,
      'tax': tax,
      'taxRate': taxRate,
      'total': total,
      'status': status,
      'items': jsonEncode(
          items.map((item) => (item as InvoiceItemModel).toJson()).toList()),
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id'] as String,
      invoiceNumber: map['invoiceNumber'] as String,
      customerId: map['customerId'] as String,
      date: map['date'] as String,
      dueDate: map['dueDate'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      tax: (map['tax'] as num).toDouble(),
      taxRate: (map['taxRate'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      status: map['status'] as String,
      items: (jsonDecode(map['items'] as String) as List)
          .map(
              (item) => InvoiceItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.id,
    required super.description,
    required super.quantity,
    required super.rate,
    required super.amount,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as int,
      rate: (json['rate'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'rate': rate,
      'amount': amount,
    };
  }

  factory InvoiceItemModel.fromEntity(InvoiceItemEntity entity) {
    return InvoiceItemModel(
      id: entity.id,
      description: entity.description,
      quantity: entity.quantity,
      rate: entity.rate,
      amount: entity.amount,
    );
  }
}
