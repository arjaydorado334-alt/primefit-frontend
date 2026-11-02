import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../screens/user_session.dart';
import '../services/profile_service.dart';
import 'portal_hero.dart';
import 'status_alert_banner.dart';
import 'dart:async';
import '../services/session_status_service.dart';

/// Brightness-aware color tokens for this screen -- call `_Colors.sync`
/// once at the top of a build() before reading any of these getters.
class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) => _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get cardBg => _dark ? AppColors.darkCard : Colors.white;
  static Color get cardBorder => _dark ? AppColors.darkBorder : AppColors.cardBorder;
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF1F2937);
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : const Color(0xFF64748B);
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : const Color(0xFF94A3B8);
  static Color get qrPlaceholderIcon => _dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
  static Color get progressTrack => _dark ? AppColors.darkBorder : const Color(0xFFF3F4F6);

  /// Neutral fill for small tiles and info boxes (no colored tints).
  static Color get subtleBg => _dark ? AppColors.darkBorder : const Color(0xFFF9FAFB);

  static List<BoxShadow> get cardShadow =>
      _dark ? const [] : AppColors.softCardShadow;

  /// Cyan text that stays readable on both the light and dark surfaces.
  static Color get cyanText => _dark ? AppColors.cyan : const Color(0xFF0E7490);
}

class QrCheckinView extends StatefulWidget {
  final String memberName;
  final String memberId;
  final String planName;
  final String memberSince;
  final String renewsOn;
  final int creditsTotal;

  /// The real numeric MemberID from the `Members` table (AUTO_INCREMENT
  /// PK). Required to call checkin_api.php. If null, check-in is disabled
  /// with a friendly message (e.g. session expired).
  final int? dbMemberId;

  /// Sessions already used this period, from `Memberships.SessionsUsed`,
  /// so the counter starts accurate instead of at a hardcoded demo value.
  final int initialSessionsUsed;

  /// The signed, tamper-proof QR token from `Members.QRCodeData`. This is
  /// what actually gets encoded into the QR image and sent for check-in
  /// verification -- NOT the plain memberId|name|plan string, which
  /// anyone could forge.
  final String qrCodeData;

  const QrCheckinView({
    super.key,
    this.memberName = 'John Dela Cruz',
    this.memberId = 'PF-2026-00142',
    this.planName = 'Premium · 1 Month',
    this.memberSince = 'January 15, 2024',
    this.renewsOn = 'July 10, 2026',
    this.creditsTotal = 30,
    this.dbMemberId,
    this.initialSessionsUsed = 0,
    this.qrCodeData = '',
  });

  @override
  State<QrCheckinView> createState() => _QrCheckinViewState();
}

class _QrCheckinViewState extends State<QrCheckinView> {
  late int _sessionsUsed;
  late int _creditsTotal;
  late String _qrCodeData;
  // Members no longer self-check-in (the front desk scans their QR code), so
  // these stay at their placeholder — the "Last Check-In" card is kept as-is.
  final String _lastCheckIn = '—';
  final String _lastCheckInTime = '—';

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _sessionsUsed = widget.initialSessionsUsed;
    _creditsTotal = widget.creditsTotal;
    _qrCodeData = UserSession.instance.qrCodeData.isNotEmpty
        ? UserSession.instance.qrCodeData
        : widget.qrCodeData;
    if (_qrCodeData.isEmpty && mounted && widget.dbMemberId != null) {
      _refreshQrCode();
    }
    _startPolling();
  }

  void _startPolling() {
    // Poll every 5 seconds so the credit counter updates automatically
    // after the front-desk admin scans the member's QR code -- no
    // manual refresh needed.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollSessionStatus());
  }

  Future<void> _pollSessionStatus() async {
    final memberId = widget.dbMemberId;
    if (memberId == null) return;

    final result = await SessionStatusService.fetchStatus(memberId);
    if (!mounted) return;

    if (result['success'] == true) {
      final newCredits = int.tryParse('${result['session_credits']}');
      final newUsed = int.tryParse('${result['sessions_used']}');

      if (newCredits != null && newUsed != null) {
        if (newCredits != _creditsTotal || newUsed != _sessionsUsed) {
          setState(() {
            _creditsTotal = newCredits;
            _sessionsUsed = newUsed;
            UserSession.instance.creditsTotal = newCredits;
            UserSession.instance.sessionsUsed = newUsed;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshQrCode() async {
    final memberId = widget.dbMemberId;
    if (memberId == null) return;
    final result = await ProfileService.fetchProfile(memberId);
    if (!mounted) return;
    if (result['success'] == true && result['profile'] is Map) {
      final profile = result['profile'] as Map<String, dynamic>;
      final qr = profile['QRCodeData']?.toString() ?? profile['qr_code_data']?.toString() ?? '';
      if (qr.isNotEmpty) {
        setState(() {
          _qrCodeData = qr;
          UserSession.instance.qrCodeData = qr;
        });
      }
    }
  }

  int get _creditsLeft => _creditsTotal - _sessionsUsed;

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final isWide = MediaQuery.of(context).size.width > 900;
    final progress = _creditsTotal == 0 ? 0.0 : _sessionsUsed / _creditsTotal;
    final usedPercent = (progress * 100).round();

    final qrCard = _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member header: neutral row (no solid teal block).
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _Colors.cardBorder)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
                  child: Text(
                    widget.memberName.trim().isNotEmpty ? widget.memberName.trim()[0] : '?',
                    style: TextStyle(color: _Colors.cyanText, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.memberName,
                          style: TextStyle(color: _Colors.textPrimary, fontWeight: FontWeight.w700)),
                      Text(widget.memberId,
                          style: TextStyle(color: _Colors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(widget.planName,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _Colors.cyanText)),
                    ),
                    const SizedBox(height: 4),
                    Text('Membership plan',
                        style: TextStyle(color: _Colors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _Colors.cardBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _qrCodeData.isNotEmpty
                      ? QrImageView(
                          data: _qrCodeData,
                          version: QrVersions.auto,
                          backgroundColor: Colors.white,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2, size: 60, color: _Colors.qrPlaceholderIcon),
                            const SizedBox(height: 12),
                            const Text(
                              'QR code not yet available',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _refreshQrCode,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh QR Code'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1F2937),
                                side: BorderSide(
                                    color: const Color(0xFF1F2937).withValues(alpha: 0.35)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                Text(widget.memberId, style: TextStyle(color: _Colors.textMuted, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: _Colors.textSecondary, fontSize: 13),
                    children: [
                      const TextSpan(text: 'Valid until: '),
                      TextSpan(text: widget.renewsOn, style: TextStyle(fontWeight: FontWeight.w700, color: _Colors.textPrimary)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(Icons.person_outline, 'Name', widget.memberName),
                _infoRow(Icons.credit_card, 'Plan', widget.planName, valueColor: _Colors.cyanText),
                _infoRow(Icons.shield_outlined, 'Member Since', widget.memberSince),
                _infoRow(Icons.event_available_outlined, 'Renews', widget.renewsOn),
                const SizedBox(height: 16),
                Text(
                  'This QR code is unique to your account. Do not share it with others. '
                  'Present it to the front desk for each gym session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _Colors.textMuted, fontSize: 11.5),
                ),
                const SizedBox(height: 16),
                // Members no longer check themselves in — the front desk
                // scans this QR code to log the session. This status note
                // replaces the old "Check In Now" button.
                _infoBox(
                  icon: Icons.qr_code_scanner,
                  child: Text(
                    'Your session is logged automatically when the front desk '
                    'scans this QR code — no check-in needed here.',
                    style: TextStyle(color: _Colors.textSecondary, fontSize: 12.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _iconTile(Icons.confirmation_number_outlined),
                  const SizedBox(width: 10),
                  const _PanelTitle('Session Credits'),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _creditStatCard(
                      icon: Icons.event_available_outlined,
                      label: 'Remaining',
                      value: '$_creditsLeft',
                      color: const Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _creditStatCard(
                      icon: Icons.history,
                      label: 'Used',
                      value: '$_sessionsUsed',
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _creditStatCard(
                      icon: Icons.confirmation_number_outlined,
                      label: 'Total',
                      value: '$_creditsTotal',
                      color: AppColors.cyan,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$usedPercent% used', style: TextStyle(fontSize: 12, color: _Colors.textSecondary, fontWeight: FontWeight.w500)),
                      Text('Resets on renewal', style: TextStyle(fontSize: 12, color: _Colors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: _Colors.progressTrack,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.8 ? const Color(0xFFEF4444) : AppColors.cyan,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconTile(Icons.access_time),
                    const SizedBox(height: 12),
                    Text('Last Check-In', style: TextStyle(color: _Colors.textMuted, fontSize: 12)),
                    Text(_lastCheckIn, style: TextStyle(fontWeight: FontWeight.w700, color: _Colors.textPrimary)),
                    Text(_lastCheckInTime, style: TextStyle(color: _Colors.textMuted, fontSize: 11.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _iconTile(Icons.calendar_today_outlined),
                    const SizedBox(height: 12),
                    Text('Sessions This Month', style: TextStyle(color: _Colors.textMuted, fontSize: 12)),
                    Text('$_sessionsUsed sessions', style: TextStyle(fontWeight: FontWeight.w700, color: _Colors.textPrimary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _infoBox(
          icon: Icons.shield_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How it works',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _Colors.textPrimary)),
              const SizedBox(height: 6),
              Text(
                'Each time you visit PrimeFit, present your QR code to the front desk. '
                'The staff scanner reads your member ID and subscription — 1 credit is '
                'deducted per session automatically.',
                style: TextStyle(color: _Colors.textSecondary, fontSize: 12.5, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PortalHero(
            eyebrow: 'Check-In',
            icon: Icons.qr_code_2,
            title: 'My QR Check-In Code',
            subtitle:
                'Show your QR code at the front desk — the staff scanner will log your session automatically.',
          ),
          const SizedBox(height: 20),
          StatusAlertBanner(session: UserSession.instance),
          const SizedBox(height: 4),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: qrCard),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: sideColumn),
                  ],
                )
              : Column(children: [qrCard, const SizedBox(height: 20), sideColumn]),
        ],
      ),
    );
  }

  /// Small cyan icon tile used on the cards (same style as the dashboard's
  /// KPI cards).
  static Widget _iconTile(IconData icon) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: AppColors.cyan),
      );

  /// Neutral info box with a small cyan icon (replaces the blue tinted boxes).
  static Widget _infoBox({required IconData icon, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _Colors.subtleBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Colors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.cyan, size: 18),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      );

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _Colors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: _Colors.textSecondary, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor ?? _Colors.textPrimary)),
        ],
      ),
    );
  }

  /// Neutral credit tile: only the small icon carries a color.
  Widget _creditStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Colors.subtleBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppText.statNumber(size: 24, color: _Colors.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: _Colors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase gray card title (Haws Prints style).
class _PanelTitle extends StatelessWidget {
  final String text;
  const _PanelTitle(this.text);

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: _Colors.textSecondary,
      ),
    );
  }
}

/// Neutral white card with a hairline border and soft shadow (no tinted fill).
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _Colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _Colors.cardBorder),
        boxShadow: _Colors.cardShadow,
      ),
      child: child,
    );
  }
}
