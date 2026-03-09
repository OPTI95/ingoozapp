import 'dart:io' show Platform;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showPlatformDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  if (Platform.isIOS) {
    DateTime? selected = initialDate;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: firstDate,
                maximumDate: lastDate,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
            CupertinoButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
}

Future<TimeOfDay?> showPlatformTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  if (Platform.isIOS) {
    TimeOfDay selected = initialTime;
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(ctx),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(0, 0, 0, initialTime.hour, initialTime.minute),
                use24hFormat: true,
                onDateTimeChanged: (value) {
                  selected = TimeOfDay(hour: value.hour, minute: value.minute);
                },
              ),
            ),
            CupertinoButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Готово'),
            ),
          ],
        ),
      ),
    );
    return selected;
  }

  return showTimePicker(
    context: context,
    initialTime: initialTime,
  );
}
