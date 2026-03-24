import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ingoozapp/data/repositories/payment_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final _amountController = TextEditingController();
  bool _tinkoffLoading = false;
  static const int _minTopUpAmount = 100;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startTinkoffPayment() async {
    final amount = _parseAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Минимальная сумма пополнения — 100 ₽')),
      );
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Пользователь не найден')));
      return;
    }

    setState(() => _tinkoffLoading = true);
    try {
      // Проверяем, существует ли профиль
      final profile = await client
          .from('profiles')
          .select('user_id, balance')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        // Профиль не заполнен
        setState(() => _tinkoffLoading = false);
        if (!mounted) return;

        _showFillProfileDialog();
        return;
      }

      final response = await client.functions.invoke(
        'tinkoff-init',
        body: {'amount': amount},
      );

      final data = response.data;
      final paymentUrl = data is Map<String, dynamic>
          ? data['paymentUrl'] as String?
          : null;
      final orderId = data is Map<String, dynamic>
          ? data['orderId'] as String?
          : null;

      if (paymentUrl == null) {
        throw Exception('Tinkoff вернул пустой ответ');
      }

      // Регистрируем pending-платёж в нашей БД, чтобы вебхук смог найти его по OrderId.
      if (orderId != null) {
        try {
          final paymentRepository = SupabasePaymentRepository(client);
          await paymentRepository.createPayment(
            amount: amount,
            currency: 'RUB',
            status: 'pending',
            provider: 'tinkoff',
            providerPaymentId: orderId,
          );
        } catch (e) {
          // Не блокируем оплату, просто логируем в UI.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Не удалось сохранить платёж: $e')),
            );
          }
        }
      }

      if (!mounted) return;
      _showTinkoffQrDialog(
        paymentUrl: paymentUrl,
        orderId: orderId ?? '',
        amount: amount,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка запуска оплаты: $e')));
    } finally {
      if (mounted) {
        setState(() => _tinkoffLoading = false);
      }
    }
  }

  int? _parseAmount() {
    final text = _amountController.text.replaceAll(' ', '');
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null || value < _minTopUpAmount) return null;
    return value;
  }

  void _showFillProfileDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Expanded(child: Text('Заполните профиль')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Для пополнения баланса необходимо заполнить профиль.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'Это нужно сделать один раз при первом пополнении.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamed('/profile');
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Перейти в профиль'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTinkoffQrDialog({
    required String paymentUrl,
    required String orderId,
    required int amount,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isChecking = false;
        bool? statusSuccess;
        String? statusMessage;
        bool started = false;
        int remainingSeconds = 120;
        StreamSubscription? realtimeSubscription;
        Timer? countdownTimer;
        Timer? timeoutTimer;

        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            void cleanup() {
              realtimeSubscription?.cancel();
              countdownTimer?.cancel();
              timeoutTimer?.cancel();
            }

            Future<void> checkPaymentStatus() async {
              if (isChecking) return;

              cleanup();

              setStateDialog(() {
                isChecking = true;
                statusSuccess = null;
                statusMessage = 'Ожидаем подтверждения оплаты...';
                remainingSeconds = 120;
              });

              final client = Supabase.instance.client;
              bool completed = false;

              // Таймер обратного отсчёта (визуальный)
              countdownTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (!dialogContext.mounted || completed) {
                  timer.cancel();
                  return;
                }
                setStateDialog(() {
                  remainingSeconds--;
                });
              });

              // Таймаут на 120 секунд
              timeoutTimer = Timer(const Duration(seconds: 120), () async {
                if (completed || !dialogContext.mounted) return;
                completed = true;
                cleanup();

                // Делаем финальный запрос статуса
                try {
                  final row = await client
                      .from('payments')
                      .select('status')
                      .eq('provider', 'tinkoff')
                      .eq('provider_payment_id', orderId)
                      .maybeSingle();

                  final finalStatus = row != null
                      ? row['status'] as String?
                      : null;

                  if (!dialogContext.mounted) return;
                  setStateDialog(() {
                    isChecking = false;
                    statusSuccess = finalStatus == 'succeeded';
                    statusMessage = finalStatus == 'succeeded'
                        ? '✅ Оплата прошла успешно! Баланс обновлён.'
                        : finalStatus == 'failed'
                        ? '❌ Оплата отклонена банком.'
                        : finalStatus == 'canceled'
                        ? '🚫 Оплата отменена.'
                        : '⏱️ Оплата не подтверждена.\nПроверьте позже в истории операций.';
                  });

                  if (finalStatus == 'succeeded') {
                    await Future.delayed(const Duration(seconds: 2));
                    if (!context.mounted) return;
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pop(true);
                  }
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  setStateDialog(() {
                    isChecking = false;
                    statusSuccess = false;
                    statusMessage =
                        '⏱️ Время ожидания истекло.\nПроверьте позже в истории операций.';
                  });
                }
              });

              try {
                // Подписка на изменения в реальном времени
                final stream = client
                    .from('payments')
                    .stream(primaryKey: ['id']);

                realtimeSubscription = stream.listen(
                  (data) async {
                    if (completed || !dialogContext.mounted) return;

                    // Фильтруем на стороне клиента
                    final payment = data
                        .cast<Map<String, dynamic>>()
                        .firstWhere(
                          (row) =>
                              row['provider'] == 'tinkoff' &&
                              row['provider_payment_id'] == orderId,
                          orElse: () => <String, dynamic>{},
                        );

                    if (payment.isEmpty) return;

                    final status = payment['status'] as String?;

                    // Финальные статусы
                    if (status == 'succeeded' ||
                        status == 'failed' ||
                        status == 'canceled') {
                      completed = true;
                      cleanup();

                      if (!dialogContext.mounted) return;
                      setStateDialog(() {
                        isChecking = false;
                        statusSuccess = status == 'succeeded';
                        statusMessage = status == 'succeeded'
                            ? '✅ Оплата прошла успешно! Баланс обновлён.'
                            : status == 'failed'
                            ? '❌ Оплата отклонена банком.'
                            : '🚫 Оплата отменена.';
                      });

                      if (status == 'succeeded') {
                        await Future.delayed(const Duration(seconds: 2));
                        if (!context.mounted) return;
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop(true);
                      }
                    }
                  },
                  onError: (error) {
                    if (completed || !dialogContext.mounted) return;
                    completed = true;
                    cleanup();

                    setStateDialog(() {
                      isChecking = false;
                      statusSuccess = false;
                      statusMessage = 'Ошибка подключения: $error';
                    });
                  },
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                completed = true;
                cleanup();

                setStateDialog(() {
                  isChecking = false;
                  statusSuccess = false;
                  statusMessage = 'Ошибка при проверке: $e';
                });
              }
            }

            // Стартуем авто‑проверку один раз
            if (!started) {
              started = true;
              checkPaymentStatus();
            }

            Future<void> openPaymentLink() async {
              final uri = Uri.tryParse(paymentUrl);
              if (uri == null) return;
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }

            return WillPopScope(
              onWillPop: () async {
                cleanup();
                return true;
              },
              child: AlertDialog(
                title: Row(
                  children: [
                    const Icon(Icons.payment, color: Colors.orange),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('Оплата вне приложения')),
                    IconButton(
                      onPressed: () {
                        cleanup();
                        Navigator.of(dialogContext).pop();
                        Navigator.of(context).pop(false);
                      },
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                      tooltip: 'Закрыть',
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Сумма: $amount ₽',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                            ),
                            if (orderId.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Заказ: $orderId',
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: openPaymentLink,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Открыть страницу оплаты'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Оплата откроется в браузере этого устройства',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isChecking
                              ? Colors.blue.shade50
                              : statusSuccess == true
                              ? Colors.green.shade50
                              : statusSuccess == false
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isChecking
                                ? Colors.blue
                                : statusSuccess == true
                                ? Colors.green
                                : statusSuccess == false
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isChecking) ...[
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ] else if (statusSuccess != null) ...[
                                  Icon(
                                    statusSuccess == true
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: statusSuccess == true
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Flexible(
                                  child: Text(
                                    statusMessage ?? 'Ожидаем подтверждения...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w500),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            if (isChecking) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Осталось ~$remainingSeconds сек',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  if (!isChecking && statusSuccess == false)
                    ElevatedButton.icon(
                      onPressed: checkPaymentStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Проверить ещё раз'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: paymentUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Ссылка скопирована'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Скопировать'),
                  ),
                  TextButton(
                    onPressed: isChecking
                        ? null
                        : () {
                            cleanup();
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop(false);
                          },
                    child: Text(
                      isChecking ? 'Проверяем...' : 'Закрыть',
                      style: TextStyle(color: isChecking ? Colors.grey : null),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пополнение баланса')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Сумма пополнения'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Минимум 100 ₽',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Способ оплаты'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payments),
                title: const Text('Оплата картой (Тинькофф)'),
                subtitle: const Text('Переход по ссылке в браузер'),
                trailing: _tinkoffLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: _tinkoffLoading ? null : _startTinkoffPayment,
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
