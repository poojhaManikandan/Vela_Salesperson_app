import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cart_store.dart';
import '../data/theme_controller.dart';
import '../services/translation_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'printer_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool embedded;

  const SettingsScreen({super.key, this.embedded = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _notificationsKey = 'velan_notifications_enabled';

  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) {
        setState(() {
          _notifications = prefs.getBool(_notificationsKey) ?? true;
        });
      }
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Notifications enabled for this device.'
              : 'Notifications disabled for this device.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'.tr),
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (widget.embedded) ...[
          const SizedBox(height: 8),
        ],

        // User Profile Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    CartStore.activeEmployee.isNotEmpty
                        ? CartStore.activeEmployee[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CartStore.activeEmployee,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Store Cashier'.tr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        _SettingsSectionLabel('PREFERENCES'.tr),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.print_outlined,
                title: 'Printer Settings'.tr,
                subtitle: 'Manage connected printer'.tr,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrinterScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              ValueListenableBuilder<bool>(
                valueListenable: ThemeController.instance,
                builder: (context, dark, _) => _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Theme'.tr,
                  subtitle: dark ? 'Dark mode is ON'.tr : 'Switch light / dark mode'.tr,
                  trailing: Switch(
                    value: dark,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => ThemeController.instance.setDark(v),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56),
              ValueListenableBuilder<bool>(
                valueListenable: TranslationService.isTamil,
                builder: (context, isTamil, _) => _SettingsTile(
                  icon: Icons.language_outlined,
                  title: 'Language'.tr,
                  subtitle: isTamil ? 'Tamil Enabled'.tr : 'Switch to Tamil or English'.tr,
                  trailing: Switch(
                    value: isTamil,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (v) => TranslationService.toggleLanguage(v),
                  ),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications'.tr,
                subtitle: 'Order alerts and reminders'.tr,
                trailing: Switch(
                  value: _notifications,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: _toggleNotifications,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _SettingsSectionLabel('APP INFO'.tr),
        const SizedBox(height: 8),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: _SettingsTile(
            icon: Icons.info_outline,
            title: 'About Velan'.tr,
            subtitle: 'Version 1.0.0'.tr,
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Velan Billing',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.shopping_bag_rounded,
                  size: 32,
                  color: AppTheme.primaryGreen,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppTheme.dangerRed,
            title: 'Logout'.tr,
            titleColor: AppTheme.dangerRed,
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionLabel extends StatelessWidget {
  final String label;
  const _SettingsSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryGreen).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppTheme.primaryGreen),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor ?? context.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted)
              : null),
    );
  }
}
