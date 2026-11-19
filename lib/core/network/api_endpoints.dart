/// Central registry of REST API paths (relative to [Env.apiBaseUrl]).
/// Mirrors the INGOOZ Swagger (`/api/v1/...`).
class ApiEndpoints {
  ApiEndpoints._();

  static const String _v1 = '/api/v1';

  // --- auth ---
  static const String requestCode = '$_v1/auth/request-code/';
  static const String verifyCode = '$_v1/auth/verify-code/';
  static const String token = '$_v1/auth/token/';
  static const String tokenRefresh = '$_v1/auth/token/refresh/';
  static const String loginEmail = '$_v1/auth/login/email/';
  static const String registerEmail = '$_v1/auth/register/email/';
  static const String passwordChange = '$_v1/auth/password/change/';
  static const String emailChange = '$_v1/auth/email/change/';

  // --- password reset by email code (OTP) ---
  static const String passwordResetRequest = '$_v1/auth/password-reset/request/';
  static const String passwordResetVerify = '$_v1/auth/password-reset/verify/';
  static const String passwordResetConfirm = '$_v1/auth/password-reset/confirm/';

  // --- profile / billing ---
  static const String profile = '$_v1/profile/';
  static const String balance = '$_v1/balance/';
  static const String payments = '$_v1/payments/';
  static const String paymentsCreate = '$_v1/payments/create/';
  static const String transactions = '$_v1/transactions/';

  // --- catalog ---
  static const String guide = '$_v1/guide/';
  static const String promoApply = '$_v1/promo/apply/';
  static const String promoRedemptions = '$_v1/promo/redemptions/';
  static const String vehicles = '$_v1/vehicles/';
  static String vehicle(Object id) => '$_v1/vehicles/$id/';

  // --- waybills ---
  static const String waybills = '$_v1/waybills/';
  static String waybill(Object id) => '$_v1/waybills/$id/';
  static const String waybillIssue = '$_v1/waybills/issue/';
  static const String waybillQuote = '$_v1/waybills/quote/';
}
