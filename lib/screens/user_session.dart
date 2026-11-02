/// Simple in-memory "session" that mimics a signed-in user's profile.
///
/// In a real app this would come from your auth/user API. For this
/// simulation, `CreateAccountPage` fills it in right after a successful
/// signup + payment, and `LoginPage` fills it in after a successful sign
/// in -- both read/verify data from your MySQL database via PHP APIs.
/// `ProfileSettingsPage` reads from (and can edit) it.
///
/// Being a plain singleton keeps this framework-agnostic — no provider /
/// riverpod / bloc setup required. If your app already has a state
/// management solution, feel free to swap this out for it later; every
/// other file just calls `UserSession.instance`.
class UserSession {
  UserSession._internal();
  static UserSession _instance = UserSession._internal();
  static UserSession get instance => _instance;
  static void reset() => _instance = UserSession._internal();

  String firstName = 'John';
  String lastName = 'Doe';
  String email = 'john.doe@example.com';
  String phone = '+1 (555) 987-6543';
  String dateOfBirth = '';
  // '' means "not set" -- expected values are 'Male' / 'Female' / 'Other'.
  String gender = '';
  String address = '';
  String membershipPlan = '7 Months';
  String membershipStatus = 'Active';
  String memberId = 'PF-2026-00000';
  DateTime memberSince = DateTime.now();
  int totalWorkouts = 0;
  int creditsTotal = 30;

  /// The real NextRenewalDate from the `Memberships` table, when known
  /// (set after registration/payment or after login). When this is null,
  /// `renewsOn` falls back to estimating from memberSince + plan length.
  DateTime? renewalDateOverride;

  /// The plan's price from the `Plans` table (e.g. 3500.00 for "7 Months").
  /// Null until we've fetched it from the database.
  double? planPrice;

  /// The real numeric MemberID (AUTO_INCREMENT PK) from the `Members`
  /// table. Needed for API calls like check-in that require the raw ID
  /// (as opposed to the formatted "PF-00004" display string).
  int? dbMemberId;

  /// Sessions used this membership period, from `Memberships.SessionsUsed`.
  int sessionsUsed = 0;

  /// Number of check-ins (visits) this week, tracked from the admin
  /// check-in system. Updated each time a check-in is recorded.
  int visitsThisWeek = 0;

  /// Dates of visits this week, used to accurately highlight
  /// which days the member has checked in on the week tracker.
  final List<DateTime> visitDates = [];

  /// Total gym visits ever (all-time), from AttendanceLogs.
  int totalSessions = 0;

  /// The signed, tamper-proof QR token from `Members.QRCodeData`.
  /// Empty until fetched from the database (after registration or login).
  String qrCodeData = '';

  /// The profile picture URL from `Members.ProfilePictureURL`.
  /// Empty until the member uploads one.
  String profilePictureUrl = '';

  /// Per-member notifications preference, loaded from shared_preferences
  /// (keyed by dbMemberId) by `MemberPortalScreen` once available. Gates
  /// `StatusAlertBanner`. Defaults true until loaded/toggled.
  bool notificationsEnabled = true;

  /// True once `MemberPortalScreen` has completed its one-time food/body-
  /// metrics reminder check for this session. Gates [needsFoodReminder]
  /// and [needsWeighInReminder] so they never fire on stale/default data
  /// before that check has actually run.
  bool remindersChecked = false;

  /// Whether the member has logged any food today, from the day's
  /// `FoodLogs`. Meaningless until [remindersChecked] is true.
  bool hasLoggedFoodToday = false;

  /// The `RecordedAt` date of the member's most recent `BodyMetrics`
  /// entry, or null if they've never logged one. Meaningless until
  /// [remindersChecked] is true.
  DateTime? lastBodyMetricDate;

  /// True when it's reasonably late in the day and the member still
  /// hasn't logged any food today -- past the point where a reminder
  /// stops feeling like nagging and starts being useful.
  bool get needsFoodReminder =>
      remindersChecked && !hasLoggedFoodToday && DateTime.now().hour >= 18;

  /// True once it's been 7+ days since the member's last weight/BMI
  /// entry (or they've never logged one at all).
  bool get needsWeighInReminder {
    if (!remindersChecked) return false;
    if (lastBodyMetricDate == null) return true;
    return DateTime.now().difference(lastBodyMetricDate!).inDays >= 7;
  }

  String get planPriceLabel {
    if (planPrice == null) return '—';
    // Simple thousands-separator formatting without needing the intl package.
    final wholeNumber = planPrice!.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < wholeNumber.length; i++) {
      if (i > 0 && (wholeNumber.length - i) % 3 == 0) buffer.write(',');
      buffer.write(wholeNumber[i]);
    }
    return '₱$buffer';
  }

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final a = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final b = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final result = ('$a$b').toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get memberSinceLabel =>
      '${_months[memberSince.month - 1]} ${memberSince.year}';

  /// Uses the real database renewal date when we have one; otherwise
  /// estimates it from memberSince + plan duration (used only as a
  /// fallback, e.g. if the API call to fetch it failed).
  DateTime get renewsOn =>
      renewalDateOverride ??
      _addMonths(memberSince, _monthsForPlan(membershipPlan));

  String get renewsOnLabel {
    final d = renewsOn;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// Days remaining until the membership renewal date. Negative means
  /// the renewal date has already passed.
  int get daysUntilRenewal => renewsOn.difference(DateTime.now()).inDays;

  /// True when the membership has lapsed -- either cancelled, or the
  /// renewal date has passed without a new payment being recorded.
  bool get isMembershipExpired =>
      membershipStatus == 'Cancelled' || daysUntilRenewal < 0;

  /// True when the membership is still active but renews within 7 days.
  bool get isMembershipExpiringSoon =>
      !isMembershipExpired && daysUntilRenewal <= 7;

  /// Fraction of session credits remaining this period (0.0 - 1.0).
  double get creditsRemainingPercent =>
      creditsTotal <= 0 ? 0.0 : (creditsTotal - sessionsUsed) / creditsTotal;

  /// True when 20% or less of this period's session credits remain.
  bool get isCreditsLow => creditsTotal > 0 && creditsRemainingPercent <= 0.20;

  /// Computes the current day streak based on [visitDates].
  /// Counts consecutive days (ending today) with at least one visit.
  int get dayStreak {
    if (visitDates.isEmpty) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final visitSet =
        visitDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    var streak = 0;
    var checkDate = todayDate;
    while (visitSet.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Count of visits in the current calendar month, computed from
  /// [visitDates]. Powers the Dashboard's "Monthly Attendance" stat tile.
  int get visitsThisMonth {
    final now = DateTime.now();
    return visitDates
        .where((d) => d.year == now.year && d.month == now.month)
        .length;
  }

  static const List<String> _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Real attendance grouped by month (last 6 calendar months,
  /// including the current one), computed from [visitDates].
  /// Powers the Progress page's "Monthly Attendance" chart.
  List<Map<String, Object>> get monthlyAttendance {
    final now = DateTime.now();
    final counts = <String, int>{};
    for (final d in visitDates) {
      final key = '${d.year}-${d.month}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final result = <Map<String, Object>>[];
    for (int i = 5; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      final key = '${target.year}-${target.month}';
      result.add({
        'month': _monthAbbr[target.month - 1],
        'sessions': (counts[key] ?? 0).toDouble(),
      });
    }
    return result;
  }

  /// Percentage of monthly session credits used.
  int get monthlyGoalPercent {
    if (creditsTotal <= 0) return 0;
    final pct = (sessionsUsed / creditsTotal) * 100;
    return pct.round().clamp(0, 100);
  }

  /// Returns a 7-element list representing the current week (Mon-Sun).
  /// Each element is `true` if the member visited on that day,
  /// `false` if the day has passed and they did NOT visit,
  /// `null` if the day has not yet occurred.
  List<bool?> get weekCheckins {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDates = <DateTime>[];
    for (var i = 0; i < 7; i++) {
      weekDates.add(monday.add(Duration(days: i)));
    }
    final visitSet =
        visitDates.map((d) => DateTime(d.year, d.month, d.day)).toSet();
    final result = <bool?>[];
    final today = DateTime(now.year, now.month, now.day);
    for (final wd in weekDates) {
      final wdDate = DateTime(wd.year, wd.month, wd.day);
      if (wdDate.isAfter(today)) {
        result.add(null);
      } else {
        result.add(visitSet.contains(wdDate));
      }
    }
    return result;
  }

  int _monthsForPlan(String plan) {
    switch (plan) {
      case '4 Months':
        return 4;
      case '5 Months':
        return 5;
      case '7 Months':
        return 7;
      case '1 Year':
        return 12;
      default:
        return 1;
    }
  }

  DateTime _addMonths(DateTime date, int months) {
    var newDate = DateTime(date.year, date.month + months, date.day);
    if (newDate.month != (date.month + months - 1) % 12 + 1) {
      return DateTime(date.year, date.month + months + 1, 0);
    }
    return newDate;
  }

  /// Populate the in-memory session from a server-verified member response.
  void applyMemberResponse(Map<String, dynamic> member) {
    final rawId = member['member_id'] ?? member['MemberID'];
    final id = int.tryParse('$rawId');
    if (id == null || id <= 0) throw const FormatException('Invalid member ID');
    final since = DateTime.tryParse('${member['member_since']}') ?? DateTime.now();
    final renewal = member['next_renewal_date'] == null
        ? null : DateTime.tryParse('${member['next_renewal_date']}');
    applySignup(
      firstName: member['first_name']?.toString() ?? '',
      lastName: member['last_name']?.toString() ?? '',
      email: member['email']?.toString() ?? '',
      phone: member['phone']?.toString() ?? '',
      membershipPlan: member['membership_plan']?.toString() ?? 'No active plan',
      membershipStatus: member['membership_status']?.toString() ?? 'Active',
      memberId: 'PF-${id.toString().padLeft(5, '0')}',
      memberSince: since,
      membershipRenewsOn: renewal,
      planPrice: double.tryParse('${member['plan_price']}'),
      dbMemberId: id,
      creditsTotal: int.tryParse('${member['session_credits']}') ?? 30,
      sessionsUsed: int.tryParse('${member['sessions_used']}') ?? 0,
      qrCodeData: (member['qr_code_data'] ?? member['QRCodeData'])?.toString() ?? '',
      profilePictureUrl: (member['profile_picture'] ?? member['ProfilePictureURL'])?.toString() ?? '',
    );
  }

  void applySignup({
    required String firstName,
    required String lastName,
    String middleInitial = '',
    required String email,
    required String phone,
    required String membershipPlan,
    required String memberId,
    required DateTime memberSince,
    int creditsTotal = 30,
    String membershipStatus = 'Active',
    DateTime? membershipRenewsOn,
    double? planPrice,
    int? dbMemberId,
    int sessionsUsed = 0,
    int visitsThisWeek = 0,
    List<DateTime>? visitDates,
    String qrCodeData = '',
    String profilePictureUrl = '',
  }) {
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    this.phone = phone;
    this.membershipPlan = membershipPlan;
    this.membershipStatus = membershipStatus;
    this.memberId = memberId;
    this.memberSince = memberSince;
    this.creditsTotal = creditsTotal;
    renewalDateOverride = membershipRenewsOn;
    this.planPrice = planPrice;
    this.dbMemberId = dbMemberId;
    this.sessionsUsed = sessionsUsed;
    this.visitsThisWeek = visitsThisWeek;
    if (visitDates != null) {
      this.visitDates.clear();
      this.visitDates.addAll(visitDates);
    }
    this.qrCodeData = qrCodeData;
    this.profilePictureUrl = profilePictureUrl;
    totalWorkouts = 0;
  }

  void updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String dateOfBirth,
    String gender = '',
    required String address,
  }) {
    this.firstName = firstName;
    this.lastName = lastName;
    this.email = email;
    this.phone = phone;
    this.dateOfBirth = dateOfBirth;
    this.gender = gender;
    this.address = address;
  }

  /// Age in whole years, computed from [dateOfBirth]. Accepts either
  /// "YYYY-MM-DD" (MySQL/API format) or "MM/DD/YYYY" (this app's Profile
  /// Settings UI format) since callers have stored either historically.
  /// Null when no date of birth is on file yet, or it can't be parsed.
  int? get age {
    final dob = _parseDob(dateOfBirth);
    if (dob == null) return null;
    final now = DateTime.now();
    int years = now.year - dob.year;
    final hadBirthdayThisYear =
        (now.month > dob.month) || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthdayThisYear) years--;
    return years;
  }

  static DateTime? _parseDob(String raw) {
    if (raw.isEmpty) return null;
    try {
      return DateTime.parse(raw); // "YYYY-MM-DD"
    } catch (_) {
      // fall through to MM/DD/YYYY
    }
    final parts = raw.split('/');
    if (parts.length == 3) {
      final m = int.tryParse(parts[0]);
      final d = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (m != null && d != null && y != null) {
        try {
          return DateTime(y, m, d);
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }
}
