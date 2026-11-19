import 'package:flutter/material.dart';

import '../../features/auth/pages/sign_in_page.dart';
import '../../features/auth/pages/sign_up_page.dart';
import '../../features/auth/pages/whatsapp_code_page.dart';
import '../../features/auth/pages/reset_password_page.dart';
import '../../features/auth/pages/email_confirmed_page.dart';
import '../../features/auth/pages/email_change_confirm_page.dart';
import '../../features/auth/pages/email_link_expired_page.dart';
import '../../features/auth/pages/phone_sign_in_page.dart';
import '../../features/auth/pages/set_password_page.dart';
import '../../features/auth/pages/password_reset_email_page.dart';
import '../../features/auth/pages/password_reset_code_page.dart';
import '../../features/auth/pages/password_reset_new_password_page.dart';
import '../../features/cars/pages/cars_list_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/admin/pages/stamps_settings_page.dart';
import '../../features/waybill/pages/waybill_admin_panel_page.dart';
import '../../features/waybills/presentation/pages/waybills_page.dart';
import '../../features/payments/pages/payment_method_page.dart';
import '../../features/info/pages/guide_page.dart';
import '../../features/info/pages/contacts_page.dart';
import '../../features/promo/pages/promo_page.dart';
import '../../features/promo/pages/promo_admin_page.dart';

/// Centralized router configuration. Replace placeholders as routes appear.
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static String? _expiredReasonFromQuery(Map<String, String> queryParams) {
    final type = queryParams['type'];
    if (type == 'recovery') return 'recovery';
    if (type == 'signup') return 'signup';
    if (type == 'magiclink') return 'email_change';
    return queryParams['reason'];
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Парсим URL и параметры
    final raw = settings.name ?? '';
    final uri = Uri.tryParse(raw);
    final queryParams = <String, String>{...?uri?.queryParameters};
    // Supabase часто кладёт токены/параметры в fragment (#...).
    final fragment = uri?.fragment ?? '';
    if (fragment.isNotEmpty) {
      final fragmentUri = Uri.tryParse('?$fragment');
      if (fragmentUri != null) {
        queryParams.addAll(fragmentUri.queryParameters);
      }
    }

    // Просроченная/невалидная ссылка auth: показываем специальный экран.
    final hasExpiredAuthError =
        queryParams['error'] == 'access_denied' ||
        queryParams['error_code'] == 'otp_expired' ||
        raw.contains('otp_expired') ||
        raw.contains('Email link is invalid or has expired');
    if (hasExpiredAuthError) {
      return _material(
        EmailLinkExpiredPage(
          reason: _expiredReasonFromQuery(queryParams),
        ),
      );
    }

    // Для custom scheme вида ingoozapp://email-change-confirm path обычно пустой,
    // а нужный маршрут лежит в host.
    final path = (uri != null && uri.path.isNotEmpty)
        ? uri.path
        : (uri != null && uri.host.isNotEmpty ? '/${uri.host}' : raw);
    
    // Email confirmation (signup)
    if (queryParams['type'] == 'signup') {
      return _material(const EmailConfirmedPage());
    }

    // Password recovery deep link.
    if (queryParams['type'] == 'recovery') {
      return _material(const ResetPasswordPage());
    }

    // Magic-link из старой почты для подтверждения смены email.
    // В некоторых сценариях Supabase не передаёт наш custom path, только type=magiclink.
    // Тогда открываем confirm-экран без параметров: он завершит confirm_latest.
    if (queryParams['type'] == 'magiclink') {
      return _material(
        const EmailChangeConfirmPage(
          requestId: '',
          confirmToken: '',
        ),
      );
    }
    
    // Проверяем, есть ли access_token в пути (альтернативный вариант)
    if (settings.name?.contains('access_token') == true && 
        settings.name?.contains('type=signup') == true) {
      return _material(const EmailConfirmedPage());
    }
    if (settings.name?.contains('access_token') == true &&
        settings.name?.contains('type=recovery') == true) {
      return _material(const ResetPasswordPage());
    }
    
    switch (path) {
      case '/':
        return _material(const SignInPage());
      case '/sign-up':
        return _material(const SignUpPage());
      case '/whatsapp-code':
        return _material(const WhatsAppCodePage());
      case '/phone-sign-in':
        return _material(const PhoneSignInPage(isRegisterMode: false));
      case '/phone-sign-up':
        return _material(const PhoneSignInPage(isRegisterMode: true));
      case '/phone-reset-password':
        return _material(const PhoneSignInPage(isResetMode: true));
      case '/set-password':
        return _material(const SetPasswordPage());
      case '/set-password-reset':
        return _material(
          const SetPasswordPage(
            title: 'Новый пароль',
            description: 'Введите новый пароль для входа по номеру телефона.',
            successRoute: '/',
          ),
        );
      case '/home':
        return _material(const HomePage());
      case '/cars':
        return _material(const CarsListPage());
      case '/profile':
        return _material(const ProfilePage());
      case '/waybill':
        return _material(const WaybillsPage());
      case '/payment-methods':
        return _material(const PaymentMethodPage());
      case '/reset-password':
        return _material(const ResetPasswordPage());
      // Старый экран восстановления по magic-link оставлен для совместимости,
      // но '/forgot-password' ведёт на новый флоу с одноразовым кодом.
      case '/forgot-password':
      case '/password-reset':
        return _material(const PasswordResetEmailPage());
      case '/password-reset-code':
        final codeArgs =
            (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(
          PasswordResetCodePage(
            email: codeArgs['email'] as String? ?? '',
            resetId: codeArgs['reset_id'] as int? ?? 0,
          ),
        );
      case '/password-reset-new':
        final args =
            (settings.arguments as Map<String, dynamic>?) ?? const {};
        return _material(
          PasswordResetNewPasswordPage(
            resetToken: args['reset_token'] as String? ?? '',
          ),
        );
      case '/email-confirmed':
      case '/email-confirm': // Deep link может прийти без '-ed'
        return _material(const EmailConfirmedPage());
      case '/email-link-expired':
        return _material(
          EmailLinkExpiredPage(
            reason: _expiredReasonFromQuery(queryParams),
          ),
        );
      case '/email-change-confirm':
        return _material(
          EmailChangeConfirmPage(
            requestId: queryParams['request_id'] ?? '',
            confirmToken: queryParams['confirm_token'] ?? '',
          ),
        );
      case '/guide':
        return _material(const GuidePage());
      case '/contacts':
        return _material(const ContactsPage());
      case '/promo':
        return _material(const PromoPage());
      case '/admin-promo':
        return _material(const PromoAdminPage());
      case '/admin-stamps':
        return _material(const StampsSettingsPage());
      case '/admin-waybills':
        return _material(const WaybillAdminPanelPage());
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not implemented yet')),
          ),
        );
    }
  }

  static MaterialPageRoute<T> _material<T>(Widget child) {
    return MaterialPageRoute<T>(builder: (_) => child);
  }
}
