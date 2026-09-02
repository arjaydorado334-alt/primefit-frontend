import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/membership_plans.dart';
import '../services/billing_service.dart';
import '../theme/app_theme.dart';
import 'user_session.dart';

/// Dark-mode-aware tokens, matching the Membership page's palette so this
/// screen sits inside the same cyan/gold PrimeFit theme.
class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) =>
      _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get bg => _dark ? AppColors.darkBg : AppColors.portalPageBg;
  static Color get cardBg => _dark ? AppColors.darkCard : Colors.white;
  static Color get cardBorder =>
      _dark ? AppColors.darkBorder : Colors.grey.shade200;
  static Color get borderMuted =>
      _dark ? AppColors.darkBorder : Colors.grey.shade300;
  static Color get surfaceAlt =>
      _dark ? const Color(0xFF1C1D22) : Colors.grey.shade50;
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF1A1A1A);
  static Color get textSecondary =>
      _dark ? AppColors.textMutedOnDark : Colors.grey.shade600;
  static List<BoxShadow> get cardShadow =>
      _dark ? const [] : AppColors.softCardShadow;

  static const Color cyan = Color(0xFF22B8D8);
  static const Color gold = Color(0xFFCB8A00);
}

/// Payment-account details shown to the member. Placeholder values for now —
/// swap in the gym's real GCash / Maya numbers when available.
class _PayTarget {
  final String label;
  final String accountName;
  final String number;
  final IconData icon;
  final String qrAsset;
  const _PayTarget(
      this.label, this.accountName, this.number, this.icon, this.qrAsset);
}

const Map<String, _PayTarget> _payTargets = {
  // TODO: replace the placeholder account name / number with the real ones.
  'GCash': _PayTarget('GCash', 'PrimeFitness Gym', '0917 000 0000',
      Icons.smartphone_outlined, 'assets/qr/gcash_qr.jpg'),
  'Maya': _PayTarget('Maya', 'PrimeFitness Gym', '0918 000 0000',
      Icons.account_balance_wallet_outlined, 'assets/qr/maya_qr.jpg'),
};

class SubmitReceiptPage extends StatefulWidget {
  const SubmitReceiptPage({super.key});

  @override
  State<SubmitReceiptPage> createState() => _SubmitReceiptPageState();
}

class _SubmitReceiptPageState extends State<SubmitReceiptPage> {
  int? _selectedPlanIndex;
  String _method = 'GCash';
  Uint8List? _receiptBytes;
  String? _receiptName;

  bool _submitting = false;
  bool _submitted = false;
  String? _errorMessage;

  MembershipPlan? get _selectedPlan =>
      _selectedPlanIndex == null ? null : kMembershipPlans[_selectedPlanIndex!];

  bool get _canSubmit =>
      _selectedPlan != null && _receiptBytes != null && !_submitting;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: source, imageQuality: 80, maxWidth: 1600);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _receiptBytes = bytes;
        _receiptName = picked.name;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the image: $e')),
      );
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Colors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined,
                    color: _Colors.textPrimary),
                title: Text('Choose from gallery',
                    style: TextStyle(color: _Colors.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_camera_outlined, color: _Colors.textPrimary),
                title: Text('Take a photo',
                    style: TextStyle(color: _Colors.textPrimary)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final plan = _selectedPlan;
    final memberId = UserSession.instance.dbMemberId;

    if (plan == null || _receiptBytes == null) return;
    if (memberId == null) {
      setState(() => _errorMessage =
          'We could not identify your account. Please log in again.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await BillingService.submitReceipt(
      memberId: memberId,
      planId: plan.planId,
      method: _method,
      receiptBytes: _receiptBytes!,
      receiptFileName: _receiptName ?? 'receipt.jpg',
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result['success'] == true) {
      setState(() => _submitted = true);
    } else {
      setState(() => _errorMessage =
          result['message']?.toString() ??
              'Submission failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);

    return Scaffold(
      backgroundColor: _Colors.bg,
      appBar: AppBar(
        backgroundColor: _Colors.cardBg,
        foregroundColor: _Colors.textPrimary,
        elevation: 0,
        title: const Text('Submit Payment Receipt',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: _submitted ? _buildSuccess() : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ form

  Widget _buildForm() {
    final plan = _selectedPlan;
    final target = _payTargets[_method]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pay for a plan manually via GCash or Maya, then upload a screenshot '
          'of your payment confirmation. Your membership is activated once an '
          'admin reviews it.',
          style: TextStyle(fontSize: 13.5, color: _Colors.textSecondary),
        ),
        const SizedBox(height: 24),

        _sectionTitle('1. Choose a plan'),
        const SizedBox(height: 12),
        for (int i = 0; i < kMembershipPlans.length; i++) _planTile(i),

        const SizedBox(height: 24),
        _sectionTitle('2. Payment method'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _methodButton('GCash')),
            const SizedBox(width: 12),
            Expanded(child: _methodButton('Maya')),
          ],
        ),

        const SizedBox(height: 24),
        _sectionTitle('3. Pay to this account'),
        const SizedBox(height: 12),
        _payToCard(target, plan),

        const SizedBox(height: 24),
        _sectionTitle('4. Upload your receipt'),
        const SizedBox(height: 12),
        _uploadBox(),

        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFDC2626), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFB91C1C), fontSize: 13)),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _canSubmit ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _Colors.cyan,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _Colors.borderMuted,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit Receipt',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: _Colors.textPrimary),
      );

  Widget _planTile(int index) {
    final plan = kMembershipPlans[index];
    final selected = _selectedPlanIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _selectedPlanIndex = index),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? _Colors.cyan.withValues(alpha: 0.06)
                : _Colors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _Colors.cyan : _Colors.borderMuted,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? const [] : _Colors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? _Colors.cyan : _Colors.borderMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.duration,
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _Colors.textPrimary)),
                        const Spacer(),
                        Text('₱${formatPeso(plan.price)}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _Colors.gold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...plan.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 13, color: Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(f,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _Colors.textSecondary)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _methodButton(String method) {
    final selected = _method == method;
    final target = _payTargets[method]!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _method = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? _Colors.cyan : _Colors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _Colors.cyan : _Colors.borderMuted,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? const [] : _Colors.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(target.icon,
                size: 18,
                color: selected ? Colors.white : _Colors.textSecondary),
            const SizedBox(width: 8),
            Text(method,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: selected ? Colors.white : _Colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _payToCard(_PayTarget target, MembershipPlan? plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              target.qrAsset,
              width: 190,
              height: 190,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => Container(
                width: 190,
                height: 190,
                color: _Colors.surfaceAlt,
                alignment: Alignment.center,
                child: Icon(Icons.qr_code_2,
                    size: 60, color: _Colors.borderMuted),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('${target.label} · ${target.accountName}',
              style: TextStyle(
                  fontSize: 13, color: _Colors.textSecondary)),
          const SizedBox(height: 2),
          SelectableText(
            target.number,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _Colors.textPrimary),
          ),
          if (plan != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _Colors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Amount to pay:  ₱${formatPeso(plan.price)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: _Colors.gold),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Scan the QR or send to the number above using your ${target.label} app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: _Colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _uploadBox() {
    final hasImage = _receiptBytes != null;
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        width: double.infinity,
        height: hasImage ? 220 : 120,
        decoration: BoxDecoration(
          color: _Colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? _Colors.cyan : _Colors.borderMuted,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.memory(_receiptBytes!, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, size: 13, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Change',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_upload_outlined,
                      size: 26, color: _Colors.textSecondary),
                  const SizedBox(height: 8),
                  Text('Tap to upload your payment receipt',
                      style: TextStyle(
                          fontSize: 12.5, color: _Colors.textSecondary)),
                  const SizedBox(height: 2),
                  Text('Gallery or camera',
                      style: TextStyle(
                          fontSize: 11,
                          color: _Colors.textSecondary.withValues(alpha: 0.7))),
                ],
              ),
      ),
    );
  }

  // --------------------------------------------------------------- success

  Widget _buildSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F9EF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Color(0xFF16A34A), size: 34),
          ),
          const SizedBox(height: 18),
          Text('Receipt submitted!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _Colors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Your membership will be activated once an admin reviews your payment.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.5, color: _Colors.textSecondary),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Colors.cyan,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Membership',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
