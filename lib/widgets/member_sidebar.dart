import 'package:flutter/material.dart';

/// PrimeFit brand palette — soft pastel cyan background (easier on the
/// eyes than the earlier neon shade). "PrimeFit" at the top is gold
/// (brand accent); every other text is white with a subtle drop shadow
/// so it still reads clearly against the lighter background. Icons stay
/// white. Hover/click just darken the row/chip — no border or dot marks
/// the active item.
class _SidebarColors {
  // Slightly lighter, softer teal-cyan — less neon/saturated than the
  // original bright turquoise, so it's easier on the eyes while text
  // still stays readable on top of it.
  static const Color cyan = Color(0xFF4FC7D4);

  // Gold — brand accent, used for the "PrimeFit" wordmark and the
  // membership tier badge.
  static const Color gold = Color(0xFFFFC400);
  static const Color goldText = Color(0xFF4A3600); // readable text on a gold chip

  // Text on the cyan background — white, bumped close to full opacity
  // so "Member Portal" / "MENU" stay clearly visible against the
  // lighter background.
  static const Color textPrimary = Color.fromARGB(255, 255, 255, 255);
  static const Color textSecondary = Color.fromARGB(249, 255, 255, 255); // white @ 95%
  static const Color textMuted = Color.fromARGB(246, 255, 255, 255); // white @ 88%

  // Icons keep their own white color.
  static const Color iconColor = Colors.white;

  // Darkening overlay for hover/active/click — black at some opacity,
  // layered over the flat cyan background/chips.
  static Color darken(double opacity) => Colors.black.withValues(alpha: opacity);

  // A soft dark shadow behind text so white stays readable even against
  // the lighter/pastel cyan — plain white alone was too close in
  // "lightness" to the background to pop clearly.
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
      color: _SidebarColors.cyan,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- Branding ----------------
            // "PrimeFit" is built as a plain Text here (not the
            // PrimeFitWordmark widget) so its color can be set directly
            // to gold, since that widget's internal styling isn't
            // editable from this file.
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
                      Text('PrimeFit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _SidebarColors.gold,
                            shadows: _SidebarColors.textShadow,
                          )),
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
                      child: Icon(widget.data.icon, size: 18, color: _SidebarColors.iconColor),
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

/// Logout row — same treatment: darkens on hover, darkens further on
/// click, no border/dot.
class _LogoutTile extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutTile({required this.onTap});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color rowBg = _SidebarColors.darken(_hovered ? 0.12 : 0);
    final Color chipBg = _SidebarColors.darken(_hovered ? 0.24 : 0.14);

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
            splashColor: _SidebarColors.darken(0.18),
            highlightColor: _SidebarColors.darken(0.12),
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
                    child: const Icon(Icons.logout, size: 16, color: _SidebarColors.iconColor),
                  ),
                  const SizedBox(width: 10),
                  const Text('Logout',
                      style: TextStyle(
                        color: _SidebarColors.textPrimary,
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
