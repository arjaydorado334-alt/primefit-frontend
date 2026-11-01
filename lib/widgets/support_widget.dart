import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// ---------------------------------------------------------------------
/// PRIMEFIT SUPPORT WIDGET
/// A floating round button (bottom-right) that opens a small panel with
/// two tabs: Chat (answers from the FAQ list by keyword) and FAQ
/// (tap-to-expand questions). No backend needed.
///
/// Put this file at lib/widgets/support_widget.dart, then in
/// landing_page.dart add, as the LAST child of the body Stack:
///
///   const Positioned(right: 24, bottom: 24, child: SupportWidget()),
///
/// and `import '../widgets/support_widget.dart';` at the top.
/// ---------------------------------------------------------------------

// Colours (same values as the landing page's _Palette / AppColors).
const _bgDeep = Color(0xFF060608);
const _bgCard = AppColors.darkCard;
const _bgSoft = Color(0xFF1C1E24);
const _border = AppColors.darkBorder;
const _text = Color(0xFFE9EAEE);
const _strong = Color(0xFFF4F5F7);
const _muted = AppColors.textMutedOnDark;

class _Faq {
  final String section;
  final String q;
  final String a;
  final List<String> keys; // lowercase words the Chat tab matches on
  const _Faq(this.section, this.q, this.a, this.keys);
}

// EDIT THESE: sections, questions, answers and chat keywords.
const List<_Faq> _faqs = [
  // ---- About PrimeFit ----
  _Faq(
    'About PrimeFit',
    'What is PrimeFit?',
    'PrimeFit Gym Fitness and Wellness Center is a fitness facility that '
        'provides gym and fitness services through organized programs, '
        'equipment, and training support.',
    ['what is', 'about', 'who are'],
  ),
  _Faq(
    'About PrimeFit',
    'When was PrimeFit established?',
    'PrimeFit was established on September 6, 2025.',
    ['established', 'founded', 'since', 'when was', 'anniversary'],
  ),
  _Faq(
    'About PrimeFit',
    'Where is PrimeFit located?',
    'PrimeFit is located at 31 Bernardo St., near Army Road, Central Signal, '
        'Taguig City, 1633 Metro Manila.',
    ['where', 'location', 'address', 'located', 'direction', 'map'],
  ),
  _Faq(
    'About PrimeFit',
    'PrimeFit social media and contact information',
    'Phone: 0917 847 8351\n'
        'Email: primefitnesstaguig@gmail.com\n'
        'Facebook: PrimeFit Fitness Gym\n'
        'TikTok: @primefit.fitness.g',
    ['contact', 'social', 'phone', 'call', 'number', 'email', 'facebook',
      'tiktok', 'messenger', 'reach'],
  ),
  _Faq(
    'About PrimeFit',
    "What are PrimeFit's operating hours?",
    'Monday to Saturday: 7:00 AM – 10:00 PM\n'
        'Sunday: 8:00 AM – 8:00 PM',
    ['hour', 'open', 'close', 'what time', 'sunday', 'saturday'],
  ),
  _Faq(
    'About PrimeFit',
    'What services does PrimeFit offer?',
    'PrimeFit provides fitness programs, workout equipment, exercise '
        'services, and physical training.',
    ['service', 'offer', 'equipment', 'facilit', 'provide'],
  ),

  // ---- Membership ----
  _Faq(
    'Membership',
    'How can I become a PrimeFit member?',
    'Membership registration can be completed through the PrimeFit '
        'membership system. The system allows member information and '
        'membership records to be registered and managed digitally.',
    ['become a', 'join', 'sign up', 'signup', 'register', 'enroll', 'avail'],
  ),
  _Faq(
    'Membership',
    'What membership plans are available?',
    'PrimeFit offers different membership options. For the latest plans, '
        'inclusions, and rates, please check the Membership section of the '
        'website or inquire directly with PrimeFit.',
    ['plan', 'option', 'inclusion', 'promo', 'package'],
  ),
  _Faq(
    'Membership',
    'How much does membership cost?',
    'Membership rates may vary depending on the selected plan. Please check '
        "the current membership rates through PrimeFit's official channels.",
    ['price', 'cost', 'how much', 'rate', 'fee', 'peso', 'cheap'],
  ),
  _Faq(
    'Membership',
    'Can I check my membership status online?',
    'Yes. The web-based system allows members to view their membership '
        'information and records.',
    ['status', 'my membership', 'expire', 'expiry', 'renew', 'validity',
      'active'],
  ),

  // ---- Attendance & Fitness ----
  _Faq(
    'Attendance & Fitness',
    'How do I record my gym attendance?',
    'PrimeFit uses QR code technology for attendance and member '
        'verification, allowing check-ins to be recorded digitally.',
    ['attendance', 'check in', 'check-in', 'checkin', 'qr', 'scan'],
  ),
  _Faq(
    'Attendance & Fitness',
    'Can I view my attendance records?',
    'Yes. The system can record and monitor member attendance and activity '
        'history.',
    ['attendance record', 'my attendance', 'activity', 'history'],
  ),
  _Faq(
    'Attendance & Fitness',
    'Can I track my fitness progress?',
    'Yes. Members can track their fitness program progress, including '
        'progress toward sessions or milestones.',
    ['progress', 'track', 'milestone', 'results', 'improve'],
  ),
  _Faq(
    'Attendance & Fitness',
    'Can I have a fitness program assigned to me?',
    'Yes. The system supports the creation and assignment of fitness '
        'programs to members, including exercises and schedules.',
    ['program', 'assign', 'routine', 'exercise', 'workout'],
  ),

  // ---- Payments ----
  _Faq(
    'Payments',
    'Can I view my payment history?',
    'Yes. The system records billing and payment transactions, allowing '
        'members to access their payment history.',
    ['payment history', 'transaction', 'billing', 'receipt', 'invoice'],
  ),
  _Faq(
    'Payments',
    'Does PrimeFit accept cashless payments?',
    'Yes. The system supports the recording of cashless transactions such '
        'as GCash and PayMaya. Specific payment methods should be confirmed '
        'with PrimeFit.',
    ['cashless', 'gcash', 'maya', 'e-wallet', 'ewallet', 'payment method',
      'accept', 'pay'],
  ),
  _Faq(
    'Payments',
    'Can I pay for my membership directly through the website?',
    'The system records billing and payment information, but direct '
        'electronic fund transfers and payment gateway integrations are not '
        'available at the moment.',
    ['pay online', 'through the website', 'directly', 'payment gateway',
      'online payment'],
  ),

  // ---- PrimeFit Merchandise ----
  _Faq(
    'PrimeFit Merchandise',
    'Does PrimeFit sell merchandise?',
    'Yes. PrimeFit offers gym merchandise such as T-shirts and sleeveless '
        'shirts.',
    ['merch', 'shirt', 'sleeveless', 'apparel', 'sell', 'tee'],
  ),
  _Faq(
    'PrimeFit Merchandise',
    'Where can I check the available merchandise?',
    'You can view the available PrimeFit merchandise through the '
        'Merchandise section of the website or inquire directly with '
        'PrimeFit.',
    ['available merch', 'check merch', 'see merch', 'view merch', 'catalog'],
  ),
  _Faq(
    'PrimeFit Merchandise',
    'Are sizes, designs, and prices available online?',
    'Availability, sizes, designs, and prices may vary depending on current '
        'stock. Please check the Merchandise section or contact PrimeFit for '
        'the latest information.',
    ['size', 'design', 'stock'],
  ),

  // ---- Support & Information ----
  _Faq(
    'Support & Information',
    'What can I do through the PrimeFit website?',
    'Members can manage their profile, view membership information, monitor '
        'attendance, access payment history, view fitness programs and '
        'progress, and use scheduling and chatbot features.',
    ['website', 'what can i do', 'feature', 'portal', 'profile',
      'scheduling'],
  ),
  _Faq(
    'Support & Information',
    'How does AI help PrimeFit members?',
    'The system uses AI-powered analytics to analyze gym data and generate '
        'insights related to attendance, member engagement, membership '
        'renewal, revenue trends, and equipment maintenance.',
    [' ai ', 'analytics', 'insight', 'artificial'],
  ),
  _Faq(
    'Support & Information',
    'What can the AI chatbot help me with?',
    'The AI chatbot can answer basic member inquiries, provide membership '
        'information, show payment history, and assist with session '
        'scheduling.',
    ['chatbot', ' bot ', 'assistant', 'help me', 'you do'],
  ),
  _Faq(
    'Support & Information',
    'Do I need to install an app?',
    "No. PrimeFit's system is web-based and can be accessed through a web "
        'browser. It is designed to work across computers, tablets, and '
        'mobile browsers.',
    ['install', 'download', 'app store', ' app ', 'mobile'],
  ),
  _Faq(
    'Support & Information',
    'Do I need an internet connection to use the system?',
    "Yes. Since PrimeFit's system is web-based, an internet connection is "
        'required to access its online features.',
    ['internet', 'wifi', 'wi-fi', 'offline', 'connection'],
  ),
  _Faq(
    'Support & Information',
    'How is my information protected?',
    'The system uses a centralized database and secure web communication '
        'through HTTPS/SSL to help protect stored and transmitted '
        'information.',
    ['privacy', 'protect', 'secure', 'security', 'safe', 'https', 'ssl',
      'personal'],
  ),
  _Faq(
    'Support & Information',
    'Where can I get the latest information about PrimeFit?',
    'For updated membership rates, merchandise availability, payment '
        "options, schedules, and other announcements, please refer to "
        "PrimeFit's official website or contact the gym directly.",
    ['latest', 'update', 'announcement', 'news', 'newest'],
  ),
];

const String _greeting =
    "Hi! I'm the PrimeFit assistant. Ask about hours, membership, payments, "
    'merchandise or how the system works, or browse the FAQ tab.';
const String _fallback =
    "I'm not sure about that one. Please call 0917 847 8351 or message "
    'PrimeFit on Facebook and our staff will help you.';

String _replyFor(String message) {
  // Pad with spaces and strip punctuation so keys like ' ai ' only match
  // whole words.
  final m =
      ' ${message.toLowerCase().replaceAll(RegExp(r"[^a-z0-9\- ]"), " ")} ';
  _Faq? best;
  var bestScore = 0;
  for (final f in _faqs) {
    var score = 0;
    for (final k in f.keys) {
      if (m.contains(k)) score++;
    }
    if (score > bestScore) {
      bestScore = score;
      best = f;
    }
  }
  return best?.a ?? _fallback;
}

class _Msg {
  final String text;
  final bool fromUser;
  const _Msg(this.text, this.fromUser);
}

class SupportWidget extends StatefulWidget {
  const SupportWidget({super.key});

  @override
  State<SupportWidget> createState() => _SupportWidgetState();
}

class _SupportWidgetState extends State<SupportWidget> {
  bool _open = false;
  int _tab = 0; // 0 = Chat, 1 = FAQ
  int? _expanded;
  bool _typing = false;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [const _Msg(_greeting, false)];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _typing) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(text, true));
      _typing = true;
    });
    _scrollToEnd();
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    setState(() {
      _messages.add(_Msg(_replyFor(text), false));
      _typing = false;
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final panelW = (size.width - 32).clamp(280.0, 380.0);
    final panelH = (size.height - 150).clamp(360.0, 560.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open) ...[
          _panel(panelW, panelH)
              .animate()
              .fade(duration: 180.ms)
              .slideY(begin: 0.04, end: 0, duration: 180.ms),
          const SizedBox(height: 12),
        ],
        _fab(),
      ],
    );
  }

  // ---- floating button --------------------------------------------------
  Widget _fab() {
    return Material(
      color: AppColors.gold,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _open = !_open),
        child: SizedBox(
          width: 62,
          height: 62,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              _open ? Icons.close : Icons.chat_bubble_rounded,
              key: ValueKey(_open),
              color: AppColors.onGold,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }

  // ---- panel ------------------------------------------------------------
  Widget _panel(double w, double h) {
    return Material(
      color: _bgCard,
      elevation: 12,
      shadowColor: Colors.black,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            _header(),
            _tabs(),
            Expanded(child: _tab == 0 ? _chatTab() : _faqTab()),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      decoration: const BoxDecoration(
        color: _bgDeep,
        border: Border(bottom: BorderSide(color: Color(0x73F2B705))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.archivoBlack(fontSize: 18, letterSpacing: -0.3),
              children: const [
                TextSpan(text: 'Prime', style: TextStyle(color: AppColors.cyan)),
                TextSpan(text: 'Fit ', style: TextStyle(color: AppColors.gold)),
                TextSpan(text: 'Support', style: TextStyle(color: _strong)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quick answers about PrimeFit, membership and more.',
            style: GoogleFonts.inter(fontSize: 12.5, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _tabs() {
    Widget tab(String label, int index) {
      final active = _tab == index;
      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.gold : _border,
                  width: active ? 2 : 1,
                ),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _strong : _muted,
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [tab('Chat', 0), tab('FAQ', 1)]);
  }

  // ---- FAQ tab ----------------------------------------------------------
  Widget _faqTab() {
    final rows = <Widget>[];
    String? lastSection;
    for (var i = 0; i < _faqs.length; i++) {
      final f = _faqs[i];
      if (f.section != lastSection) {
        lastSection = f.section;
        rows.add(Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 10, bottom: 10, left: 2),
          child: Text(
            f.section.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.cyan,
            ),
          ),
        ));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _faqTile(i),
      ));
    }
    return ListView(padding: const EdgeInsets.all(16), children: rows);
  }

  Widget _faqTile(int i) {
    final open = _expanded == i;
    final f = _faqs[i];
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _expanded = open ? null : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _bgSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: open ? AppColors.gold : _border,
            width: open ? 1.3 : 1,
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      f.q,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _strong,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: open ? AppColors.gold : _muted,
                    ),
                  ),
                ],
              ),
              if (open) ...[
                const SizedBox(height: 10),
                Text(
                  f.a,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: _muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---- Chat tab ---------------------------------------------------------
  Widget _chatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: _messages.length + (_typing ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length) {
                return _bubble('...', false);
              }
              final m = _messages[i];
              return _bubble(m.text, m.fromUser);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: _border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  style: GoogleFonts.inter(fontSize: 13.5, color: _text),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.inter(fontSize: 13.5, color: _muted),
                    filled: true,
                    fillColor: _bgSoft,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.gold,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _send,
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.send_rounded,
                        size: 19, color: AppColors.onGold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bubble(String text, bool fromUser) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: const BoxConstraints(maxWidth: 270),
        decoration: BoxDecoration(
          color: fromUser ? AppColors.cyan : _bgSoft,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            height: 1.45,
            color: fromUser ? Colors.black : _text,
          ),
        ),
      ),
    ).animate().fade(duration: 160.ms);
  }
}
