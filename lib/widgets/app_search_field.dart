import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Rounded search bar reused on Home and Bill History screens.
class AppSearchField extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AppSearchField({
    super.key,
    this.hintText = 'Search',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppTheme.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
