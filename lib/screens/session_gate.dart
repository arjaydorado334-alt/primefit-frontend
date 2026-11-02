import 'package:flutter/material.dart';

import '../services/member_session_service.dart';
import 'landing_page.dart';
import 'member_portal_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late Future<SessionRestoreResult> _restore;
  bool _showHomepage = false;

  @override
  void initState() {
    super.initState();
    _restore = MemberSessionService.restore();
  }

  @override
  Widget build(BuildContext context) {
    if (_showHomepage) return const LandingPage();
    return FutureBuilder<SessionRestoreResult>(
      future: _restore,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == SessionRestoreResult.authenticated) {
          return const MemberPortalScreen();
        }
        if (snapshot.data == SessionRestoreResult.signedOut) {
          return const LandingPage();
        }
        return Scaffold(
          body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Could not verify your session. Please check your connection.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _restore = MemberSessionService.restore()),
                child: const Text('Try again'),
              ),
              TextButton(
                onPressed: () => setState(() => _showHomepage = true),
                child: const Text('Go to homepage'),
              ),
            ]),
          )),
        );
      },
    );
  }
}
