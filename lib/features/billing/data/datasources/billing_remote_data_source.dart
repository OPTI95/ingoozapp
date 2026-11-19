import 'package:dio/dio.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/balance_model.dart';
import '../models/payment_model.dart';
import '../models/transaction_model.dart';

/// HTTP access to balance/payments/transactions. Throws an [AppException].
abstract class BillingRemoteDataSource {
  Future<BalanceModel> getBalance();
  Future<List<PaymentModel>> getPayments();
  Future<PaymentModel> createPayment(int amount);
  Future<List<TransactionModel>> getTransactions();
}

class BillingRemoteDataSourceImpl implements BillingRemoteDataSource {
  BillingRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<BalanceModel> getBalance() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.balance);
      return BalanceModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<List<PaymentModel>> getPayments() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.payments);
      return (res.data ?? const [])
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<PaymentModel> createPayment(int amount) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentsCreate,
        data: {'amount': amount},
      );
      return PaymentModel.fromJson(res.data ?? const {});
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.transactions);
      return (res.data ?? const [])
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw exceptionFromDio(e);
    }
  }
}
