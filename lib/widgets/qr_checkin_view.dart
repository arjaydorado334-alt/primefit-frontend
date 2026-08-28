import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../screens/user_session.dart';
// 👇 Connects this widget to your PHP check-in API (checkin_api.php).
// Adjust the path if checkin_service.dart lives somewhere else.
import '../services/checkin_service.dart';
import '../services/profile_service.dart';
import 'status_alert_banner.dart';
import 'dart:async';
import '../services/session_status_service.dart';

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
  String _lastCheckIn = '—';
  String _lastCheckInTime = '—';
  bool _checkingIn = false;

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

  int get _creditsLeft => widget.creditsTotal - _sessionsUsed;

  Future<void> _handleCheckIn() async {
    if (_qrCodeData.isEmpty && widget.dbMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member session not found. Please log in again.')),
      );
      return;
    }
    if (_creditsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No session credits left this period.')),
      );
      return;
    }

    setState(() => _checkingIn = true);

    // Prefer the secure, signed QR token -- falls back to a raw member_id
    // only for older accounts created before this feature existed.
    final result = _qrCodeData.isNotEmpty
        ? await CheckinService.checkInWithQr(qrData: _qrCodeData)
        : await CheckinService.checkIn(memberId: widget.dbMemberId!);

    if (!mounted) return;

    setState(() => _checkingIn = false);

    if (result['success'] == true) {
      final newSessionsUsed = int.tryParse('${result['sessions_used']}') ?? (_sessionsUsed + 1);
      setState(() {
        _sessionsUsed = newSessionsUsed;
        UserSession.instance.sessionsUsed = newSessionsUsed;
        UserSession.instance.visitsThisWeek = int.tryParse('${result['visits_this_week']}') ?? (UserSession.instance.visitsThisWeek + 1);
        UserSession.instance.visitDates.add(DateTime.now());
        _lastCheckIn = result['check_in_date']?.toString() ?? _lastCheckIn;
        _lastCheckInTime = result['check_in_time']?.toString() ?? _lastCheckInTime;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checked in! 1 session credit deducted.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Check-in failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final progress = _creditsTotal == 0 ? 0.0 : _sessionsUsed / _creditsTotal;
    final usedPercent = (progress * 100).round();

    final qrCard = _Card(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Text(
                    widget.memberName.trim().isNotEmpty ? widget.memberName.trim()[0] : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.memberName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      Text(widget.memberId, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                       child: Text(widget.planName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black87)),
                     ),
                     const SizedBox(height: 4),
                     const Text('Membership plan', style: TextStyle(color: Colors.white70, fontSize: 11)),
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
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(12),
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
                              const Icon(Icons.qr_code_2, size: 60, color: Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              const Text(
                                'QR code not yet available',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _checkingIn ? null : _refreshQrCode,
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh QR Code'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                ),
                const SizedBox(height: 16),
                Text(widget.memberId, style: TextStyle(color: Colors.grey.shade500, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    children: [
                      const TextSpan(text: 'Valid until: '),
                      TextSpan(text: widget.renewsOn, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _infoRow(Icons.person_outline, 'Name', widget.memberName),
                _infoRow(Icons.credit_card, 'Plan', widget.planName, valueColor: AppColors.cyan),
                _infoRow(Icons.shield_outlined, 'Member Since', widget.memberSince),
                _infoRow(Icons.event_available_outlined, 'Renews', widget.renewsOn),
                const SizedBox(height: 16),
                Text(
                  'This QR code is unique to your account. Do not share it with others. '
                  'Present it to the front desk for each gym session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _checkingIn ? null : _handleCheckIn,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      _checkingIn ? 'Checking in…' : 'Check In Now',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.confirmation_number_outlined, color: AppColors.cyan, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text('Session Credits', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _creditStatCard(
                      label: 'Remaining',
                      value: '$_creditsLeft',
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFECFDF5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _creditStatCard(
                      label: 'Used',
                      value: '$_sessionsUsed',
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFFFBEB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _creditStatCard(
                      label: 'Total',
                      value: '$_creditsTotal',
                      color: AppColors.cyan,
                      bg: const Color(0xFFDDF7FC),
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
                      Text('$usedPercent% used', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      Text('Resets on renewal', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF3F4F6),
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
                    const Icon(Icons.access_time, color: AppColors.cyan, size: 20),
                    const SizedBox(height: 10),
                    Text('Last Check-In', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text(_lastCheckIn, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(_lastCheckInTime, style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
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
                    const Icon(Icons.calendar_today_outlined, color: AppColors.yellow, size: 20),
                    const SizedBox(height: 10),
                    Text('Sessions This Month', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text('$_sessionsUsed sessions', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAFAFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCDEFFB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, color: AppColors.cyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('How it works', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 6),
                    Text(
                      'Each time you visit PrimeFit, present your QR code to the front desk. '
                      'The staff scanner reads your member ID and subscription — 1 credit is '
                      'deducted per session automatically.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.5),
                    ),
                  ],
                ),
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
          const Text('My QR Check-In Code', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Show your QR code at the front desk — the staff scanner will log your session automatically.',
              style: TextStyle(color: Colors.grey.shade600)),
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

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _creditStatCard({required String label, required String value, required Color color, required Color bg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
  }
}
