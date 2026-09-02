import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'user_session.dart';
// 👇 Connects this screen to your PHP profile APIs
// (profile_api.php and upload_profile_picture.php). Adjust the paths
// if these service files live somewhere else.
import '../services/profile_service.dart';
import '../services/profile_picture_service.dart';
import '../services/notification_prefs_service.dart';
import '../theme/theme_controller.dart';
import '../theme/app_theme.dart';

/// Profile Settings screen.
///
/// Reads from `UserSession.instance` first (for an instant, no-lag
/// display), then fetches the real up-to-date profile from
/// `profile_api.php` in the background and refreshes the fields once
/// it arrives. Saving calls `profile_api.php` to persist changes to the
/// `Members` table, then updates `UserSession` so the rest of the app
/// (sidebar, dashboard, etc.) reflects the change immediately.
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _dark = false;

  Color get cyan => _dark ? const Color(0xFF4DD8EF) : const Color(0xFF22B8D8);
  Color get bgGrey => _dark ? AppColors.darkBg : AppColors.portalPageBg;
  Color get cardBg => _dark ? AppColors.darkCard : Colors.white;
  List<BoxShadow> get cardShadow => _dark ? const [] : AppColors.softCardShadow;
  Color get fieldFill => _dark ? AppColors.darkBg : Colors.white;
  Color get textDark => _dark ? Colors.white : const Color(0xFF1A1A1A);
  Color get textGrey => _dark ? AppColors.textMutedOnDark : const Color(0xFF6B7280);
  Color get borderGrey => _dark ? AppColors.darkBorder : const Color(0xFFE1E4E8);
  Color get hintColor => _dark ? AppColors.textMutedOnDark : const Color(0xFFB0B4BA);

  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _addressCtrl;

  bool _saving = false;
  bool _uploadingPhoto = false;
  String _profilePictureUrl = '';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    final session = UserSession.instance;
    _firstNameCtrl = TextEditingController(text: session.firstName);
    _lastNameCtrl = TextEditingController(text: session.lastName);
    _emailCtrl = TextEditingController(text: session.email);
    _phoneCtrl = TextEditingController(text: session.phone);
    _dobCtrl = TextEditingController(text: session.dateOfBirth);
    _addressCtrl = TextEditingController(text: session.address);
    _profilePictureUrl = session.profilePictureUrl;
    _loadProfile();
    _loadNotificationPref();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final result = await ProfileService.fetchProfile(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['profile'] is Map) {
      final profile = result['profile'] as Map<String, dynamic>;

      // Convert "YYYY-MM-DD" (from MySQL) to "MM/DD/YYYY" (for the UI field).
      String dobDisplay = '';
      final dobRaw = profile['DateOfBirth'];
      if (dobRaw != null) {
        try {
          final d = DateTime.parse(dobRaw.toString());
          dobDisplay = '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}/${d.year}';
        } catch (_) {
          dobDisplay = '';
        }
      }

      setState(() {
        _firstNameCtrl.text = profile['FirstName']?.toString() ?? _firstNameCtrl.text;
        _lastNameCtrl.text = profile['LastName']?.toString() ?? _lastNameCtrl.text;
        _emailCtrl.text = profile['Email']?.toString() ?? _emailCtrl.text;
        _phoneCtrl.text = profile['Phone']?.toString() ?? '';
        _dobCtrl.text = dobDisplay;
        _addressCtrl.text = profile['Address']?.toString() ?? '';
        _profilePictureUrl = profile['ProfilePictureURL']?.toString() ?? '';
        final qrData = profile['QRCodeData']?.toString() ?? '';
        if (qrData.isNotEmpty) {
          UserSession.instance.qrCodeData = qrData;
        }
      });
      UserSession.instance.profilePictureUrl = _profilePictureUrl;
    }
  }

  Future<void> _loadNotificationPref() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final enabled = await NotificationPrefsService.isEnabled(memberId);
    if (!mounted) return;

    setState(() => _notificationsEnabled = enabled);
  }

  Future<void> _handleNotificationsToggle(bool value) async {
    setState(() => _notificationsEnabled = value);
    UserSession.instance.notificationsEnabled = value;

    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;
    await NotificationPrefsService.setEnabled(memberId, value);
  }

  Future<void> _pickDateOfBirth() async {
    DateTime initial = DateTime(1995, 1, 1);
    final parts = _dobCtrl.text.split('/');
    if (parts.length == 3) {
      final m = int.tryParse(parts[0]);
      final d = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (m != null && d != null && y != null) initial = DateTime(y, m, d);
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: cyan)),
        child: child!,
      ),
    );
    if (picked != null) {
      final mm = picked.month.toString().padLeft(2, '0');
      final dd = picked.day.toString().padLeft(2, '0');
      setState(() => _dobCtrl.text = '$mm/$dd/${picked.year}');
    }
  }

  Future<void> _handleSaveChanges() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('First name, last name, and email are required.')));
      return;
    }

    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Member session not found. Please log in again.')));
      return;
    }

    setState(() => _saving = true);

    // Convert "MM/DD/YYYY" (UI format) to "YYYY-MM-DD" (MySQL DATE format).
    String dobForApi = '';
    final parts = _dobCtrl.text.trim().split('/');
    if (parts.length == 3) {
      final mm = parts[0].padLeft(2, '0');
      final dd = parts[1].padLeft(2, '0');
      final yyyy = parts[2];
      dobForApi = '$yyyy-$mm-$dd';
    }

    final result = await ProfileService.updateProfile(
      memberId: memberId,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      dateOfBirth: dobForApi,
      address: _addressCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (result['success'] == true) {
      UserSession.instance.updatePersonalInfo(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      setState(() {}); // refreshes the avatar initials / any derived labels
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Could not update profile.')));
    }
  }

  Future<void> _handleUploadPhoto() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Member session not found. Please log in again.')));
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return; // user cancelled

    final Uint8List bytes = await picked.readAsBytes();

    setState(() => _uploadingPhoto = true);

    final result = await ProfilePictureService.upload(
      memberId: memberId,
      bytes: bytes,
      filename: picked.name,
    );

    if (!mounted) return;

    setState(() => _uploadingPhoto = false);

    if (result['success'] == true) {
      final url = result['url']?.toString() ?? '';
      setState(() => _profilePictureUrl = url);
      UserSession.instance.profilePictureUrl = url;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Profile picture updated.')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Upload failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    _dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bgGrey,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Settings', style: AppText.pageTitle(size: 30, color: textDark)),
                const SizedBox(height: 6),
                Text('Manage your personal information and preferences',
                    style: TextStyle(color: textGrey, fontSize: 15)),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 760;
                    final personalInfoCard = _card(
                        accent: AppColors.accentCyan,
                        child: _buildPersonalInformation());
                    final sideColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _card(
                            accent: AppColors.accentCyan,
                            child: _buildProfilePicture()),
                        const SizedBox(height: 24),
                        _card(
                            accent: AppColors.accentGold,
                            child: _buildQuickStats()),
                        const SizedBox(height: 24),
                        _card(child: _buildSecurity()),
                        const SizedBox(height: 24),
                        _card(
                            accent: AppColors.accentViolet,
                            child: _buildPreferences()),
                      ],
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: personalInfoCard),
                          const SizedBox(width: 24),
                          SizedBox(width: 300, child: sideColumn),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        personalInfoCard,
                        const SizedBox(height: 24),
                        sideColumn,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? accent}) {
    final tinted = accent != null && !_dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tinted ? AppColors.cardTint(accent) : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: tinted ? AppColors.cardTintBorder(accent) : borderGrey),
        boxShadow: cardShadow,
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: cyan, size: 20),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
      ],
    );
  }

  // ==================== PERSONAL INFORMATION ====================

  Widget _buildPersonalInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.person_outline, 'Personal Information'),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field(label: 'First Name', controller: _firstNameCtrl)),
            const SizedBox(width: 16),
            Expanded(child: _field(label: 'Last Name', controller: _lastNameCtrl)),
          ],
        ),
        _field(label: 'Email', controller: _emailCtrl, keyboardType: TextInputType.emailAddress),
        _field(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
        _field(
          label: 'Date of Birth',
          controller: _dobCtrl,
          hint: 'MM/DD/YYYY',
          readOnly: true,
          onTap: _pickDateOfBirth,
          suffixIcon: Icons.calendar_today_outlined,
        ),
        _field(
          label: 'Address',
          controller: _addressCtrl,
          hint: 'Street, City, State, ZIP',
          maxLines: 3,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton(
            onPressed: _saving ? null : _handleSaveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: cyan,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(_saving ? 'Saving…' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: textDark)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 14.5, color: textDark),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor),
              filled: true,
              fillColor: fieldFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 19, color: textGrey) : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderGrey)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderGrey)),
              focusedBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cyan, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PROFILE PICTURE ====================

  Widget _buildProfilePicture() {
    final session = UserSession.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Profile Picture', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cyan,
                  image: _profilePictureUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(_profilePictureUrl), fit: BoxFit.cover)
                      : null,
                ),
                alignment: Alignment.center,
                child: _uploadingPhoto
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                    : (_profilePictureUrl.isEmpty
                        ? Text(
                            session.initials,
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                          )
                        : null),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _uploadingPhoto ? null : _handleUploadPhoto,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderGrey),
                  foregroundColor: textDark,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(_uploadingPhoto ? 'Uploading…' : 'Upload Photo',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== QUICK STATS ====================

  Widget _buildQuickStats() {
    final session = UserSession.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Stats', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textDark)),
        const SizedBox(height: 18),
        _statRow(Icons.calendar_today_outlined, 'Member Since', session.memberSinceLabel),
        const SizedBox(height: 16),
        _statRow(Icons.track_changes_outlined, 'Total Workouts', '${session.totalWorkouts} sessions'),
        const SizedBox(height: 16),
        _statRow(Icons.person_outline, 'Membership', session.membershipPlan),
      ],
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _dark
                ? cyan.withValues(alpha: 0.16)
                : AppColors.cyanTint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFF0E7490)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: textGrey, fontSize: 12.5)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  // ==================== SECURITY ====================

  Widget _buildSecurity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.shield_outlined, 'Security'),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Change password flow not wired up yet.')));
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: borderGrey),
              foregroundColor: textDark,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Logged out (simulated).')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 13)),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          ),
        ),
      ],
    );
  }

  // ==================== PREFERENCES ====================

  Widget _buildPreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.tune, 'Preferences'),
        const SizedBox(height: 18),
        ListenableBuilder(
          listenable: ThemeController.instance,
          builder: (context, _) => _preferenceSwitchRow(
            label: 'Dark Mode',
            subtitle: 'Switch the app to a darker color theme',
            value: ThemeController.instance.isDark,
            onChanged: (v) => ThemeController.instance.setDarkMode(v),
          ),
        ),
        const SizedBox(height: 16),
        _preferenceSwitchRow(
          label: 'Notifications',
          subtitle: 'Show membership and reminder alerts',
          value: _notificationsEnabled,
          onChanged: _handleNotificationsToggle,
        ),
      ],
    );
  }

  Widget _preferenceSwitchRow({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: textDark)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: textGrey, fontSize: 12.5)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: Colors.white,
          activeTrackColor: cyan,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
