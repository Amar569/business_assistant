import 'package:business_assistant/domain/entities/payment_entity.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class GetPendingPaymentsUseCase {
  final PaymentRepositoryInterface repository;

  GetPendingPaymentsUseCase(this.repository);

  Future<List<PaymentEntity>> execute() {
    return repository.getPendingPayments();
  }
}
