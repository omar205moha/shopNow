import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shop_now_mobile/const/app_colors.dart';
import 'package:shop_now_mobile/const/app_components.dart';

class AlertDialogWidget extends StatelessWidget {
  final List<Widget>? actionWidgets;
  final Widget? contentWidget;
  final Widget? titleWidget;
  final Color? backgroundColor;
  const AlertDialogWidget({
    super.key,
    this.actionWidgets,
    this.contentWidget,
    this.titleWidget,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      titlePadding: AppComponents.dialogTitlePadding,
      contentPadding: AppComponents.dialogContentPadding,
      shape: const RoundedRectangleBorder(
          borderRadius: AppComponents.dialogBorderRadius),
      title: titleWidget,
      content: contentWidget,
      actions: actionWidgets,
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: AppComponents.dialogActionPadding,
      buttonPadding: EdgeInsets.zero,
    );
  }
}

/// Custom TextButton stretches the width of the screen with small elevation
/// shadow
class CustomStretchedTextButtonWidget extends StatelessWidget {
  final String buttonText;
  final bool isLoading;
  final void Function()? onTap;
  const CustomStretchedTextButtonWidget({
    super.key,
    this.onTap,
    required this.buttonText,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return LoadingStretchedTextButtonWidget(buttonText: buttonText);
    }
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                // color: AppColors.primaryColor.withOpacity(0.5),
                gradient: onTap == null
                    ? LinearGradient(colors: [
                        AppColors.primaryMaterialColor.withOpacity(0.5),
                        AppColors.primaryMaterialColor.withOpacity(0.5)
                      ])
                    : LinearGradient(colors: [
                        AppColors.primaryMaterialColor,
                        AppColors.primaryMaterialColor.withOpacity(0.1),
                      ])),
            child: TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    elevation: onTap == null ? 0 : 10,
                    shadowColor:
                        AppColors.primaryMaterialColor.withOpacity(0.25),
                    // backgroundColor: onTap == null
                    //     ? AppColors.primaryColor.withOpacity(0.15)
                    //     : AppColors.primaryColor.withOpacity(0.0),
                    minimumSize: const Size(30, 62),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            AppComponents.defaultBorderRadius))),
                child: Text(buttonText,
                    textAlign: TextAlign.center,
                    style: onTap == null
                        ? const TextStyle(color: Colors.black54)
                        : null)),
          ),
        ),
      ],
    );
  }
}

/// Custom TextButton stretches the width of the screen with small elevation
/// shadow
class LoadingStretchedTextButtonWidget extends StatelessWidget {
  final String buttonText;
  const LoadingStretchedTextButtonWidget({
    super.key,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingPlaceholderWidget(
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  // color: AppColors.primaryColor.withOpacity(0.5),
                  gradient: LinearGradient(colors: [
                    AppColors.primaryMaterialColor.withOpacity(0.5),
                    AppColors.primaryMaterialColor.withOpacity(0.5)
                  ])),
              child: TextButton(
                  onPressed: null,
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor:
                          AppColors.primaryMaterialColor.withOpacity(0.25),
                      // backgroundColor: onTap == null
                      //     ? AppColors.primaryColor.withOpacity(0.15)
                      //     : AppColors.primaryColor.withOpacity(0.0),
                      minimumSize: const Size(30, 62),
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                              AppComponents.defaultBorderRadius))),
                  child: Text(buttonText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingPlaceholderWidget extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  const LoadingPlaceholderWidget({
    super.key,
    required this.child,
    this.baseColor = AppColors.shimmerBaseColor,
    this.highlightColor = AppColors.shimmerHighlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
        baseColor: baseColor, highlightColor: highlightColor, child: child);
  }
}
