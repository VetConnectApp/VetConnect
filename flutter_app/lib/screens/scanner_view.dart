import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';

import '../models/animal_model.dart';
import '../models/treatment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../theme.dart';
import '../widgets/glass_card.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> with WidgetsBindingObserver {
  final MobileScannerController _cameraCtrl = MobileScannerController();
  final FirestoreService _fs = FirestoreService();

  bool _isNfcMode = false;
  bool _isScanning = false;
  bool _nfcAvailable = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNfc();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraCtrl.dispose();
    NfcManager.instance.stopSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_cameraCtrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraCtrl.stop();
    } else if (state == AppLifecycleState.resumed && !_isNfcMode) {
      _cameraCtrl.start();
    }
  }

  Future<void> _checkNfc() async {
    final available = await NfcManager.instance.isAvailable();
    if (mounted) setState(() => _nfcAvailable = available);
  }

  void _switchMode(bool nfc) {
    if (nfc && !_nfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device.')),
      );
      return;
    }
    setState(() {
      _isNfcMode = nfc;
      _statusMessage = '';
      _isScanning = false;
    });
    if (nfc) {
      _cameraCtrl.stop();
    } else {
      NfcManager.instance.stopSession();
      _cameraCtrl.start();
    }
  }

  Future<void> _startNfcScan() async {
    setState(() {
      _isScanning = true;
      _statusMessage = '📡 NFC active — tap a tag near your phone...';
    });

    await NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        String? tagId;

        // Try to read NDEF text record first
        final ndef = Ndef.from(tag);
        if (ndef != null) {
          final msg = await ndef.read();
          for (final record in msg.records) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
              final payload = record.payload;
              // Skip language code bytes (first byte = length of language code)
              if (payload.isNotEmpty) {
                final langLen = payload[0] & 0x3F;
                tagId = String.fromCharCodes(payload.sublist(1 + langLen));
              }
            }
          }
        }

        // Fall back to tag identifier
        tagId ??= tag.data.entries
            .where(
                (e) => e.value is Map && (e.value as Map)['identifier'] != null)
            .map((e) {
          final bytes = (e.value as Map)['identifier'] as List<int>?;
          return bytes
              ?.map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();
        }).firstWhere((id) => id != null, orElse: () => null);

        tagId ??= 'NFC-${DateTime.now().millisecondsSinceEpoch}';

        await NfcManager.instance.stopSession();
        if (mounted) {
          setState(() {
            _isScanning = false;
            _statusMessage = '✅ NFC Tag detected: $tagId';
          });
          _handleScannedId(tagId);
        }
      },
    );
  }

  void _handleBarcodeDetect(BarcodeCapture capture) {
    if (_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final value = barcode!.rawValue!;
    _cameraCtrl.stop();
    setState(() {
      _isScanning = true;
      _statusMessage = '🔍 Barcode detected: $value';
    });
    _handleScannedId(value);
  }

  Future<void> _handleScannedId(String scannedId) async {
    setState(() => _statusMessage = '🔍 Searching database for: $scannedId...');

    final animal = await _fs.findAnimal(scannedId);

    if (!mounted) return;
    if (animal != null) {
      setState(() => _statusMessage = '✅ Found: ${animal.tagId}');
      _showAnimalProfile(animal);
    } else {
      setState(() => _statusMessage = '⚠️ Not found. Register new cattle?');
      _showRegisterSheet(scannedId);
    }
  }

  void _showAnimalProfile(AnimalModel animal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AnimalProfileSheet(animal: animal, fs: _fs),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = '';
        });
        if (!_isNfcMode) _cameraCtrl.start();
      }
    });
  }

  void _showRegisterSheet(String scannedId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RegisterCattleSheet(
        prefillId: scannedId,
        fs: _fs,
        onRegistered: (animal) {
          if (mounted) {
            setState(() {
              _isScanning = false;
              _statusMessage = '✅ Registered: ${animal.tagId}';
            });
          }
        },
      ),
    ).then((_) {
      if (mounted && !_isNfcMode) {
        setState(() {
          _isScanning = false;
          _statusMessage = '';
        });
        _cameraCtrl.start();
      }
    });
  }

  void _manualSearch(String value) {
    if (value.isEmpty) return;
    _cameraCtrl.stop();
    _handleScannedId(value);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeProvider>().t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final role = context.watch<AppAuthProvider>().role;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('scanner')),
        actions: [
          // Manual search
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => _showManualSearch(context),
            tooltip: 'Manual Tag Search',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mode Toggle ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: GlassCard(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: t('camera_mode'),
                      icon: Icons.qr_code_scanner_rounded,
                      isActive: !_isNfcMode,
                      onTap: () => _switchMode(false),
                    ),
                  ),
                  Expanded(
                    child: _ModeButton(
                      label: t('nfc_mode'),
                      icon: Icons.nfc_rounded,
                      isActive: _isNfcMode,
                      onTap: () => _switchMode(true),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Camera / NFC View ──────────────────────────────────────────
          Expanded(
            child: _isNfcMode
                ? _buildNfcPanel(context, t)
                : _buildCameraPanel(context, t),
          ),

          // ── Status Bar ─────────────────────────────────────────────────
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Register button shortcut (Vet only) ───────────────────────
          if (role == 'vet')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showRegisterSheet(''),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Register New Cattle'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPanel(BuildContext context, String Function(String) t) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: MobileScanner(
            controller: _cameraCtrl,
            onDetect: _handleBarcodeDetect,
          ),
        ),
        // Scan overlay
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.accent, width: 2.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Positioned(
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t('scan_barcode'),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
        // Flash toggle
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
            onPressed: () => _cameraCtrl.toggleTorch(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNfcPanel(BuildContext context, String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            width: _isScanning ? 140 : 120,
            height: _isScanning ? 140 : 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isScanning
                    ? [AppTheme.primaryLight, AppTheme.accent]
                    : [AppTheme.primary, AppTheme.primaryDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(_isScanning ? 0.5 : 0.3),
                  blurRadius: _isScanning ? 40 : 20,
                ),
              ],
            ),
            child: Icon(
              Icons.nfc_rounded,
              color: Colors.white,
              size: _isScanning ? 70 : 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isScanning
                ? 'Scanning — hold your device\nnear the NFC tag'
                : t('scan_nfc'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (!_isScanning)
            ElevatedButton.icon(
              onPressed: _startNfcScan,
              icon: const Icon(Icons.nfc_rounded, size: 18),
              label: const Text('Start NFC Scan'),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                NfcManager.instance.stopSession();
                setState(() {
                  _isScanning = false;
                  _statusMessage = '';
                });
              },
              icon: const Icon(Icons.stop_rounded, size: 18),
              label: const Text('Stop Scan'),
            ),
        ],
      ),
    );
  }

  void _showManualSearch(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search by Tag ID'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter Tag ID...'),
          onSubmitted: (v) {
            Navigator.pop(ctx);
            _manualSearch(v.trim());
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _manualSearch(ctrl.text.trim());
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

// ─── Mode Toggle Button ───────────────────────────────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animal Profile Sheet ─────────────────────────────────────────────────────

class _AnimalProfileSheet extends StatefulWidget {
  final AnimalModel animal;
  final FirestoreService fs;

  const _AnimalProfileSheet({required this.animal, required this.fs});

  @override
  State<_AnimalProfileSheet> createState() => _AnimalProfileSheetState();
}

class _AnimalProfileSheetState extends State<_AnimalProfileSheet> {
  final _noteCtrl = TextEditingController();
  final _medCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _urgency = 'Routine';
  DateTime? _nextDue;
  final List<Map<String, String>> _prescriptions = [];
  bool _showTreatmentForm = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _medCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final auth = context.read<AppAuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pets_rounded,
                      color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tag: ${animal.tagId}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text('${animal.species} • ${animal.breed}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(0.5),
                            )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Info rows
            _InfoRow(
                label: '📡 NFC ID',
                value: animal.nfcId.isEmpty ? 'None' : animal.nfcId),
            _InfoRow(
                label: '📷 Barcode',
                value: animal.barcodeId.isEmpty ? 'None' : animal.barcodeId),
            _InfoRow(label: '👤 Farmer', value: animal.farmerId),
            const SizedBox(height: 16),
            // Treatment history
            Text('Treatment History',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            StreamBuilder(
              stream: widget.fs.getAnimalTreatments(animal.tagId),
              builder: (ctx, snap) {
                if (!snap.hasData || snap.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No treatments on record.',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return Column(
                  children: snap.data!
                      .take(5)
                      .map((t) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.urgency,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: cs.primary,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(t.notes,
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            // Add treatment (vet only)
            if (auth.role == 'vet') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      setState(() => _showTreatmentForm = !_showTreatmentForm),
                  icon: Icon(
                    _showTreatmentForm
                        ? Icons.expand_less_rounded
                        : Icons.note_add_rounded,
                    size: 18,
                  ),
                  label: Text(_showTreatmentForm
                      ? 'Hide Form'
                      : '📝 Add Treatment Log'),
                ),
              ),
              if (_showTreatmentForm) ...[
                const SizedBox(height: 16),
                _buildTreatmentForm(context, auth, cs),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentForm(
      BuildContext context, AppAuthProvider auth, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgency select
        DropdownButtonFormField<String>(
          initialValue: _urgency,
          decoration: const InputDecoration(labelText: 'Urgency'),
          items: ['Routine', 'Urgent', 'Surgery']
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) => setState(() => _urgency = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Treatment Notes...'),
        ),
        const SizedBox(height: 12),
        // Prescription
        Text('Prescription', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _medCtrl,
                decoration: const InputDecoration(hintText: 'Medicine'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _doseCtrl,
                decoration:
                    const InputDecoration(hintText: 'Dosage (e.g. 20ml)'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon:
                  const Icon(Icons.add_circle_rounded, color: AppTheme.primary),
              onPressed: () {
                if (_medCtrl.text.isNotEmpty && _doseCtrl.text.isNotEmpty) {
                  setState(() {
                    _prescriptions.add({
                      'medicine': _medCtrl.text,
                      'dosage': _doseCtrl.text,
                    });
                    _medCtrl.clear();
                    _doseCtrl.clear();
                  });
                }
              },
            ),
          ],
        ),
        if (_prescriptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _prescriptions
                .map((p) => Chip(
                      label: Text('${p['medicine']}: ${p['dosage']}',
                          style: const TextStyle(fontSize: 11)),
                      onDeleted: () => setState(() => _prescriptions.remove(p)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 12),
        // Next due date
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 30)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) setState(() => _nextDue = picked);
          },
          icon: const Icon(Icons.calendar_today_rounded, size: 16),
          label: Text(_nextDue == null
              ? 'Set Next Due Date (optional)'
              : 'Next Due: ${_nextDue!.day}/${_nextDue!.month}/${_nextDue!.year}'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving ? null : () => _saveTreatment(auth),
            child: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save Treatment Log'),
          ),
        ),
      ],
    );
  }

  Future<void> _saveTreatment(AppAuthProvider auth) async {
    if (_noteCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await widget.fs.addTreatment(
        TreatmentModel(
          animalTagId: widget.animal.tagId,
          vetId: auth.firebaseUser?.uid ?? '',
          vetName: auth.userProfile?.displayName ?? 'Vet',
          farmerId: widget.animal.farmerId,
          urgency: _urgency,
          notes: _noteCtrl.text,
          prescription: _prescriptions
              .map((p) => PrescriptionItem(
                  medicine: p['medicine']!, dosage: p['dosage']!))
              .toList(),
          nextDueDate: _nextDue,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Treatment logged successfully!')),
        );
        setState(() {
          _showTreatmentForm = false;
          _noteCtrl.clear();
          _prescriptions.clear();
          _nextDue = null;
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label  ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  )),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
          ),
        ],
      ),
    );
  }
}

// ─── Register Cattle Sheet ────────────────────────────────────────────────────

class _RegisterCattleSheet extends StatefulWidget {
  final String prefillId;
  final FirestoreService fs;
  final void Function(AnimalModel) onRegistered;

  const _RegisterCattleSheet({
    required this.prefillId,
    required this.fs,
    required this.onRegistered,
  });

  @override
  State<_RegisterCattleSheet> createState() => _RegisterCattleSheetState();
}

class _RegisterCattleSheetState extends State<_RegisterCattleSheet> {
  late final TextEditingController _tagCtrl;
  final _speciesCtrl = TextEditingController(text: 'Cow');
  final _breedCtrl = TextEditingController();
  final _farmerEmailCtrl = TextEditingController(text: 'farmer@vetconnect.com');
  String _nfcId = '';
  final String _barcodeId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tagCtrl = TextEditingController(text: widget.prefillId);
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _speciesCtrl.dispose();
    _breedCtrl.dispose();
    _farmerEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Register New Cattle',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(labelText: 'Tag Number *'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _nfcId.isNotEmpty ? null : _assignNfc,
                    icon: const Icon(Icons.nfc_rounded, size: 16),
                    label: Text(
                        _nfcId.isNotEmpty ? '✅ NFC Linked' : 'Assign NFC Tag'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                    label: Text(_barcodeId.isNotEmpty
                        ? '✅ Barcode Set'
                        : 'Scan Barcode'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _speciesCtrl,
              decoration: const InputDecoration(labelText: 'Species'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedCtrl,
              decoration: const InputDecoration(labelText: 'Breed'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _farmerEmailCtrl,
              decoration:
                  const InputDecoration(labelText: 'Farmer Email (Owner)'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _register,
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Register'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignNfc() async {
    final available = await NfcManager.instance.isAvailable();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NFC not available on this device')),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📡 Tap a NFC tag to assign...')),
    );
    await NfcManager.instance.startSession(
      onDiscovered: (tag) async {
        final id = 'NFC-${DateTime.now().millisecondsSinceEpoch}';
        await NfcManager.instance.stopSession();
        if (mounted) setState(() => _nfcId = id);
      },
    );
  }

  Future<void> _register() async {
    if (_tagCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    final animal = AnimalModel(
      tagId: _tagCtrl.text.trim(),
      nfcId: _nfcId,
      barcodeId: _barcodeId,
      species: _speciesCtrl.text,
      breed: _breedCtrl.text,
      farmerId: _farmerEmailCtrl.text.trim(),
    );
    try {
      await widget.fs.registerAnimal(animal);
      widget.onRegistered(animal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }
}
