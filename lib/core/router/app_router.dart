import 'package:flutter/material.dart';

import '../../features/auth/pages/sign_in_page.dart';
import '../../features/auth/pages/sign_up_page.dart';
import '../../features/auth/pages/whatsapp_code_page.dart';
import '../../features/auth/pages/reset_password_page.dart';
import '../../features/cars/pages/cars_list_page.dart';
import '../../features/home/home_page.dart';
import '../../features/profile/pages/profile_page.dart';
import '../../features/admin/pages/stamps_settings_page.dart';
import '../../features/waybill/pages/waybill_admin_panel_page.dart';
import '../../features/waybill/pages/waybill_page.dart';
import '../../features/payments/pages/payment_method_page.dart';

/// Centralized router configuration. Replace placeholders as routes appear.
class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _material(const SignInPage());
      case '/sign-up':
        return _material(const SignUpPage());
      case '/whatsapp-code':
        return _material(const WhatsAppCodePage());
      case '/home':
        return _material(const HomePage());
      case '/cars':
        return _material(const CarsListPage());
      case '/profile':
        return _material(const ProfilePage());
      case '/waybill':
        return _material(const WaybillPage());
      case '/payment-methods':
        return _material(const PaymentMethodPage());
      case '/reset-password':
        return _material(const ResetPasswordPage());
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
