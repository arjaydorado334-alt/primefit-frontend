import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// PrimeFit member-portal sidebar, restyled to match the staff login page and
/// the admin portal:
///  * near-black rail with a thin right border, in both light and dark mode;
///  * gold-ringed logo + two-tone wordmark ("Prime" cyan, "Fit" gold) with a
///    divider underneath;
///  * thin icons; the active item is a solid gold pill with black bold text
///    (like the Sign In button); hovering gives a soft white wash;
///  * the footer is a bordered profile card with a gold tier pill, and an
///    outlined "Sign Out" pill below it.
/// Menu items, their icons, the widget's constructor and the navigation
/// callbacks are unchanged.
class _SidebarColors {
  /// Brand cyan (same value the member dashboard uses for its accents).
  static const Color cyan = Color(0xFF18B7D9);

  static const Color gold = AppColors.gold; // wordmark "Fit", active pill, tier

  /// Rail background (same near-black as the login screen).
  static const Color background = Color(0xFF0A0A0A);

  /// Hairline border / divider on the rail.
  static const Color border = Color(0xFF1F1F23);

  /// Profile card surface + border, and the Sign Out outline.
  static const Color cardSurface = Color(0xFF121214);
  static const Color cardBorder = Color(0xFF26262B);
  static const Color outline = Color(0xFF2E2E34);

  /// Row hover wash.
  static const Color hoverOverlay = Color(0x14FFFFFF);

  /// Text colors on the dark rail.
  static const Color mutedText = Color(0xFF8A8A93);
  static const Color inactiveText = Color(0xFFB4B4BC);

  /// Text/icon color placed on top of the gold active pill.
  static const Color onGold = Color(0xFF0A0A0A);

  static const Color red = Color(0xFFEF4444);
  static Color redOverlay(double opacity) => red.withValues(alpha: opacity);

  /// Soft red for the Sign Out label/icon while hovered or pressed.
  static const Color softRed = Color(0xFFFCA5A5);
}

class SidebarItemData {
  final IconData icon;
  final String label;
  const SidebarItemData(this.icon, this.label);
}

const List<SidebarItemData> sidebarItems = [
  SidebarItemData(Icons.grid_view_rounded, 'Dashboard'),
  SidebarItemData(Icons.fitness_center, 'Progress'),
  SidebarItemData(Icons.credit_card, 'Check-In'),
  SidebarItemData(Icons.qr_code_2, 'Membership'),
  SidebarItemData(Icons.show_chart, 'Program'),
  SidebarItemData(Icons.person_outline, 'Profile'),
];

class MemberSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final String memberName;
  final String memberTier;

  const MemberSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
    this.memberName = 'John Doe',
    this.memberTier = 'Premium Member',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: _SidebarColors.background,
        border: Border(
          right: BorderSide(color: _SidebarColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Branding ----------------
            // Tapping the logo/wordmark takes the member back to their
            // Dashboard (index 0), same as clicking a site's logo goes home.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelect(0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              height: 48,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/primefit_logo.jpg',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      style: GoogleFonts.archivoBlack(
                                        fontSize: 21,
                                        letterSpacing: -0.3,
                                      ),
                                      children: const [
                                        TextSpan(
                                            text: 'Prime',
                                            style: TextStyle(
                                                color: _SidebarColors.cyan)),
                                        TextSpan(
                                            text: 'Fit',
                                            style: TextStyle(
                                                color: _SidebarColors.gold)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Member Portal'.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.8,
                                      color: _SidebarColors.inactiveText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: _SidebarColors.border),
                ],
              ),
            ),

            // ---------------- Navigation ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(32, 22, 20, 8),
              child: Text(
                'MY PORTAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                  color: _SidebarColors.mutedText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (int i = 0; i < sidebarItems.length; i++)
                    _SidebarTile(
                      data: sidebarItems[i],
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            const Spacer(),

            // ---------------- Member profile + Sign Out ----------------
            // Bordered dark card, like the "Restricted access" box on login.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _SidebarColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: _SidebarColors.cardBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1A1A1D),
                        border: Border.all(
                          color: _SidebarColors.cyan,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _initials(memberName),
                        style: const TextStyle(
                          color: _SidebarColors.cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            memberName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _TierBadge(tier: memberTier),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: _LogoutTile(onTap: onLogout),
            ),
          ],
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// The membership-tier chip in the profile card: a gold-tinted pill with a
/// thin gold border (no solid gold block).
class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _SidebarColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: _SidebarColors.gold.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Text(
        tier,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _SidebarColors.gold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A single sidebar nav row. Active = solid gold pill with black bold label
/// and icon; inactive = muted grey; hover = soft white wash with a gold icon.
class _SidebarTile extends StatefulWidget {
  final SidebarItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile(
      {required this.data, required this.selected, required this.onTap});

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;

    final Color rowBg = active
        ? _SidebarColors.gold
        : (_hovered ? _SidebarColors.hoverOverlay : Colors.transparent);
    final Color labelColor = active
        ? _SidebarColors.onGold
        : (_hovered ? Colors.white : _SidebarColors.inactiveText);
    final Color iconColor = active
        ? _SidebarColors.onGold
        : (_hovered ? _SidebarColors.gold : _SidebarColors.inactiveText);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Icon(widget.data.icon, size: 20, color: iconColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.data.label,
                        style: AppText.navItem(active: active, color: labelColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sign Out — an outlined pill, quiet by default; on hover the border,
/// label and icon turn soft red with a faint red wash, deeper while pressed.
class _LogoutTile extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _pressed;
    final Color rowBg = active
        ? _SidebarColors.redOverlay(_pressed ? 0.22 : 0.12)
        : Colors.transparent;
    final Color borderColor = active
        ? _SidebarColors.softRed.withValues(alpha: 0.45)
        : _SidebarColors.outline;
    final Color fgColor =
        active ? _SidebarColors.softRed : const Color(0xFFE4E4E7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            splashColor: _SidebarColors.redOverlay(0.18),
            highlightColor: _SidebarColors.redOverlay(0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 18, color: fgColor),
                  const SizedBox(width: 10),
                  Text('Sign Out', style: AppText.navItem(color: fgColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
