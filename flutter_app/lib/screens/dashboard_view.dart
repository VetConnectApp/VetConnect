import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/animal_model.dart';
import '../models/treatment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/treatment_list_item.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final _fs = FirestoreService();
  int _totalTreatments = 0;
  int _pendingCount = 0;
  int _animalCount = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AppAuthProvider>();
    final uid = auth.firebaseUser?.uid ?? '';
    final role = auth.role;
    try {
      if (role == 'vet') {
        final total = await _fs.countVetTreatments(uid);
        final pending = await _fs.countPendingTreatments();
        final animals = await _fs.countAnimals();
        if (mounted) {
          setState(() {
            _totalTreatments = total;
            _pendingCount = pending;
            _animalCount = animals;
            _statsLoading = false;
          });
        }
      } else if (role == 'farmer') {
        final animals = await _fs.countFarmerAnimals(uid);
        final pending = await _fs.countPendingTreatments();
        if (mounted) {
          setState(() {
            _animalCount = animals;
            _pendingCount = pending;
            _statsLoading = false;
          });
        }
      } else {
        final pending = await _fs.countPendingTreatments();
        final total = await _fs.countAnimals();
        if (mounted) {
          setState(() {
            _pendingCount = pending;
            _animalCount = total;
            _statsLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final t = context.watch<ThemeProvider>().t;
    final role = auth.role;
    final user = auth.userProfile;

    String dashTitle;
    switch (role) {
      case 'vet':
        dashTitle = t('vet_dashboard');
        break;
      case 'admin':
        dashTitle = t('admin_dashboard');
        break;
      default:
        dashTitle = t('farmer_dashboard');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(dashTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _AvatarButton(user: user, role: role),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: Theme.of(context).colorScheme.primary,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _buildGreeting(context, user?.displayName ?? '', role),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              sliver: SliverToBoxAdapter(
                child: _statsLoading
                    ? _buildStatsShimmer(context)
                    : _buildStats(context, role, t),
              ),
            ),
            if (role == 'vet')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: _VetTreatmentList(fs: _fs),
              )
            else if (role == 'farmer')
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: _FarmerHerdView(fs: _fs),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                sliver: _AdminOverview(fs: _fs),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, String name, String role) {
    final greeting = _getGreeting();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${name.isNotEmpty ? name.split(' ').first : 'Welcome'}! ${_roleEmoji(role)}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Here\'s your overview for today',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _roleEmoji(String role) {
    switch (role) {
      case 'vet':
        return '🩺';
      case 'admin':
        return '🛡️';
      default:
        return '🚜';
    }
  }

  Widget _buildStats(
      BuildContext context, String role, String Function(String) t) {
    if (role == 'vet') {
      return GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            label: t('total_treatments'),
            value: '$_totalTreatments',
            icon: Icons.medical_services_rounded,
            iconColor: AppTheme.primary,
          ),
          StatCard(
            label: t('pending'),
            value: '$_pendingCount',
            icon: Icons.pending_actions_rounded,
            iconColor: AppTheme.warningOrange,
            iconBackground: AppTheme.warningOrange.withOpacity(0.12),
          ),
          StatCard(
            label: 'Animals',
            value: '$_animalCount',
            icon: Icons.pets_rounded,
            iconColor: AppTheme.accent,
            iconBackground: AppTheme.accent.withOpacity(0.12),
          ),
        ],
      );
    } else if (role == 'farmer') {
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            label: t('my_herd'),
            value: '$_animalCount',
            icon: Icons.pets_rounded,
          ),
          StatCard(
            label: t('pending'),
            value: '$_pendingCount',
            icon: Icons.pending_actions_rounded,
            iconColor: AppTheme.warningOrange,
            iconBackground: AppTheme.warningOrange.withOpacity(0.12),
          ),
        ],
      );
    } else {
      // Admin
      return GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            label: 'Animals Registered',
            value: '$_animalCount',
            icon: Icons.pets_rounded,
          ),
          StatCard(
            label: 'Pending Review',
            value: '$_pendingCount',
            icon: Icons.pending_actions_rounded,
            iconColor: AppTheme.warningOrange,
            iconBackground: AppTheme.warningOrange.withOpacity(0.12),
          ),
        ],
      );
    }
  }

  Widget _buildStatsShimmer(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Container(
            height: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar Button ───────────────────────────────────────────────────────────

class _AvatarButton extends StatelessWidget {
  final dynamic user;
  final String role;

  const _AvatarButton({required this.user, required this.role});

  @override
  Widget build(BuildContext context) {
    final initials = user?.initials ?? 'U';
    final emoji = user?.roleEmoji ?? '👤';
    return GestureDetector(
      onTap: () => _showProfileSnack(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials.length > 2 ? emoji : initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSnack(BuildContext context) {
    final name = user?.displayName ?? '';
    final email = user?.email ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name • $email'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Vet Treatment List ───────────────────────────────────────────────────────

class _VetTreatmentList extends StatelessWidget {
  final FirestoreService fs;

  const _VetTreatmentList({required this.fs});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppAuthProvider>().firebaseUser?.uid ?? '';

    return StreamBuilder<List<TreatmentModel>>(
      stream: fs.getVetTreatments(uid),
      builder: (context, snap) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Text(
              'Recent Treatments',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (!snap.hasData || snap.data!.isEmpty)
              const _EmptyState(message: 'No treatments logged yet.')
            else
              ...snap.data!.take(10).map((t) => TreatmentListItem(
                    treatment: t,
                    onFlagDeletion: () => _showFlagDialog(context, t.id),
                  )),
          ]),
        );
      },
    );
  }

  void _showFlagDialog(BuildContext context, String id) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Flag for Deletion'),
        content: TextField(
          controller: reasonCtrl,
          decoration:
              const InputDecoration(hintText: 'Reason for deletion request...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              await fs.requestTreatmentDeletion(id, reasonCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Flag'),
          ),
        ],
      ),
    );
  }
}

// ─── Farmer Herd View ─────────────────────────────────────────────────────────

class _FarmerHerdView extends StatelessWidget {
  final FirestoreService fs;

  const _FarmerHerdView({required this.fs});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AppAuthProvider>().firebaseUser?.uid ?? '';

    return StreamBuilder<List<TreatmentModel>>(
      stream: fs.getFarmerTreatments(uid),
      builder: (context, snap) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Row(
              children: [
                Expanded(
                  child: Text(
                    "My Herd's Health",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sosDialog(context),
                  icon: const Icon(Icons.emergency_rounded, size: 16),
                  label: const Text('SOS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (!snap.hasData || snap.data!.isEmpty)
              const _EmptyState(message: 'No treatment records found.')
            else
              ...snap.data!.take(10).map((t) => TreatmentListItem(
                    treatment: t,
                    showActions: false,
                  )),
          ]),
        );
      },
    );
  }

  void _sosDialog(BuildContext context) {
    final noteCtrl = TextEditingController();
    final uid = context.read<AppAuthProvider>().firebaseUser?.uid ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🚨 Emergency SOS',
                  style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.errorRed,
                      )),
              const SizedBox(height: 14),
              TextField(
                controller: noteCtrl,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe the emergency...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorRed),
                      onPressed: () async {
                        if (noteCtrl.text.isEmpty) return;
                        await FirestoreService().addEmergency(
                          farmerId: uid,
                          note: noteCtrl.text,
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                                content: Text('🚨 Emergency SOS Sent!')),
                          );
                        }
                      },
                      child: const Text('Send SOS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Admin Overview ───────────────────────────────────────────────────────────

class _AdminOverview extends StatefulWidget {
  final FirestoreService fs;

  const _AdminOverview({required this.fs});

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  String _filter = 'Pending Approval';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TreatmentModel>>(
      stream: widget.fs.getAllTreatments(status: _filter),
      builder: (context, snap) {
        return SliverList(
          delegate: SliverChildListDelegate([
            Text('Admin Review',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Pending Approval', 'Approved', 'Rejected']
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(f),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: AppTheme.primary.withOpacity(0.15),
                            checkmarkColor: AppTheme.primary,
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator())
            else if (!snap.hasData || snap.data!.isEmpty)
              _EmptyState(message: 'No records in "$_filter".')
            else
              ...snap.data!.map((t) => _AdminTreatmentItem(
                    treatment: t,
                    fs: widget.fs,
                  )),
          ]),
        );
      },
    );
  }
}

class _AdminTreatmentItem extends StatelessWidget {
  final TreatmentModel treatment;
  final FirestoreService fs;

  const _AdminTreatmentItem({required this.treatment, required this.fs});

  @override
  Widget build(BuildContext context) {
    final commentCtrl = TextEditingController();
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TreatmentListItem(treatment: treatment, showActions: false),
          if (treatment.status == 'Pending Approval') ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
              child: TextField(
                controller: commentCtrl,
                decoration:
                    const InputDecoration(hintText: 'Review comment...'),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => fs.updateTreatmentStatus(
                        treatment.id, 'Approved', commentCtrl.text),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed),
                    onPressed: () => fs.updateTreatmentStatus(
                        treatment.id, 'Rejected', commentCtrl.text),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }
}
