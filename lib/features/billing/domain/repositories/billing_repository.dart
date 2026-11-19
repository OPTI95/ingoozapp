import '../entities/balance.dart';
import '../entities/payment.dart';
import '../entities/transaction.dart';

/// Contract for balance, payments and transactions. Implementations throw a
/// [Failure] (from `core/error`) on any error.
abstract class BillingRepository {
  /// `GET /balance/`
  Future<Balance> getBalance();

  /// `GET /payments/`
  Future<List<Payment>> getPayments();

  /// `POST /payments/create/` — returns a payment carrying `payment_url`.
  Future<Payment> createPayment(int amount);

  /// `GET /transactions/`
  Future<List<BalanceTransaction>> getTransactions();
}
