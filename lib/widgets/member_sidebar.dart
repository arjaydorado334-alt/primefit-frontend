import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// PrimeFit member-portal sidebar. Dark (near-black) surface keeping the
/// brand cyan/gold accents. The active nav item is a soft cyan-tinted pill
/// with a short left accent bar; inactive items are plain and lighten on
/// hover. Menu items, their icons, and their navigation targets are
/// unchanged from before.
class _SidebarColors {
  // Near-black surface (matches the app's canonical dark background).
  static const Color background = AppColors.darkBg;

  // Gold — brand accent, used for the membership tier badge and the
  // "Fit" half of the PrimeFit wordmark.
  static const Color gold = AppColors.yellow;
  static const Color goldText = Color(0xFF3A2B00); // readable on a gold chip

  // Cyan — brand accent, used for the menu icons and the "Prime" half
  // of the PrimeFit wordmark.
  static const Color cyan = AppColors.cyan;

  // Red — used for the Logout row's hover/pressed state.
  static const Color red = Color(0xFFEF4444);
  static Color redOverlay(double opacity) => red.withValues(alpha: opacity);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB6BAC2);
  static const Color textMuted = Color(0xFF7A7F8A);
  static const Color iconInactive = Color(0xFF9CA3AF);

  static const Color divider = Color(0x14FFFFFF);

  // Soft cyan wash behind the active item; white wash for hover.
  static Color activeWash(double alpha) => cyan.withValues(alpha: alpha);
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
            // ---------------- Branding ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/primefit_logo.jpg',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          // Same face as the Login page's PrimeFit wordmark.
                          style: GoogleFonts.archivoBlack(
                            fontSize: 16,
                            letterSpacing: -0.3,
                          ),
                          children: const [
                            TextSpan(text: 'Prime', style: TextStyle(color: _SidebarColors.cyan)),
                            TextSpan(text: 'Fit', style: TextStyle(color: _SidebarColors.gold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('Member Portal',
                          style: TextStyle(
                            fontSize: 11,
                            color: _SidebarColors.textMuted,
                            letterSpacing: 0.2,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _SidebarColors.divider),
            const SizedBox(height: 18),

            // ---------------- Navigation ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Text(
                'MENU',
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

            // ---------------- Member profile + Logout ----------------
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _SidebarColors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _SidebarColors.hoverWash(0.08),
                          border: Border.all(color: _SidebarColors.hoverWash(0.12)),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_outline,
                            color: _SidebarColors.textPrimary, size: 18),
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
                  const SizedBox(height: 14),
                  _LogoutTile(onTap: onLogout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

/// A single sidebar nav row. Active = soft cyan pill + short left accent
/// bar + cyan icon; inactive = plain, lightening a touch on hover.
class _SidebarTile extends StatefulWidget {
  final SidebarItemData data;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.data, required this.selected, required this.onTap});

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final Color rowBg = selected
        ? _SidebarColors.activeWash(0.14)
        : (_hovered ? _SidebarColors.hoverWash(0.06) : Colors.transparent);
    final Color iconColor =
        selected ? _SidebarColors.cyan : _SidebarColors.iconInactive;
    final Color labelColor = selected
        ? _SidebarColors.textPrimary
        : (_hovered ? _SidebarColors.textPrimary : _SidebarColors.textSecondary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
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
              splashColor: _SidebarColors.activeWash(0.10),
              highlightColor: _SidebarColors.activeWash(0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        color: selected ? _SidebarColors.cyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Icon(widget.data.icon, size: 20, color: iconColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.data.label,
                        style: TextStyle(
                          color: labelColor,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
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

/// Logout row — turns red on hover, and a deeper red while pressed.
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
        ? _SidebarColors.redOverlay(_pressed ? 0.24 : 0.13)
        : Colors.transparent;
    final Color fgColor =
        active ? _SidebarColors.red : _SidebarColors.textSecondary;

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.logout, size: 20, color: fgColor),
                  const SizedBox(width: 12),
                  Text('Logout',
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
