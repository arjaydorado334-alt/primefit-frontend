import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../screens/user_session.dart';
import '../services/checkin_service.dart';
import '../services/profile_service.dart';
import 'dart:async';
import '../services/session_status_service.dart';

class QRCodePage extends StatefulWidget {
  const QRCodePage({super.key});

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  List<Map<String, String>> sessionHistory = [];
  String _qrCodeData = '';
  bool _refreshingQr = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _qrCodeData = UserSession.instance.qrCodeData;
    if (_qrCodeData.isEmpty && UserSession.instance.dbMemberId != null && mounted) {
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
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final result = await SessionStatusService.fetchStatus(memberId);
    if (!mounted) return;

    if (result['success'] == true) {
      final newCredits = int.tryParse('${result['session_credits']}');
      final newUsed = int.tryParse('${result['sessions_used']}');
      final newVisits = int.tryParse('${result['visits_this_week']}');

      if (newCredits != null && newUsed != null) {
        // Only trigger a rebuild if something actually changed.
        if (newCredits != UserSession.instance.creditsTotal ||
            newUsed != UserSession.instance.sessionsUsed) {
          setState(() {
            UserSession.instance.creditsTotal = newCredits;
            UserSession.instance.sessionsUsed = newUsed;
            if (newVisits != null) {
              UserSession.instance.visitsThisWeek = newVisits;
            }
          });
        }
      }
    }
  }

  Future<void> _refreshQrCode() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;
    setState(() => _refreshingQr = true);
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
    if (mounted) setState(() => _refreshingQr = false);
  }

  int get _totalCredits => UserSession.instance.creditsTotal;

  int get _sessionsUsed => UserSession.instance.sessionsUsed;

  int get _remainingCredits => _totalCredits - _sessionsUsed;

  double get _progress => _totalCredits == 0 ? 0.0 : _sessionsUsed / _totalCredits;

  Future<void> _handleCheckIn() async {
    if (_remainingCredits <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No remaining credits this period."),
          ),
        );
      }
      return;
    }

    if (_qrCodeData.isEmpty && UserSession.instance.dbMemberId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No QR code available and no member session found.")),
        );
      }
      return;
    }

    final session = UserSession.instance;
    final result = _qrCodeData.isNotEmpty
        ? await CheckinService.checkInWithQr(qrData: _qrCodeData)
        : session.dbMemberId != null
            ? await CheckinService.checkIn(memberId: session.dbMemberId!)
            : null;

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      final newSessionsUsed = int.tryParse('${result['sessions_used']}') ?? (_sessionsUsed + 1);
      setState(() {
        session.sessionsUsed = newSessionsUsed;
        session.visitsThisWeek = int.tryParse('${result['visits_this_week']}') ?? (session.visitsThisWeek + 1);
        session.visitDates.add(DateTime.now());
        sessionHistory.insert(0, {
          "date": result['check_in_date']?.toString() ?? 'Today',
          "time": result['check_in_time']?.toString() ?? TimeOfDay.now().format(context),
          "credits": "-1 Credit",
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-in successful! 1 credit deducted.")),
        );
      }
    } else if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Check-in failed.')),
        );
      }
    } else {
      setState(() {
        session.sessionsUsed = _sessionsUsed + 1;
        sessionHistory.insert(0, {
          "date": "Today",
          "time": TimeOfDay.now().format(context),
          "credits": "-1 Credit",
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Check-in successful! 1 credit deducted.")),
        );
      }
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession.instance;
    final qrData = _qrCodeData;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "QR Code Check-In",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Scan your QR Code",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Use this QR code for gym check-in",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                       child: Column(
                        children: [
                          if (qrData.isEmpty)
                            Column(
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
                                  onPressed: _refreshingQr ? null : _refreshQrCode,
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Refresh QR Code'),
                                ),
                              ],
                            )
                          else
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 220.0,
                              gapless: false,
                            ),
                          const SizedBox(height: 25),
                          const Text(
                            "Member ID",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            session.memberId,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton.icon(
                              onPressed: _handleCheckIn,
                              icon: const Icon(Icons.login),
                              label: const Text(
                                "Check In Now",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          const Text(
                            "Session Credits",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: _progress.clamp(0.0, 1.0),
                                  strokeWidth: 12,
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "$_remainingCredits",
                                      style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      "Remaining",
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 25),
                          LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "$_remainingCredits of $_totalCredits credits left",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Recent Session History",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (sessionHistory.isEmpty)
                      const Text("No check-ins yet.", style: TextStyle(color: Colors.grey))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sessionHistory.length,
                        itemBuilder: (context, index) {
                          final item = sessionHistory[index];
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                              ),
                              title: Text(
                                item["date"]!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                item["time"]!,
                              ),
                              trailing: Text(
                                item["credits"]!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}