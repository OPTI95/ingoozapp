import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ingoozapp/data/repositories/payment_repository.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _parseAmount() {
    final text = _amountController.text.replaceAll(' ', '');
    if (text.isEmpty) return null;
    final value = int.tryParse(text);
    if (value == null || value <= 0) return null;
    return value;
  }

  Future<void> _fakeStripePayment() async {
    final amount = _parseAmount();
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную сумму')),
      );
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не найден')),
      );
      return;
    }

    final rootContext = context;

    showDialog<void>(
      context: rootContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Тестовый платеж'),
          content: Text('Симулируем оплату Stripe на $amount ₽.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();

                try {
                  final profile = await client
                      .from('profiles')
                      .select('balance')
                      .eq('user_id', user.id)
                      .maybeSingle();

                  if (profile == null) {
                    await client.from('profiles').insert({
                      'user_id': user.id,
                      'balance': amount,
                    });
                  } else {
                    final currentBalance =
                        (profile['balance'] as num? ?? 0);
                    final newBalance = currentBalance + amount;

                    await client
                        .from('profiles')
                        .update({'balance': newBalance})
                        .eq('user_id', user.id);
                  }

                    // Log payment in payments table
                  final paymentRepository = SupabasePaymentRepository(client);
                  await paymentRepository.createPayment(
                    amount: amount,
                    currency: 'RUB',
                    status: 'succeeded',
                    provider: 'stripe_test',
                    providerPaymentId: null,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(
                        content: Text('Оплата (тест) прошла успешно')),
                  );
                  Navigator.of(rootContext).pop(true);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text('Ошибка при обновлении баланса: $e')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Пополнение баланса')), 
      body: Padding(
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
                hintText: 'Например, 500',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Способ оплаты'),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance),
                title: const Text('Stripe / карта (тест)'),
                subtitle: const Text('Симуляция оплаты Stripe'),
                onTap: _fakeStripePayment,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('Другая карта'),
                subtitle: const Text('Заглушка для других сервисов оплаты'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пока недоступно')), 
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
