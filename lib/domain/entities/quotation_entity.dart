class QuotationItemEntity {
  final String id;
  final String description;
  final int quantity;
  final double rate;
  final double amount;

  QuotationItemEntity({
    required this.id,
    required this.description,
    required this.quantity,
    required this.rate,
    required this.amount,
  });
}

class QuotationEntity {
  final String id;
  final String quotationNumber;
  final String customerId;
  final String customerName;
  final String date;
  final String? validUntil;
  final double subtotal;
  final double tax;
  final double taxRate;
  final double total;
  final String status; // Draft, Sent, Accepted, Rejected, Expired
  final List<QuotationItemEntity> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuotationEntity({
    required this.id,
    required this.quotationNumber,
    required this.customerId,
    required this.customerName,
    required this.date,
    this.validUntil,
    required this.subtotal,
    required this.tax,
    required this.taxRate,
    required this.total,
    required this.status,
    required this.items,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
}
