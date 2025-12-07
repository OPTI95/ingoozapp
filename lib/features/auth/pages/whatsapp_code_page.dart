import 'package:flutter/material.dart';

class WhatsAppCodePage extends StatelessWidget {
  const WhatsAppCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение WhatsApp')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('TODO: отправка кода в WhatsApp и ввод OTP'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}
