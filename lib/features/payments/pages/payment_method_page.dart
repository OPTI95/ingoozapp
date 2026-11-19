import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../billing/domain/entities/payment.dart';
import '../../billing/presentation/bloc/top_up_bloc.dart';

class PaymentMethodPage extends StatelessWidget {
  const PaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TopUpBloc>(
      create: (_) => sl<TopUpBloc>()..add(const TopUpStarted()),
      child: const _PaymentMethodView(),
    );
  }
}

class _PaymentMethodView extends StatefulWidget {
  const _PaymentMethodView();

  @override
  State<_PaymentMethodView> createState() => _PaymentMethodViewState();
}

class _PaymentMethodViewState extends State<_PaymentMethodView> {
  static const int _minTopUpAmount = 100;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _parseAmount() {
    final text = _amountController.text.replaceAll(' ', '');
    final value = int.tryParse(text);
    if (value == null || value < _minTopUpAmount) return null;
    return value;
  }

  void _submit() {
    final amount = _parseAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Минимальная сумма пополнения — 100 ₽')),
      );
      return;
    }
    context.read<TopUpBloc>().add(TopUpSubmitted(amount));
  }

  void _onState(BuildContext context, TopUpState state) {
    if (state.status == TopUpStatus.created && state.payment != null) {
      _showPaymentDialog(context, state.payment!);
    } else if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  Future<void> _showPaymentDialog(BuildContext context, Payment payment) async {
    final url = payment.paymentUrl;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Банк не вернул ссылку на оплату')),
      );
      return;
    }

    // Try to open immediately for convenience.
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Оплата'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма: ${payment.amount.toStringAsFixed(0)} ₽'),
            const SizedBox(height: 12),
            const Text(
              'Страница оплаты открыта в браузере. После оплаты баланс '
              'обновится автоматически в течение нескольких минут.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ссылка скопирована')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Скопировать'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Открыть оплату'),
          ),
        ],
      ),
    );
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Пополнение баланса'),
      ),
      body: SafeArea(
        child: BlocConsumer<TopUpBloc, TopUpState>(
          listener: _onState,
          builder: (context, state) {
            if (state.status == TopUpStatus.loadingBalance) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Сумма пополнения',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Минимум 100 ₽',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.inputBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Способ оплаты',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    color: AppColors.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.fieldFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/svg/ic-money.svg',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ),
                      title: const Text(
                        'Оплата картой (Тинькофф)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Переход по ссылке в браузер'),
                      trailing: state.isCreating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.chevron_right),
                      onTap: state.isCreating ? null : _submit,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
