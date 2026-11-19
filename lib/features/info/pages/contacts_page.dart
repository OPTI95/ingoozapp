import 'package:flutter/material.dart';

import '../../../core/widgets/app_back_button.dart';

class ContactItem {
  const ContactItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;
}

class ContactSection {
  const ContactSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<ContactItem> items;
}

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  static const List<ContactSection> _sections = [
    ContactSection(
      title: 'Поддержка',
      items: [
        ContactItem(
          title: 'Почта поддержки',
          value: 'support_ingooz@ro.ru',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Контакты'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, sectionIndex) {
          final section = _sections[sectionIndex];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...section.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            item.value,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
