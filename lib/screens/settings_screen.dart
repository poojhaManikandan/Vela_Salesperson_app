import 'package:flutter/material.dart';
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
  bool _darkMode = false;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    final body = _buildBody(context);

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(child: body),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (widget.embedded) ...[
          const Text(
            'Settings',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    'R',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ramalingam',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      SizedBox(height: 3),
                      Text('EMP1024 · Store Cashier',
                          style: TextStyle(
                              fontSize: 12.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryBlue),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _SettingsSectionLabel('Preferences'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.print_outlined,
                title: 'Printer Settings',
                subtitle: 'Manage connected printers',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrinterScreen()),
                  );
                },
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Theme',
                subtitle: 'Switch between light and dark mode',
                trailing: Switch(
                  value: _darkMode,
                  activeThumbColor: AppTheme.primaryBlue,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Low stock and order alerts',
                trailing: Switch(
                  value: _notifications,
                  activeThumbColor: AppTheme.primaryBlue,
                  onChanged: (v) => setState(() => _notifications = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SettingsSectionLabel('Account'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'About Velan',
                subtitle: 'Version 1.0.0',
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: AppTheme.dangerRed,
            title: 'Logout',
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textMuted,
          letterSpacing: 0.4,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryBlue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? AppTheme.primaryBlue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: titleColor ?? AppTheme.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted))
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted)
              : null),
    );
  }
}
