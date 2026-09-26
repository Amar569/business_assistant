import 'package:business_assistant/domain/entities/payment_entity.dart';
import 'package:business_assistant/domain/repositories/payment_repository_interface.dart';

class RecordPaymentUseCase {
  final PaymentRepositoryInterface repository;

  RecordPaymentUseCase(this.repository);

  Future<void> execute(PaymentEntity payment) {
    return repository.addPayment(payment);
  }
}
