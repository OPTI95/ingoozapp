import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ingoozapp/core/di/injection.dart';
import 'package:ingoozapp/core/widgets/app_back_button.dart';
import 'package:ingoozapp/core/widgets/primary_button.dart';

import '../domain/entities/promo_redemption.dart';
import '../presentation/bloc/promo_bloc.dart';

class PromoPage extends StatelessWidget {
  const PromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PromoBloc>(
      create: (_) => sl<PromoBloc>()..add(const PromoStarted()),
      child: const _PromoView(),
    );
  }
}

class _PromoView extends StatefulWidget {
  const _PromoView();

  @override
  State<_PromoView> createState() => _PromoViewState();
}

class _PromoViewState extends State<_PromoView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите промокод')),
      );
      return;
    }
    context.read<PromoBloc>().add(PromoApplied(code));
  }

  void _onState(BuildContext context, PromoState state) {
    if (state.apply == PromoApplyStatus.success) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Промокод успешно активирован')),
      );
    } else if (state.apply == PromoApplyStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? 'Не удалось активировать')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Промокоды'),
      ),
      body: BlocConsumer<PromoBloc, PromoState>(
        listener: _onState,
        builder: (context, state) {
          if (state.status == PromoStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PromoStatus.failure) {
            return _ErrorView(
              message: state.errorMessage ?? 'Не удалось загрузить промокоды',
              onRetry: () =>
                  context.read<PromoBloc>().add(const PromoStarted()),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<PromoBloc>().add(const PromoStarted()),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCreditsCard(state.credits),
                const SizedBox(height: 16),
                _buildInputCard(state.isApplying),
                const SizedBox(height: 16),
                _buildHistoryCard(state.redemptions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditsCard(int credits) {
    return Card(
      elevation: Platform.isIOS ? 0 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Подарочные путевые листы',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$credits шт.',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Они списываются автоматически перед списанием денег с баланса.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(bool applying) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Активировать промокод',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Введите код'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Активировать',
              loading: applying,
              onPressed: _apply,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(List<PromoRedemption> redemptions) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История активаций',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (redemptions.isEmpty)
              const Text(
                'Вы ещё не активировали промокоды.',
                style: TextStyle(color: Colors.black54),
              )
            else
              ...redemptions.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.code),
                  subtitle: Text(
                    'Подарено: ${item.waybillQuota} лист.\n'
                    '${_formatDate(item.redeemedAt)}',
                  ),
                  leading: SvgPicture.asset(
                    'assets/svg/ic-gift.svg',
                    width: 26,
                    height: 26,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
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
