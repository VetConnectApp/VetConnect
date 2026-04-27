import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phonePwCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  bool _obscureEmail = true;
  bool _obscurePhone = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _phoneCtrl.dispose();
    _phonePwCtrl.dispose();
    super.dispose();
  }

  Future<void> _signInEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AppAuthProvider>();
    await auth.signInWithEmail(_emailCtrl.text.trim(), _pwCtrl.text);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _signInPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = context.read<AppAuthProvider>();
    await auth.signInWithPhone(_phoneCtrl.text.trim(), _phonePwCtrl.text);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final error = context.watch<AppAuthProvider>().errorMessage;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 56),
              // ── Logo ──────────────────────────────────
              _buildLogo(context),
              const SizedBox(height: 36),
              // ── Card ──────────────────────────────────
              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Tabs
                    TabBar(
                      controller: _tabController,
                      dividerColor: Colors.transparent,
                      indicator: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.primaryLight],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: cs.onSurface.withOpacity(0.5),
                      labelStyle: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      tabs: [
                        Tab(text: t('email_tab')),
                        Tab(text: t('phone_tab')),
                      ],
                    ),
                    // Tab views
                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildEmailForm(context, t),
                          _buildPhoneForm(context, t),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // ── Error ─────────────────────────────────
              if (error != null && error.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppTheme.errorRed, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error,
                          style: const TextStyle(
                              color: AppTheme.errorRed, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              // ── Test credentials hint ─────────────────
              _buildHintCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.local_hospital_rounded,
              color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'VetConnect',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          context.read<ThemeProvider>().t('rural_mgmt'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      ],
    );
  }

  Widget _buildEmailForm(BuildContext context, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _emailFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: t('email'),
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
              ),
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Enter a valid email'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _pwCtrl,
              obscureText: _obscureEmail,
              decoration: InputDecoration(
                hintText: t('password'),
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureEmail
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureEmail = !_obscureEmail),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Password too short' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInEmail,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(t('sign_in')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneForm(BuildContext context, String Function(String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Form(
        key: _phoneFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: t('phone'),
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter phone number' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phonePwCtrl,
              obscureText: _obscurePhone,
              decoration: InputDecoration(
                hintText: t('password'),
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePhone
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePhone = !_obscurePhone),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Password too short' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInPhone,
                child: _isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(t('sign_in')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Test Credentials',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _credRow(context, '🩺 Vet', 'vet@vetconnect.com / vet123'),
          _credRow(context, '🚜 Farmer', 'farmer@vetconnect.com / farmer123'),
          _credRow(context, '🛡️ Admin', 'admin@vetconnect.com / admin123'),
        ],
      ),
    );
  }

  Widget _credRow(BuildContext context, String role, String cred) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text(role,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Text(cred,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.5),
                    fontFamily: 'monospace',
                  )),
        ],
      ),
    );
  }
}
