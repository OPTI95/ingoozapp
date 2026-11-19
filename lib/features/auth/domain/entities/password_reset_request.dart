import 'package:equatable/equatable.dart';

/// Ответ шага «запросить код восстановления».
///
/// Backend не раскрывает, зарегистрирован ли email: для неизвестного адреса он
/// отвечает 200 с нейтральным [detail] и без [resetId]. Продолжить флоу можно
/// только когда [resetId] пришёл.
class PasswordResetRequest extends Equatable {
  const PasswordResetRequest({this.resetId, this.detail});

  final int? resetId;
  final String? detail;

  bool get codeSent => resetId != null;

  @override
  List<Object?> get props => [resetId, detail];
}
