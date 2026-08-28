import 'package:flutter/material.dart';

/// PrimeFit brand palette — black background, all text white. "PrimeFit"
/// and "Member Portal" are white; icons stay white. Hover/click lighten
/// the row/chip (since darkening black would be invisible) — no border
/// or dot marks the active item.
class _SidebarColors {
  // Flat black background.
  static const Color background = Color(0xFF000000);

  // Gold — brand accent, used for the membership tier badge and the
  // "Fit" half of the PrimeFit wordmark.
  static const Color gold = Color(0xFFFFC400);
  static const Color goldText = Color(0xFF4A3600); // readable text on a gold chip

  // Cyan — brand accent, used for the menu icons and the "Prime" half
  // of the PrimeFit wordmark.
  static const Color cyan = Color(0xFF22D3EE);

  // Red — used for the Logout row's hover/pressed state.
  static const Color red = Color(0xFFEF4444);
  static Color redOverlay(double opacity) => red.withValues(alpha: opacity);

  // All sidebar text is white.
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white;
  static const Color textMuted = Colors.white;

  // Icons keep their own white color.
  static const Color iconColor = Colors.white;

  // Lightening overlay for hover/active/click — white at some opacity,
  // layered over the flat black background/chips (darkening black would
  // be invisible).
  static Color darken(double opacity) => Colors.white.withValues(alpha: opacity);

  static const List<Shadow> textShadow = [
    Shadow(color: Color(0x59000000), blurRadius: 3, offset: Offset(0, 1)),
  ];
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
      // Flat single shade — no gradient.
      color: _SidebarColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Branding ----------------
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/primefit_logo.jpg',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            shadows: _SidebarColors.textShadow,
                          ),
                          children: [
                            TextSpan(text: 'Prime', style: TextStyle(color: _SidebarColors.cyan)),
                            TextSpan(text: 'Fit', style: TextStyle(color: _SidebarColors.gold)),
                          ],
                        ),
                      ),
                      Text('Member Portal',
                          style: TextStyle(
                            fontSize: 11,
                            color: _SidebarColors.textSecondary,
                            shadows: _SidebarColors.textShadow,
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: _SidebarColors.darken(0.15)),
            const SizedBox(height: 12),

            // ---------------- Navigation ----------------
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: _SidebarColors.textMuted,
                  shadows: _SidebarColors.textShadow,
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _SidebarColors.darken(0.15))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: _SidebarColors.darken(0.12),
                        child: const Icon(Icons.person, color: _SidebarColors.iconColor, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(memberName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _SidebarColors.textPrimary,
                                  shadows: _SidebarColors.textShadow,
                                )),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _SidebarColors.gold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                memberTier,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: _SidebarColors.goldText,
                                ),
                              ),
                            ),
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

/// A single sidebar nav row. No border/dot — the active item is shown
/// purely by staying darker than the rest. Hover darkens it a bit more,
/// and clicking (via the InkWell splash) darkens it further still.
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

    // Darkening builds up: selected adds a base darken, hover adds a
    // bit more on top of whatever state it's already in. Click darkens
    // further still via the InkWell's splash/highlight colors below.
    double overlay = 0;
    if (selected) overlay += 0.16;
    if (_hovered) overlay += 0.10;

    final Color rowBg = _SidebarColors.darken(overlay);
    final Color chipBg = _SidebarColors.darken(0.14 + overlay);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: widget.onTap,
              splashColor: _SidebarColors.darken(0.18),
              highlightColor: _SidebarColors.darken(0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      alignment: Alignment.center,
                      child: Icon(widget.data.icon, size: 18, color: _SidebarColors.cyan),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.data.label,
                        style: const TextStyle(
                          color: _SidebarColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          shadows: _SidebarColors.textShadow,
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
        ? _SidebarColors.redOverlay(_pressed ? 0.30 : 0.16)
        : _SidebarColors.darken(0);
    final Color chipBg = active
        ? _SidebarColors.redOverlay(_pressed ? 0.55 : 0.35)
        : _SidebarColors.darken(0.14);
    final Color fgColor = active ? _SidebarColors.red : _SidebarColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: rowBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: widget.onTap,
            onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
            splashColor: _SidebarColors.redOverlay(0.30),
            highlightColor: _SidebarColors.redOverlay(0.20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.logout, size: 16, color: fgColor),
                  ),
                  const SizedBox(width: 10),
                  Text('Logout',
                      style: TextStyle(
                        color: fgColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        shadows: _SidebarColors.textShadow,
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
