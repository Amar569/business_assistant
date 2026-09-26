import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final double outstandingBalance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.gstin,
    this.outstandingBalance = 0,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        address,
        gstin,
        outstandingBalance,
        createdAt,
        updatedAt,
      ];

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? gstin,
    double? outstandingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstin: gstin ?? this.gstin,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
