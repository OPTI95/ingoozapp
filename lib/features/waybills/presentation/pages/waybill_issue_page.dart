import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_back_button.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/waybill_quote.dart';
import '../bloc/waybill_issue_bloc.dart';

/// "Новый путевой лист": choose a vehicle, payment source and mileage,
/// then issue. Pops with the issued [Waybill] on success.
class WaybillIssuePage extends StatelessWidget {
  const WaybillIssuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WaybillIssueBloc>(
      create: (_) => sl<WaybillIssueBloc>()..add(const WaybillIssueStarted()),
      child: const _WaybillIssueView(),
    );
  }
}

class _WaybillIssueView extends StatefulWidget {
  const _WaybillIssueView();

  @override
  State<_WaybillIssueView> createState() => _WaybillIssueViewState();
}

class _WaybillIssueViewState extends State<_WaybillIssueView> {
  final _odometerController = TextEditingController();

  static String _money(double v) => '${v.toStringAsFixed(2)} ₽';

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    // Show the "Предупреждение" confirmation as in the Figma flow.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Предупреждение',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Проверьте правильность введённых данных. После создания путевого '
          'листа изменения могут быть недоступны.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Отмена',
              style: TextStyle(color: AppColors.primaryBlue),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;

    final odometer = int.tryParse(_odometerController.text.trim());
    context.read<WaybillIssueBloc>().add(
          WaybillIssueSubmitted(odometer: odometer),
        );
  }

  Future<void> _showInsufficientFundsDialog(
    BuildContext context, {
    double? cost,
  }) async {
    final need = cost != null
        ? 'Для выпуска путевого листа требуется ${_money(cost)}. '
            'Пополните баланс, чтобы продолжить.'
        : 'Недостаточно средств на балансе. Пополните баланс, чтобы продолжить.';
    final topUp = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Недостаточно средств'),
        content: Text(need),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );
    if (topUp == true && context.mounted) {
      Navigator.of(context).pushNamed('/payment-methods');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Новый путевой лист'),
      ),
      body: BlocConsumer<WaybillIssueBloc, WaybillIssueState>(
        listenWhen: (prev, curr) =>
            curr.status == WaybillIssueStatus.issued ||
            (curr.errorMessage != null &&
                curr.errorMessage != prev.errorMessage) ||
            (curr.insufficientFunds && !prev.insufficientFunds),
        listener: (context, state) {
          if (state.status == WaybillIssueStatus.issued &&
              state.issued != null) {
            Navigator.of(context).pop(state.issued);
          } else if (state.insufficientFunds) {
            _showInsufficientFundsDialog(context, cost: state.quote?.cost);
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == WaybillIssueStatus.loadingVehicles) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == WaybillIssueStatus.failure) {
            return _ErrorView(
              message: state.errorMessage ?? 'Не удалось загрузить данные',
              onRetry: () => context
                  .read<WaybillIssueBloc>()
                  .add(const WaybillIssueStarted()),
            );
          }
          if (state.vehicles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'У вас нет автомобилей. Добавьте авто в разделе '
                  '«Автомобили», чтобы выпустить путевой лист.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _buildForm(context, state);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, WaybillIssueState state) {
    final quote = state.quote;
    return AbsorbPointer(
      absorbing: state.isBusy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Все данные подтягиваются автоматически из профиля и выбранного '
              'авто. Введите только пробег при выезде.',
              style: TextStyle(color: Colors.black87, height: 1.35),
            ),
            const SizedBox(height: 16),

            // Inline summary — exactly as in Figma:
            // "Стоимость: X ₽   Баланс: Y ₽"
            // "Пополнить"
            // "Подарочные листы: N шт."
            _summaryInline(context, quote, state.isQuoting),
            const SizedBox(height: 16),

            // Способ списания block with a single rounded border.
            _paymentSourceBlock(context, state),
            const SizedBox(height: 16),

            // Автомобиль dropdown.
            DropdownButtonFormField<int>(
              initialValue: state.selectedVehicleId,
              decoration: InputDecoration(
                labelText: 'Автомобиль',
                labelStyle: const TextStyle(color: AppColors.textGrey),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
              ),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              items: [
                for (final v in state.vehicles)
                  if (v.id != null)
                    DropdownMenuItem(
                      value: v.id,
                      child: Text('${v.title} (${v.plateNumber})'),
                    ),
              ],
              onChanged: (id) {
                if (id != null) {
                  context
                      .read<WaybillIssueBloc>()
                      .add(WaybillVehicleChanged(id));
                }
              },
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _odometerController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Пробег (одометр при выезде), км',
                labelStyle: const TextStyle(color: AppColors.textGrey),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primaryBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            PrimaryButton(
              label: 'Создать',
              loading: state.isIssuing,
              onPressed: state.canIssue ? () => _submit(context) : null,
              colorText: AppColors.textGrey3,
              color: state.canIssue
                  ? AppColors.fieldFill
                  : AppColors.fieldFill,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryInline(
    BuildContext context,
    WaybillQuote? quote,
    bool isQuoting,
  ) {
    if (quote == null && isQuoting) {
      return const SizedBox(
        height: 24,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DefaultTextStyle.merge(
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          child: Row(
            children: [
              const Text(
                'Стоимость: ',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
              Text(
                quote != null
                    ? '${quote.cost.toStringAsFixed(quote.cost == quote.cost.truncateToDouble() ? 1 : 2)} ₽'
                    : '—',
                style: const TextStyle(color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),
              Text(
                'Баланс: ',
                style: TextStyle(
                  color: (quote?.balance ?? 0) <= 0
                      ? Colors.red
                      : AppColors.primaryBlue,
                ),
              ),
              Text(
                quote != null
                    ? '${quote.balance.toStringAsFixed(2)} ₽'
                    : '—',
                style: TextStyle(
                  color: (quote?.balance ?? 0) <= 0
                      ? Colors.red
                      : AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed('/payment-methods'),
          child: const Text(
            'Пополнить',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Подарочные листы: ${quote?.promoWaybillsLeft ?? 0} шт.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.orange,
          ),
        ),
      ],
    );
  }

  Widget _paymentSourceBlock(BuildContext context, WaybillIssueState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Способ списания',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _paymentRadioRow(
            context: context,
            state: state,
            value: 'promo',
            title: 'Подарочные листы',
            subtitle: state.promoAvailable
                ? 'Доступно ${state.quote?.promoWaybillsLeft ?? 0} шт.'
                : 'Недоступно',
            enabled: state.promoAvailable,
          ),
          _paymentRadioRow(
            context: context,
            state: state,
            value: 'balance',
            title: 'Баланс счёта',
            subtitle: state.balanceAvailable
                ? 'Доступно ${state.quote != null ? _money(state.quote!.balance) : '—'}'
                : 'Недостаточно средств',
            enabled: state.balanceAvailable,
          ),
        ],
      ),
    );
  }

  Widget _paymentRadioRow({
    required BuildContext context,
    required WaybillIssueState state,
    required String value,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final selected = state.paymentSource == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: enabled
          ? () => context
              .read<WaybillIssueBloc>()
              .add(WaybillPaymentSourceChanged(value))
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                      selected ? AppColors.primaryBlue : AppColors.textGrey,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
