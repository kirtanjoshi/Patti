import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class KittiDialogs {
  static void showRules(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('kitti.rules_title'.tr()),
        content: Text('kitti.rules_summary'.tr()),
        actions: [
          Semantics(
            button: true,
            label: 'actions.confirm'.tr(),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('actions.confirm'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  static void showFoldConfirm(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('kitti.fold'.tr()),
        content: Text('kitti.fold_confirm'.tr()),
        actions: [
          Semantics(
            button: true,
            label: 'actions.cancel'.tr(),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('actions.cancel'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'kitti.fold'.tr(),
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: Text('kitti.fold'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  static void showLeaveConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('actions.leave'.tr()),
        content: Text('callbreak.leave_confirm'.tr()),
        actions: [
          Semantics(
            button: true,
            label: 'callbreak.stay'.tr(),
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('callbreak.stay'.tr()),
            ),
          ),
          Semantics(
            button: true,
            label: 'actions.leave'.tr(),
            child: FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: Text('actions.leave'.tr()),
            ),
          ),
        ],
      ),
    );
  }
}
