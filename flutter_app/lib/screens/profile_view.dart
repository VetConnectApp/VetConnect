import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final _fs = FirestoreService();
  bool _editing = false;
  bool _saving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  // Vet fields
  late TextEditingController _licenseCtrl;
  late TextEditingController _clinicCtrl;
  // Farmer fields
  late TextEditingController _villageCtrl;
  late TextEditingController _landCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppAuthProvider>().userProfile;
    _nameCtrl = TextEditingController(text: user?.displayName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _licenseCtrl = TextEditingController(text: user?.licenseNumber ?? '');
    _clinicCtrl = TextEditingController(text: user?.clinicName ?? '');
    _villageCtrl = TextEditingController(text: user?.village ?? '');
    _landCtrl =
        TextEditingController(text: user?.landHoldings?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenseCtrl.dispose();
    _clinicCtrl.dispose();
    _villageCtrl.dispose();
    _landCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';
    final role = auth.role;

    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'displayName': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    };

    if (role == 'vet') {
      updates['licenseNumber'] = _licenseCtrl.text.trim();
      updates['clinicName'] = _clinicCtrl.text.trim();
    } else if (role == 'farmer') {
      updates['village'] = _villageCtrl.text.trim();
      if (_landCtrl.text.isNotEmpty) {
        updates['landHoldings'] = double.tryParse(_landCtrl.text) ?? 0.0;
      }
    }

    await _fs.updateUserFields(uid, updates);
    await auth.refreshUserProfile();

    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile updated!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final t = context.watch<ThemeProvider>().t;
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.userProfile;
    final role = auth.role;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('profile')),
        actions: [
          if (!_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: Text(t('edit')),
            )
          else
            TextButton(
              onPressed: () => setState(() => _editing = false),
              child: Text(t('cancel')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar & Identity ──────────────────────────────────────
            _buildAvatar(context, user, role),
            const SizedBox(height: 24),

            // ── Personal Info Card ─────────────────────────────────────
            _buildSection(
              context,
              title: t('personal_info'),
              icon: Icons.person_outline_rounded,
              children: [
                _buildField(context, t('full_name'), _nameCtrl,
                    Icons.badge_outlined, _editing),
                const SizedBox(height: 12),
                _buildField(context, t('phone'), _phoneCtrl,
                    Icons.phone_outlined, _editing,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _readonlyField(context, t('email'), user?.email ?? '',
                    Icons.email_outlined),
                const SizedBox(height: 12),
                _readonlyField(
                    context,
                    t('role'),
                    '${user?.roleEmoji ?? ''} ${role[0].toUpperCase()}${role.substring(1)}',
                    Icons.work_outline_rounded),
              ],
            ),
            const SizedBox(height: 16),

            // ── Role-specific Fields ───────────────────────────────────
            if (role == 'vet')
              _buildSection(
                context,
                title: '🩺 Veterinarian Details',
                icon: Icons.medical_services_outlined,
                children: [
                  _buildField(context, 'License Number', _licenseCtrl,
                      Icons.card_membership_outlined, _editing),
                  const SizedBox(height: 12),
                  _buildField(context, 'Clinic / Practice Name', _clinicCtrl,
                      Icons.local_hospital_outlined, _editing),
                ],
              )
            else if (role == 'farmer')
              _buildSection(
                context,
                title: '🚜 Farmer Details',
                icon: Icons.agriculture_outlined,
                children: [
                  _buildField(context, 'Village', _villageCtrl,
                      Icons.location_on_outlined, _editing),
                  const SizedBox(height: 12),
                  _buildField(context, 'Land Holdings (acres)', _landCtrl,
                      Icons.landscape_outlined, _editing,
                      type: TextInputType.number),
                ],
              ),

            const SizedBox(height: 16),

            // ── Preferences ────────────────────────────────────────────
            _buildSection(
              context,
              title: t('preferences'),
              icon: Icons.settings_outlined,
              children: [
                // Dark mode toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 18,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t('dark_mode'),
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    Switch.adaptive(
                      value: isDark,
                      activeColor: cs.primary,
                      onChanged: (v) => themeProvider.toggleTheme(),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Language picker
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.language_rounded,
                          size: 18, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t('language'),
                          style: Theme.of(context).textTheme.bodyLarge),
                    ),
                    DropdownButton<String>(
                      value: themeProvider.locale,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hi', child: Text('हिंदी')),
                        DropdownMenuItem(value: 'gu', child: Text('ગુજરાતી')),
                      ],
                      onChanged: (v) => themeProvider.setLocale(v ?? 'en'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Save Button ────────────────────────────────────────────
            if (_editing) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  child: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(t('save_changes')),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Sign Out ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmSignOut(context, auth, t),
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: AppTheme.errorRed),
                label: Text(t('sign_out'),
                    style: const TextStyle(color: AppTheme.errorRed)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // ── App version ────────────────────────────────────────────
            Center(
              child: Text(
                'VetConnect v1.0.0 • Build 2025',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.3),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, UserModel? user, String role) {
    final initials = user?.initials ?? 'U';
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Role emoji badge
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    user?.roleEmoji ?? '👤',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: cs.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: cs.primary,
                      )),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(
    BuildContext context,
    String label,
    TextEditingController ctrl,
    IconData icon,
    bool enabled, {
    TextInputType type = TextInputType.text,
  }) {
    final cs = Theme.of(context).colorScheme;
    if (!enabled) {
      return _readonlyField(context, label, ctrl.text, icon);
    }
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _readonlyField(
      BuildContext context, String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.4)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.45),
                    )),
            Text(value.isNotEmpty ? value : '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
          ],
        ),
      ],
    );
  }

  void _confirmSignOut(
      BuildContext context, AppAuthProvider auth, String Function(String) t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              auth.signOut();
            },
            child: Text(t('sign_out')),
          ),
        ],
      ),
    );
  }
}
