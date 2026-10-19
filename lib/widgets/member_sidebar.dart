import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// PrimeFit member-portal sidebar, restyled to match the admin portal:
///  * dark gray rail (the same gray the dark-mode version used), in both
///    light and dark mode;
///  * logo + two-tone wordmark sit directly on the rail ("Prime" cyan,
///    "Fit" gold), no white chip;
///  * thin muted icons; the active item is a cyan-tinted pill with a cyan
///    border, and hovering gives a light cyan wash;
///  * the footer is a flat profile row with a quiet gold tier badge, with a
///    "Sign Out" row below it.
/// Menu items, their icons, the widget's constructor and the navigation
/// callbacks are unchanged.
class _SidebarColors {
  /// Brand cyan (same value the member dashboard uses for its accents).
  static const Color cyan = Color(0xFF18B7D9);

  static const Color gold = AppColors.gold; // wordmark "Fit", tier badge

  /// Hairline divider on the dark rail.
  static const Color divider = Color(0x14FFFFFF);

  /// Muted text on the dark rail (section label, subtitle).
  static const Color mutedText = Color(0x8CFFFFFF);

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
      width: 260,
      // Same dark gray the dark-mode version used, in both modes.
      color: AppColors.darkCard,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Branding ----------------
            // Tapping the logo/wordmark takes the member back to their
            // Dashboard (index 0), same as clicking a site's logo goes home.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onSelect(0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/primefit_logo.jpg',
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                style: GoogleFonts.archivoBlack(
                                  fontSize: 18,
                                  letterSpacing: -0.3,
                                ),
                                children: const [
                                  TextSpan(
                                      text: 'Prime',
                                      style: TextStyle(color: _SidebarColors.cyan)),
                                  TextSpan(
                                      text: 'Fit',
                                      style: TextStyle(color: _SidebarColors.gold)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Member Portal'.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: _SidebarColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---------------- Navigation ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(26, 18, 20, 8),
              child: Text(
                'MY PORTAL',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _SidebarColors.mutedText,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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

            const Divider(height: 1, color: _SidebarColors.divider),

            // ---------------- Member profile + Sign Out ----------------
            // Flat row on the rail (no filled card), quiet gold tier badge.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _SidebarColors.cyan.withValues(alpha: 0.18),
                      border: Border.all(
                        color: _SidebarColors.cyan.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      _initials(memberName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _TierBadge(tier: memberTier),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
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

/// The membership-tier chip in the sidebar footer: a quiet gold tint (no solid
/// gold block).
class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _SidebarColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
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

/// A single sidebar nav row. Active = cyan-tinted pill with a cyan border,
/// white label and cyan icon; inactive = muted white; hover = light cyan wash.
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
    const cyan = _SidebarColors.cyan;

    // Light cyan wash on hover; the active row is a bit stronger with a cyan
    // border so the two stay distinct.
    final Color rowBg = active
        ? cyan.withValues(alpha: 0.28)
        : (_hovered ? cyan.withValues(alpha: 0.20) : Colors.transparent);
    final Color borderColor = active
        ? cyan.withValues(alpha: 0.55)
        : (_hovered ? cyan.withValues(alpha: 0.30) : Colors.transparent);
    final Color labelColor =
        (active || _hovered) ? Colors.white : Colors.white.withValues(alpha: 0.72);
    final Color iconColor =
        (active || _hovered) ? cyan : Colors.white.withValues(alpha: 0.65);

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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Icon(widget.data.icon, size: 19, color: iconColor),
                    const SizedBox(width: 13),
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

/// Sign Out row — quiet by default; on hover the label/icon turn soft red
/// with a faint red wash, and a deeper wash while pressed.
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
    final Color fgColor =
        active ? _SidebarColors.softRed : Colors.white.withValues(alpha: 0.65);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            splashColor: _SidebarColors.redOverlay(0.18),
            highlightColor: _SidebarColors.redOverlay(0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: fgColor),
                  const SizedBox(width: 13),
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
