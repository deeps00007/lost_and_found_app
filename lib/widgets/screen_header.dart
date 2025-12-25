import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? action;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const ScreenHeader({
    Key? key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.action,
    this.showBackButton = false,
    this.onBackPressed,
  })  : assert(title != null || titleWidget != null,
            'Either title or titleWidget must be provided'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBackButton) ...[
              GestureDetector(
                onTap: onBackPressed ?? () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (titleWidget != null)
                    titleWidget!
                  else
                    Text(
                      title!,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
