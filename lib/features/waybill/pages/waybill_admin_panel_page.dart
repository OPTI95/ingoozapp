import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/waybill_model.dart';
import 'waybill_pdf_preview_page.dart';

class WaybillAdminPanelPage extends StatefulWidget {
  const WaybillAdminPanelPage({super.key});

  @override
  State<WaybillAdminPanelPage> createState() => _WaybillAdminPanelPageState();
}

class _WaybillAdminPanelPageState extends State<WaybillAdminPanelPage> {
  final _numberController = TextEditingController();
  bool _loading = true;
  bool _lookupLoading = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final client = Supabase.instance.client;
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _loading = false;
          _isAdmin = false;
        });
        return;
      }
      final profile = await client
          .from('profiles')
          .select('is_admin')
          .eq('user_id', userId)
          .maybeSingle();
      final isAdmin = (profile?['is_admin'] as bool?) ?? false;
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAdmin = false;
      });
    }
  }

  Future<void> _openExistingByNumber() async {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите номер путевого листа')), 
      );
      return;
    }

    setState(() => _lookupLoading = true);

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('waybills')
          .select()
          .eq('number', number)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Путевой лист №$number не найден')), 
        );
        return;
      }

      final waybill = WaybillModel.fromMap(response as Map<String, dynamic>);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaybillPdfPreviewPage(waybill: waybill),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при поиске: $e')), 
      );
    } finally {
      if (mounted) {
        setState(() => _lookupLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ панель ПЛ')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Админ панель ПЛ')),
        body: const Center(
          child: Text('Доступ запрещён'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Админ панель ПЛ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Введите номер путевого листа, чтобы открыть PDF.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Номер путевого листа',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _lookupLoading ? null : _openExistingByNumber,
                child: _lookupLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Открыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
