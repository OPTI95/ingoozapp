import '../../../../core/error/error_mapper.dart';
import '../../domain/entities/balance.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/billing_repository.dart';
import '../datasources/billing_remote_data_source.dart';

class BillingRepositoryImpl implements BillingRepository {
  BillingRepositoryImpl(this._remote);

  final BillingRemoteDataSource _remote;

  @override
  Future<Balance> getBalance() async {
    try {
      return await _remote.getBalance();
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<Payment>> getPayments() async {
    try {
      return await _remote.getPayments();
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<Payment> createPayment(int amount) async {
    try {
      return await _remote.createPayment(amount);
    } catch (e) {
      throw failureFromException(e);
    }
  }

  @override
  Future<List<BalanceTransaction>> getTransactions() async {
    try {
      return await _remote.getTransactions();
    } catch (e) {
      throw failureFromException(e);
    }
  }
}
