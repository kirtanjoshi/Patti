import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void showMarriageLeaveDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('marriage.leave'.tr()),
      content: Text('marriage.leave_confirm'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('marriage.stay'.tr()),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.pop(context);
          },
          child: Text('marriage.leave'.tr()),
        ),
      ],
    ),
  );
}

void showMarriageRulesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('marriage.game_rules'.tr()),
      content: Text('marriage.rules_summary'.tr()),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('actions.confirm'.tr()),
        ),
      ],
    ),
  );
}

void showMarriageDeclareDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('marriage.declare'.tr()),
      content: Text('marriage.finish_success'.tr()),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('actions.confirm'.tr()),
        ),
      ],
    ),
  );
}
