import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// PrimeFit member-portal sidebar. A single flat cyan fill (no gradient),
/// mirroring the PrimeFit Admin app:
///  * brand lock-up sits on a white chip so the two-tone "PrimeFit"
///    wordmark ("Prime" dark, "Fit" gold) stays legible;
///  * nav icons are gold on every state;
///  * the active item is a solid white rounded pill with dark text and a
///    trailing chevron; inactive items are high-contrast white text on the
///    cyan, lifting to a faint white overlay on hover;
///  * the footer user card sits on a deeper-teal panel with a "Sign Out"
///    row below it.
/// Menu items, their icons, and their navigation targets are unchanged.
class _SidebarColors {
  static const Color background = AppColors.sidebarFill;
  static const Color footerPanel = AppColors.sidebarFooter;

  static const Color gold = AppColors.gold; // wordmark "Fit"
  static const Color goldText = AppColors.dark;

  static const Color navIcon = AppColors.goldOnCyan; // gold on cyan (inactive)
  static const Color navIconActive = AppColors.goldPillIcon; // gold on white pill

  static const Color activeText = AppColors.dark;

  static const Color red = Color(0xFFEF4444);
  static Color redOverlay(double opacity) => red.withValues(alpha: opacity);

  static const Color textPrimary = Colors.white;
  static const Color textInactive = Color(0xFFEAF7FB); // hi-contrast on cyan
  static const Color textMuted = Color(0xFFC7E7F0); // subtitle / section label

  static Color hoverWash(double alpha) => Colors.white.withValues(alpha: alpha);
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
      color: _SidebarColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Branding (white chip) ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.softCardShadow,
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/primefit_logo.jpg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            style: GoogleFonts.archivoBlack(
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                            children: const [
                              TextSpan(text: 'Prime', style: TextStyle(color: AppColors.darkGray)),
                              TextSpan(text: 'Fit', style: TextStyle(color: _SidebarColors.gold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('Member Portal',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.2,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- Navigation ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 6, 20, 10),
              child: Text(
                'MY PORTAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: _SidebarColors.textMuted,
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

            // ---------------- Member profile + Sign Out ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _SidebarColors.footerPanel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _SidebarColors.hoverWash(0.08)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _SidebarColors.hoverWash(0.16),
                            border: Border.all(color: _SidebarColors.hoverWash(0.20)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _initials(memberName),
                            style: const TextStyle(
                              color: _SidebarColors.textPrimary,
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
                              Text(memberName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: _SidebarColors.textPrimary,
                                  )),
                              const SizedBox(height: 4),
                              _TierBadge(tier: memberTier),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  _LogoutTile(onTap: onLogout),
                ],
              ),
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

/// The gold membership-tier chip in the sidebar footer.
class _TierBadge extends StatelessWidget {
  final String tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _SidebarColors.gold,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        tier,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _SidebarColors.goldText,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// A single sidebar nav row. Active = solid white pill + dark text + a
/// trailing chevron + dark-gold icon; inactive = gold icon + high-contrast
/// white label on the cyan, lifting to a faint white overlay on hover.
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
    final selected = widget.selected;

    final Color rowBg = selected
        ? Colors.white
        : (_hovered ? _SidebarColors.hoverWash(0.12) : Colors.transparent);
    final Color iconColor =
        selected ? _SidebarColors.navIconActive : _SidebarColors.navIcon;
    final Color labelColor =
        selected ? _SidebarColors.activeText : _SidebarColors.textInactive;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? AppColors.softCardShadow : const [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onTap,
              splashColor: _SidebarColors.hoverWash(0.12),
              highlightColor: _SidebarColors.hoverWash(0.08),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Icon(widget.data.icon, size: 20, color: iconColor),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        widget.data.label,
                        style: AppText.navItem(active: selected, color: labelColor),
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.chevron_right,
                          size: 18, color: _SidebarColors.activeText),
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

/// Sign Out row — turns red on hover, and a deeper red while pressed.
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
        ? _SidebarColors.redOverlay(_pressed ? 0.26 : 0.15)
        : Colors.transparent;
    final Color fgColor =
        active ? Colors.white : _SidebarColors.textInactive;

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
            splashColor: _SidebarColors.redOverlay(0.22),
            highlightColor: _SidebarColors.redOverlay(0.16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: fgColor),
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
