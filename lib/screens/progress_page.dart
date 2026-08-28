import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// 👇 Connects this screen to your PHP personal records API
// (personal_records_api.php). Adjust the path if
// personal_records_service.dart lives somewhere else.
import '../services/personal_records_service.dart';
import '../services/body_photos_service.dart';
import '../services/monthly_goals_service.dart';
import '../services/body_metrics_service.dart';
import '../services/food_logs_service.dart';
import '../services/food_search_service.dart';
import '../services/user_targets_service.dart';
import '../theme/app_theme.dart';
import 'user_session.dart';

// ---------------------------------------------------------------------------
// Design tokens
// ---------------------------------------------------------------------------

/// Dark-mode-aware token set. Call `_Colors.sync(context)` once at the top
/// of a build() method before reading any of these -- surface tokens
/// (bg/cardBorder/text*) swap for dark equivalents; brand/status colors
/// (cyan, amber, purple, pink, emerald, red) stay identical in both themes
/// since they already read fine on light and dark backgrounds alike.
class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) => _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get bg => _dark ? AppColors.darkBg : const Color(0xFFF8FAFC); // slate-50
  static Color get surface => _dark ? AppColors.darkCard : Colors.white;
  static Color get subtleBg => _dark ? AppColors.darkBorder : const Color(0xFFF1F5F9); // slate-100
  static Color get cardBorder => _dark ? AppColors.darkBorder : const Color(0xFFE2E8F0); // slate-200
  static Color get textPrimary => _dark ? Colors.white : const Color(0xFF0F172A); // slate-900
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : const Color(0xFF64748B); // slate-500
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : const Color(0xFF94A3B8); // slate-400
  static Color get iconMuted => _dark ? AppColors.textMutedOnDark : const Color(0xFFCBD5E1); // slate-300

  static const cyan = Color(0xFF06B6D4); // cyan-500
  static Color get cyanLight =>
      _dark ? cyan.withValues(alpha: 0.15) : const Color(0xFFECFEFF); // cyan-50
  static Color get cyanBorder =>
      _dark ? cyan.withValues(alpha: 0.3) : const Color(0xFFCFFAFE); // cyan-100
  static const cyanText = Color(0xFF0E7490); // cyan-700

  static const amber = Color(0xFFFBBF24); // amber-400
  static const purple = Color(0xFF8B5CF6); // purple-500
  static const pink = Color(0xFFEC4899); // pink-500
  static const emerald = Color(0xFF059669); // emerald-600
  static const red = Color(0xFFEF4444);
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class PersonalRecord {
  /// The real PRID from the `PersonalRecords` table. Null only for a
  /// record that hasn't finished saving to the database yet.
  final int? prId;
  final String exercise;
  final String muscle;
  final int weight;
  final int sets;
  final int reps;
  final DateTime date;

  PersonalRecord({
    this.prId,
    required this.exercise,
    required this.muscle,
    required this.weight,
    required this.sets,
    required this.reps,
    required this.date,
  });
}

class ProgressPhoto {
  /// The real PhotoID from the `BodyPhotos` table. Null only for a
  /// photo that hasn't finished uploading yet.
  final int? photoId;

  /// The server URL where the photo is stored (from `BodyPhotos.PhotoURL`).
  final String url;
  final DateTime date;
  final String insight;

  ProgressPhoto({
    this.photoId,
    required this.url,
    required this.date,
    required this.insight,
  });
}

class BodyMetric {
  /// The real MetricID from the `BodyMetrics` table. Null only for an
  /// entry that hasn't finished saving to the database yet.
  final int? metricId;
  final double weight;
  final double height;
  final double bmi;
  final DateTime date;

  BodyMetric({
    this.metricId,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.date,
  });

  String get category {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

class FoodLogEntry {
  /// The real LogID from the `FoodLogs` table. Null only for an entry
  /// that hasn't finished saving to the database yet.
  final int? logId;
  final String foodName;
  final String mealType;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime date;

  FoodLogEntry({
    this.logId,
    required this.foodName,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.date,
  });
}

class UserTargets {
  /// Null fields mean the member hasn't set that target yet -- the
  /// `UserTargets` row may not even exist server-side.
  final int? calorieTarget;
  final double? proteinTarget;
  final double? carbsTarget;
  final double? fatsTarget;
  final double? targetWeight;

  const UserTargets({
    this.calorieTarget,
    this.proteinTarget,
    this.carbsTarget,
    this.fatsTarget,
    this.targetWeight,
  });

  bool get hasAnyTarget =>
      calorieTarget != null ||
      proteinTarget != null ||
      carbsTarget != null ||
      fatsTarget != null ||
      targetWeight != null;
}

/// A single USDA food-search result. Transient autocomplete data --
/// not persisted, so unlike the other models it carries no server id.
class FoodSearchResult {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;

  const FoodSearchResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
  });
}

const List<String> kMuscles = [
  'Chest',
  'Back',
  'Shoulders',
  'Biceps',
  'Triceps',
  'Legs',
  'Core',
  'Glutes',
];

const List<String> kMealTypes = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Snack',
];

const List<Map<String, Object>> kAttendance = [
  {'month': 'Jan', 'sessions': 11.5},
  {'month': 'Feb', 'sessions': 15.5},
  {'month': 'Mar', 'sessions': 13.5},
  {'month': 'Apr', 'sessions': 18.0},
  {'month': 'May', 'sessions': 15.5},
  {'month': 'Jun', 'sessions': 10.0},
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProgressTrackerPage extends StatefulWidget {
  const ProgressTrackerPage({super.key});

  @override
  State<ProgressTrackerPage> createState() => _ProgressTrackerPageState();
}

class _ProgressTrackerPageState extends State<ProgressTrackerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<PersonalRecord> _prs = [];
  bool _loadingPrs = true;

  final List<ProgressPhoto> _photos = [];
  bool _loadingPhotos = true;

  List<BodyMetric> _bodyMetrics = [];
  bool _loadingBodyMetrics = true;

  List<FoodLogEntry> _foodLogs = [];
  bool _loadingFoodLogs = true;
  DateTime _selectedFoodLogDate = DateTime.now();

  // Calories logged today, tracked separately from `_foodLogs` because
  // that list follows whatever date the Food Log tab is browsing, not
  // necessarily today -- Overview always needs today's total regardless.
  int _todayCalories = 0;

  int _goalTarget = 20;
  int _goalCompleted = 0;

  UserTargets _targets = const UserTargets();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadRecords();
    _loadBodyPhotos();
    _loadMonthlyGoal();
    _loadBodyMetrics();
    _loadFoodLogs();
    _loadTargets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final memberId = UserSession.instance.dbMemberId;
    debugPrint('🔍 UserSession.instance.dbMemberId = $memberId');
    debugPrint(
        '🔍 UserSession.instance.memberId (display) = ${UserSession.instance.memberId}');
    debugPrint(
        '🔍 UserSession.instance.firstName = ${UserSession.instance.firstName}');
    if (memberId == null) {
      setState(() => _loadingPrs = false);
      return;
    }

    final result = await PersonalRecordsService.fetchRecords(memberId);

    if (!mounted) return;

    if (result['success'] == true && result['records'] is List) {
      setState(() {
        _prs = (result['records'] as List).map((r) {
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(r['Date'].toString());
          } catch (_) {
            parsedDate = DateTime.now();
          }
          return PersonalRecord(
            prId: int.tryParse('${r['PRID']}'),
            exercise: r['Exercise']?.toString() ?? '',
            muscle: r['Muscle']?.toString() ?? '',
            // Weight comes from a DECIMAL column, so the API may return
            // it as "40.00" -- int.tryParse() alone can't handle the
            // decimal point, so we parse as double first, then round.
            weight: int.tryParse('${r['Weight']}') ??
                (double.tryParse('${r['Weight']}')?.round() ?? 0),
            sets: int.tryParse('${r['Sets']}') ?? 0,
            reps: int.tryParse('${r['Reps']}') ?? 0,
            date: parsedDate,
          );
        }).toList();
        _loadingPrs = false;
      });
    } else {
      setState(() => _loadingPrs = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  // -- PR actions -------------------------------------------------------

  Future<void> _openLogPrDialog() async {
    String muscle = kMuscles.first;
    final exerciseCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final setsCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> handleSave() async {
              if (exerciseCtrl.text.trim().isEmpty) return;

              final memberId = UserSession.instance.dbMemberId;
              if (memberId == null) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Member session not found. Please log in again.')),
                  );
                }
                return;
              }

              setDialogState(() => saving = true);

              final weight = int.tryParse(weightCtrl.text) ?? 0;
              final sets = int.tryParse(setsCtrl.text) ?? 0;
              final reps = int.tryParse(repsCtrl.text) ?? 0;

              final result = await PersonalRecordsService.addRecord(
                memberId: memberId,
                exercise: exerciseCtrl.text.trim(),
                muscle: muscle,
                weight: weight,
                sets: sets,
                reps: reps,
              );

              if (!ctx.mounted) return;

              if (result['success'] == true) {
                setState(() {
                  _prs.insert(
                    0,
                    PersonalRecord(
                      prId: int.tryParse('${result['pr_id']}'),
                      exercise: exerciseCtrl.text.trim(),
                      muscle: muscle,
                      weight: weight,
                      sets: sets,
                      reps: reps,
                      date: DateTime.now(),
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(result['message']?.toString() ??
                          'Could not save personal record.')),
                );
              }
            }

            return Dialog(
              backgroundColor: _Colors.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Log Personal Record',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _Colors.textPrimary)),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    color: _Colors.textMuted, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Target Muscle'),
                        const SizedBox(height: 8),
                        _Dropdown(
                          value: muscle,
                          items: kMuscles,
                          onChanged: (v) =>
                              setDialogState(() => muscle = v ?? muscle),
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Exercise'),
                        const SizedBox(height: 8),
                        _TextInput(
                            controller: exerciseCtrl,
                            hint: 'e.g., Bench Press'),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Weight (kg)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: weightCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Sets'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: setsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Reps'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: repsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Colors.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(
                                      color: _Colors.cardBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: _Colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Colors.cyan,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: saving ? null : handleSave,
                                child: Text(saving ? 'Saving…' : 'Save PR',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removePr(int index) async {
    final pr = _prs[index];

    // Optimistically remove from the UI first for a snappy feel.
    setState(() => _prs.removeAt(index));

    if (pr.prId != null) {
      final result = await PersonalRecordsService.deleteRecord(pr.prId!);
      if (!mounted) return;
      if (result['success'] != true) {
        // Put it back if the delete failed on the server.
        setState(() => _prs.insert(index, pr));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']?.toString() ??
                  'Could not delete personal record.')),
        );
      }
    }
  }

  Future<void> _loadMonthlyGoal() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      return;
    }

    final result = await MonthlyGoalsService.fetchGoal(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['goal'] is Map) {
      final goal = result['goal'] as Map<String, dynamic>;
      setState(() {
        _goalTarget = int.tryParse('${goal['TargetSessions']}') ?? 20;
        _goalCompleted = int.tryParse('${goal['CompletedSessions']}') ?? 0;
      });
    }
  }

  Future<void> _loadTargets() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) return;

    final result = await UserTargetsService.fetchTargets(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['targets'] is Map) {
      final t = result['targets'] as Map<String, dynamic>;
      setState(() {
        _targets = UserTargets(
          calorieTarget: int.tryParse('${t['DailyCalorieTarget']}'),
          proteinTarget: double.tryParse('${t['DailyProteinTarget']}'),
          carbsTarget: double.tryParse('${t['DailyCarbsTarget']}'),
          fatsTarget: double.tryParse('${t['DailyFatsTarget']}'),
          targetWeight: double.tryParse('${t['TargetWeight']}'),
        );
      });
    }
  }

  // -- Photo actions ------------------------------------------------------

  Future<void> _loadBodyPhotos() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      setState(() => _loadingPhotos = false);
      return;
    }

    final result = await BodyPhotosService.fetchPhotos(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['photos'] is List) {
      setState(() {
        _photos.clear();
        _photos.addAll((result['photos'] as List).map((r) {
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(r['UploadDate'].toString());
          } catch (_) {
            parsedDate = DateTime.now();
          }
          return ProgressPhoto(
            photoId: int.tryParse('${r['PhotoID']}'),
            url: r['PhotoURL']?.toString() ?? '',
            date: parsedDate,
            insight: r['InsightText']?.toString() ??
                'AI insight is temporarily unavailable for this photo.',
          );
        }));
        _loadingPhotos = false;
      });
    } else {
      setState(() => _loadingPhotos = false);
    }
  }

  Future<void> _pickPhotos() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Member session not found. Please log in again.')),
      );
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked == null) return; // user cancelled

    final Uint8List bytes = await picked.readAsBytes();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading photo…')),
    );

    final result = await BodyPhotosService.upload(
      memberId: memberId,
      bytes: bytes,
      filename: picked.name,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      DateTime uploadedDate;
      try {
        uploadedDate = DateTime.parse(result['date'].toString());
      } catch (_) {
        uploadedDate = DateTime.now();
      }
      setState(() {
        _photos.insert(
          0,
          ProgressPhoto(
            photoId: int.tryParse('${result['photo_id']}'),
            url: result['url']?.toString() ?? '',
            date: uploadedDate,
            insight: result['insight']?.toString() ??
                'AI insight is temporarily unavailable for this photo.',
          ),
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Photo uploaded.')));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(result['message']?.toString() ?? 'Upload failed.')));
    }
  }

  Future<void> _removePhoto(int index) async {
    final photo = _photos[index];

    // Optimistically remove from the UI first.
    setState(() => _photos.removeAt(index));

    if (photo.photoId != null) {
      final result = await BodyPhotosService.deletePhoto(photo.photoId!);
      if (!mounted) return;
      if (result['success'] != true) {
        // Put it back if the delete failed on the server.
        setState(() => _photos.insert(index, photo));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result['message']?.toString() ?? 'Could not delete photo.')),
        );
      }
    }
  }

  // -- Body metrics actions -----------------------------------------------

  double _computeBmi(double weightKg, double heightCm) {
    if (heightCm <= 0) return 0;
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Future<void> _loadBodyMetrics() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      setState(() => _loadingBodyMetrics = false);
      return;
    }

    final result = await BodyMetricsService.fetchHistory(memberId);
    if (!mounted) return;

    if (result['success'] == true && result['metrics'] is List) {
      setState(() {
        _bodyMetrics = (result['metrics'] as List).map((r) {
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(r['RecordedAt'].toString());
          } catch (_) {
            parsedDate = DateTime.now();
          }
          final weight = double.tryParse('${r['Weight']}') ?? 0;
          final height = double.tryParse('${r['Height']}') ?? 0;
          final bmi =
              double.tryParse('${r['BMI']}') ?? _computeBmi(weight, height);
          return BodyMetric(
            metricId: int.tryParse('${r['MetricID']}'),
            weight: weight,
            height: height,
            bmi: bmi,
            date: parsedDate,
          );
        }).toList();
        _loadingBodyMetrics = false;
      });
    } else {
      setState(() => _loadingBodyMetrics = false);
    }
  }

  Future<void> _openLogBodyMetricDialog() async {
    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> handleSave() async {
              final weight = double.tryParse(weightCtrl.text.trim());
              final height = double.tryParse(heightCtrl.text.trim());
              if (weight == null ||
                  weight <= 0 ||
                  height == null ||
                  height <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Enter a valid weight and height (both greater than 0).')),
                );
                return;
              }

              final memberId = UserSession.instance.dbMemberId;
              if (memberId == null) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Member session not found. Please log in again.')),
                  );
                }
                return;
              }

              setDialogState(() => saving = true);

              final result = await BodyMetricsService.addEntry(
                memberId: memberId,
                weight: weight,
                height: height,
              );

              if (!ctx.mounted) return;

              if (result['success'] == true) {
                final bmi = double.tryParse('${result['bmi']}') ??
                    _computeBmi(weight, height);
                setState(() {
                  _bodyMetrics.insert(
                    0,
                    BodyMetric(
                      metricId: int.tryParse('${result['metric_id']}'),
                      weight: weight,
                      height: height,
                      bmi: bmi,
                      date: DateTime.now(),
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(result['message']?.toString() ??
                          'Could not save entry.')),
                );
              }
            }

            return Dialog(
              backgroundColor: _Colors.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Log Body Metrics',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _Colors.textPrimary)),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    color: _Colors.textMuted, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Weight (kg)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: weightCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Height (cm)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: heightCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Colors.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(
                                      color: _Colors.cardBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: _Colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Colors.cyan,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: saving ? null : handleSave,
                                child: Text(saving ? 'Saving…' : 'Save Entry',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeBodyMetric(int index) async {
    final metric = _bodyMetrics[index];
    final memberId = UserSession.instance.dbMemberId;

    // Optimistically remove from the UI first.
    setState(() => _bodyMetrics.removeAt(index));

    if (metric.metricId != null && memberId != null) {
      final result =
          await BodyMetricsService.deleteEntry(metric.metricId!, memberId);
      if (!mounted) return;
      if (result['success'] != true) {
        // Put it back if the delete failed on the server.
        setState(() => _bodyMetrics.insert(index, metric));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result['message']?.toString() ?? 'Could not delete entry.')),
        );
      }
    }
  }

  // -- Food log actions -----------------------------------------------------

  Future<void> _loadFoodLogs() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      setState(() => _loadingFoodLogs = false);
      return;
    }

    setState(() => _loadingFoodLogs = true);

    final result =
        await FoodLogsService.fetchLogs(memberId, date: _selectedFoodLogDate);
    if (!mounted) return;

    if (result['success'] == true && result['logs'] is List) {
      setState(() {
        _foodLogs = (result['logs'] as List).map((r) {
          DateTime parsedDate;
          try {
            parsedDate = DateTime.parse(r['LoggedAt'].toString());
          } catch (_) {
            parsedDate = DateTime.now();
          }
          return FoodLogEntry(
            logId: int.tryParse('${r['LogID']}'),
            foodName: r['FoodName']?.toString() ?? '',
            mealType: r['MealType']?.toString() ?? kMealTypes.first,
            calories: int.tryParse('${r['Calories']}') ?? 0,
            protein: double.tryParse('${r['Protein']}') ?? 0,
            carbs: double.tryParse('${r['Carbs']}') ?? 0,
            fats: double.tryParse('${r['Fats']}') ?? 0,
            date: parsedDate,
          );
        }).toList();
        if (_isToday(_selectedFoodLogDate)) {
          _todayCalories = _foodLogs.fold<int>(0, (sum, l) => sum + l.calories);
        }
        _loadingFoodLogs = false;
      });
    } else {
      setState(() => _loadingFoodLogs = false);
    }
  }

  void _changeFoodLogDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (normalized.isAfter(todayOnly)) return; // no logging future days
    if (normalized == _selectedFoodLogDate) return;

    setState(() => _selectedFoodLogDate = normalized);
    _loadFoodLogs();
  }

  Future<void> _openLogFoodDialog() async {
    String mealType = kMealTypes.first;
    final foodNameCtrl = TextEditingController();
    final caloriesCtrl = TextEditingController();
    final proteinCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatsCtrl = TextEditingController();
    bool saving = false;

    List<FoodSearchResult> searchResults = [];
    bool searching = false;
    bool showResults = false;
    Timer? debounce;
    int searchToken =
        0; // guards against a stale search overwriting a newer one

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            void closeDialog() {
              debounce?.cancel();
              Navigator.of(ctx).pop();
            }

            Future<void> runSearch(String query) async {
              final token = ++searchToken;
              setDialogState(() => searching = true);

              final result = await FoodSearchService.searchFoods(query);

              if (!ctx.mounted || token != searchToken) return;

              setDialogState(() {
                searching = false;
                if (result['success'] == true && result['results'] is List) {
                  searchResults = (result['results'] as List).map((r) {
                    return FoodSearchResult(
                      name: r['food_name']?.toString() ?? '',
                      calories: int.tryParse('${r['calories']}') ??
                          (double.tryParse('${r['calories']}')?.round() ?? 0),
                      protein: double.tryParse('${r['protein']}') ?? 0,
                      carbs: double.tryParse('${r['carbs']}') ?? 0,
                      fats: double.tryParse('${r['fats']}') ?? 0,
                    );
                  }).toList();
                } else {
                  // Search failures are treated the same as "no matches" --
                  // manual entry always still works, so no error popup here.
                  searchResults = [];
                }
              });
            }

            void handleFoodNameChanged(String value) {
              debounce?.cancel();
              final query = value.trim();
              if (query.length < 2) {
                setDialogState(() {
                  searchResults = [];
                  showResults = false;
                  searching = false;
                });
                return;
              }
              setDialogState(() => showResults = true);
              debounce = Timer(
                  const Duration(milliseconds: 400), () => runSearch(query));
            }

            void selectSearchResult(FoodSearchResult r) {
              debounce?.cancel();
              foodNameCtrl.text = r.name;
              caloriesCtrl.text = r.calories.toString();
              proteinCtrl.text = _fmtNum(r.protein);
              carbsCtrl.text = _fmtNum(r.carbs);
              fatsCtrl.text = _fmtNum(r.fats);
              setDialogState(() {
                showResults = false;
                searchResults = [];
              });
            }

            Future<void> handleSave() async {
              final foodName = foodNameCtrl.text.trim();
              if (foodName.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Enter a food name.')),
                );
                return;
              }

              final calories = int.tryParse(caloriesCtrl.text.trim());
              if (calories == null || calories <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Enter a valid calorie amount greater than 0.')),
                );
                return;
              }

              final proteinText = proteinCtrl.text.trim();
              final protein =
                  proteinText.isEmpty ? 0.0 : double.tryParse(proteinText);
              final carbsText = carbsCtrl.text.trim();
              final carbs =
                  carbsText.isEmpty ? 0.0 : double.tryParse(carbsText);
              final fatsText = fatsCtrl.text.trim();
              final fats = fatsText.isEmpty ? 0.0 : double.tryParse(fatsText);
              if (protein == null ||
                  carbs == null ||
                  fats == null ||
                  protein < 0 ||
                  carbs < 0 ||
                  fats < 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Protein, carbs, and fats must be numbers of 0 or more.')),
                );
                return;
              }

              final memberId = UserSession.instance.dbMemberId;
              if (memberId == null) {
                closeDialog();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Member session not found. Please log in again.')),
                  );
                }
                return;
              }

              setDialogState(() => saving = true);

              final result = await FoodLogsService.addEntry(
                memberId: memberId,
                foodName: foodName,
                mealType: mealType,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
              );

              if (!ctx.mounted) return;

              if (result['success'] == true) {
                setState(() {
                  _foodLogs.insert(
                    0,
                    FoodLogEntry(
                      logId: int.tryParse('${result['log_id']}'),
                      foodName: foodName,
                      mealType: mealType,
                      calories: calories,
                      protein: protein,
                      carbs: carbs,
                      fats: fats,
                      date: DateTime.now(),
                    ),
                  );
                  // Add Food is only enabled while viewing today, so this
                  // entry always counts toward today's total.
                  _todayCalories += calories;
                });
                closeDialog();
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(result['message']?.toString() ??
                          'Could not save food entry.')),
                );
              }
            }

            return Dialog(
              backgroundColor: _Colors.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Log Food Entry',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _Colors.textPrimary)),
                            InkWell(
                              onTap: closeDialog,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    color: _Colors.textMuted, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Meal Type'),
                        const SizedBox(height: 8),
                        _Dropdown(
                          value: mealType,
                          items: kMealTypes,
                          onChanged: (v) =>
                              setDialogState(() => mealType = v ?? mealType),
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Food Name'),
                        const SizedBox(height: 8),
                        _TextInput(
                            controller: foodNameCtrl,
                            hint: 'e.g., Grilled Chicken Breast',
                            onChanged: handleFoodNameChanged),
                        if (searching)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: _Colors.cyan)),
                                const SizedBox(width: 8),
                                Text('Searching…',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: _Colors.textMuted)),
                              ],
                            ),
                          )
                        else if (showResults && searchResults.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              border: Border.all(color: _Colors.cardBorder),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: searchResults.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1, color: _Colors.cardBorder),
                              itemBuilder: (context, i) {
                                final r = searchResults[i];
                                return InkWell(
                                  onTap: () => selectSearchResult(r),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: _Colors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(
                                            '${r.calories} kcal · P ${_fmtNum(r.protein)}g · C ${_fmtNum(r.carbs)}g · F ${_fmtNum(r.fats)}g',
                                            style: TextStyle(
                                                fontSize: 11.5,
                                                color: _Colors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        else if (showResults && searchResults.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('No matches — enter manually.',
                                style: TextStyle(
                                    fontSize: 12.5, color: _Colors.textMuted)),
                          ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Calories'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: caloriesCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Protein (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: proteinCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Carbs (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: carbsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Fats (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: fatsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Colors.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(
                                      color: _Colors.cardBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: saving ? null : closeDialog,
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: _Colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Colors.cyan,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: saving ? null : handleSave,
                                child: Text(saving ? 'Saving…' : 'Save Food',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeFoodLog(int index) async {
    final entry = _foodLogs[index];
    final memberId = UserSession.instance.dbMemberId;
    final wasToday = _isToday(entry.date);

    // Optimistically remove from the UI first.
    setState(() {
      _foodLogs.removeAt(index);
      if (wasToday) _todayCalories -= entry.calories;
    });

    if (entry.logId != null && memberId != null) {
      final result = await FoodLogsService.deleteEntry(entry.logId!, memberId);
      if (!mounted) return;
      if (result['success'] != true) {
        // Put it back if the delete failed on the server.
        setState(() {
          _foodLogs.insert(index, entry);
          if (wasToday) _todayCalories += entry.calories;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  result['message']?.toString() ?? 'Could not delete entry.')),
        );
      }
    }
  }

  // -- Targets actions -------------------------------------------------------

  Future<void> _openSetTargetsDialog() async {
    final calorieCtrl = TextEditingController(
        text: _targets.calorieTarget == null
            ? ''
            : _fmtNum(_targets.calorieTarget!));
    final proteinCtrl = TextEditingController(
        text: _targets.proteinTarget == null
            ? ''
            : _fmtNum(_targets.proteinTarget!));
    final carbsCtrl = TextEditingController(
        text:
            _targets.carbsTarget == null ? '' : _fmtNum(_targets.carbsTarget!));
    final fatsCtrl = TextEditingController(
        text: _targets.fatsTarget == null ? '' : _fmtNum(_targets.fatsTarget!));
    final targetWeightCtrl = TextEditingController(
        text: _targets.targetWeight == null
            ? ''
            : _fmtNum(_targets.targetWeight!));
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> handleSave() async {
              final calorieTarget = int.tryParse(calorieCtrl.text.trim());
              if (calorieTarget == null || calorieTarget <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Enter a valid daily calorie target greater than 0.')),
                );
                return;
              }

              final proteinText = proteinCtrl.text.trim();
              final proteinTarget =
                  proteinText.isEmpty ? null : double.tryParse(proteinText);
              if (proteinText.isNotEmpty &&
                  (proteinTarget == null || proteinTarget < 0)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Protein target must be a number of 0 or more.')),
                );
                return;
              }

              final carbsText = carbsCtrl.text.trim();
              final carbsTarget =
                  carbsText.isEmpty ? null : double.tryParse(carbsText);
              if (carbsText.isNotEmpty &&
                  (carbsTarget == null || carbsTarget < 0)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Carbs target must be a number of 0 or more.')),
                );
                return;
              }

              final fatsText = fatsCtrl.text.trim();
              final fatsTarget =
                  fatsText.isEmpty ? null : double.tryParse(fatsText);
              if (fatsText.isNotEmpty &&
                  (fatsTarget == null || fatsTarget < 0)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Fats target must be a number of 0 or more.')),
                );
                return;
              }

              final targetWeightText = targetWeightCtrl.text.trim();
              final targetWeight = targetWeightText.isEmpty
                  ? null
                  : double.tryParse(targetWeightText);
              if (targetWeightText.isNotEmpty &&
                  (targetWeight == null || targetWeight <= 0)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                      content: Text('Target weight must be greater than 0.')),
                );
                return;
              }

              final memberId = UserSession.instance.dbMemberId;
              if (memberId == null) {
                Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Member session not found. Please log in again.')),
                  );
                }
                return;
              }

              setDialogState(() => saving = true);

              final result = await UserTargetsService.saveTargets(
                memberId: memberId,
                calorieTarget: calorieTarget,
                proteinTarget: proteinTarget,
                carbsTarget: carbsTarget,
                fatsTarget: fatsTarget,
                targetWeight: targetWeight,
              );

              if (!ctx.mounted) return;

              if (result['success'] == true) {
                setState(() {
                  _targets = UserTargets(
                    calorieTarget: calorieTarget,
                    proteinTarget: proteinTarget,
                    carbsTarget: carbsTarget,
                    fatsTarget: fatsTarget,
                    targetWeight: targetWeight,
                  );
                });
                Navigator.of(ctx).pop();
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(result['message']?.toString() ??
                          'Could not save targets.')),
                );
              }
            }

            return Dialog(
              backgroundColor: _Colors.surface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Set Daily Targets',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: _Colors.textPrimary)),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close,
                                    color: _Colors.textMuted, size: 22),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Daily Calorie Target'),
                        const SizedBox(height: 8),
                        _TextInput(
                            controller: calorieCtrl, hint: '0', number: true),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Protein (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: proteinCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Carbs (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: carbsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _FieldLabel('Fats (g)'),
                                  const SizedBox(height: 8),
                                  _TextInput(
                                      controller: fatsCtrl,
                                      hint: '0',
                                      number: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel('Target Weight (kg)'),
                        const SizedBox(height: 8),
                        _TextInput(
                            controller: targetWeightCtrl,
                            hint: '0',
                            number: true),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _Colors.surface,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(
                                      color: _Colors.cardBorder),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: saving
                                    ? null
                                    : () => Navigator.of(ctx).pop(),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: _Colors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _Colors.cyan,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: saving ? null : handleSave,
                                child: Text(saving ? 'Saving…' : 'Save Targets',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // -- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progress Tracker',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _Colors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor your body, records, and personalized programs',
                    style:
                        TextStyle(fontSize: 14, color: _Colors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _Colors.cardBorder)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: _Colors.cyan,
                unselectedLabelColor: _Colors.textSecondary,
                indicatorColor: _Colors.cyan,
                indicatorWeight: 2,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(
                      icon: Icon(Icons.trending_up, size: 18),
                      text: 'Overview'),
                  Tab(
                      icon: Icon(Icons.emoji_events_outlined, size: 18),
                      text: 'PR Records'),
                  Tab(
                      icon: Icon(Icons.camera_alt_outlined, size: 18),
                      text: 'Body Photos'),
                  Tab(
                      icon: Icon(Icons.monitor_weight_outlined, size: 18),
                      text: 'BMI'),
                  Tab(
                      icon: Icon(Icons.restaurant_outlined, size: 18),
                      text: 'Food Log'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(
                    totalSessions: UserSession.instance.creditsTotal,
                    currentStreak: UserSession.instance.dayStreak,
                    prsCount: _prs.length,
                    photosCount: _photos.length,
                    goalTarget: _goalTarget,
                    goalCompleted: _goalCompleted,
                    prsThisMonth: _prs
                        .where((p) =>
                            p.date.year == DateTime.now().year &&
                            p.date.month == DateTime.now().month)
                        .length,
                    monthlyAttendance: UserSession.instance.monthlyAttendance,
                    currentBmi:
                        _bodyMetrics.isNotEmpty ? _bodyMetrics.first.bmi : null,
                    bmiCategory: _bodyMetrics.isNotEmpty
                        ? _bodyMetrics.first.category
                        : null,
                    todayCalories: _todayCalories,
                    calorieTarget: _targets.calorieTarget,
                  ),
                  _PrRecordsTab(
                    prs: _prs,
                    loading: _loadingPrs,
                    onAdd: _openLogPrDialog,
                    onRemove: _removePr,
                    fmtDate: _fmtDate,
                  ),
                  _BodyPhotosTab(
                    photos: _photos,
                    loading: _loadingPhotos,
                    onUpload: _pickPhotos,
                    onRemove: _removePhoto,
                  ),
                  _BodyMetricsTab(
                    metrics: _bodyMetrics,
                    loading: _loadingBodyMetrics,
                    onAdd: _openLogBodyMetricDialog,
                    onRemove: _removeBodyMetric,
                    fmtDate: _fmtDate,
                    targets: _targets,
                    onSetTargets: _openSetTargetsDialog,
                  ),
                  _FoodLogTab(
                    logs: _foodLogs,
                    loading: _loadingFoodLogs,
                    onAdd: _openLogFoodDialog,
                    onRemove: _removeFoodLog,
                    targets: _targets,
                    onSetTargets: _openSetTargetsDialog,
                    selectedDate: _selectedFoodLogDate,
                    onDateChange: _changeFoodLogDate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Text(text,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _Colors.textPrimary));
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool number;
  final ValueChanged<String>? onChanged;
  const _TextInput(
      {required this.controller,
      required this.hint,
      this.number = false,
      this.onChanged});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _Colors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _Colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Colors.cyan, width: 1.5),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _Dropdown(
      {required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _Colors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down,
              color: _Colors.textSecondary),
          style: TextStyle(fontSize: 14.5, color: _Colors.textPrimary),
          items: items
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({required this.child, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _Colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _Colors.cardBorder),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Overview tab
// ---------------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  final int totalSessions;
  final int currentStreak;
  final int prsCount;
  final int photosCount;
  final int goalTarget;
  final int goalCompleted;
  final int prsThisMonth;
  final List<Map<String, Object>> monthlyAttendance;
  final double? currentBmi;
  final String? bmiCategory;
  final int todayCalories;
  final int? calorieTarget;

  const _OverviewTab({
    required this.totalSessions,
    required this.currentStreak,
    required this.prsCount,
    required this.photosCount,
    required this.goalTarget,
    required this.goalCompleted,
    required this.prsThisMonth,
    required this.monthlyAttendance,
    required this.currentBmi,
    required this.bmiCategory,
    required this.todayCalories,
    required this.calorieTarget,
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            // Based on the content area's own width (not full screen
            // width), since the sidebar already eats ~260px on
            // tablet/desktop: 1 column when cramped, 2 mid-width, 3 wide.
            final crossAxisCount = constraints.maxWidth < 420
                ? 1
                : constraints.maxWidth < 700
                    ? 2
                    : 3;
            final hasCalorieTarget =
                calorieTarget != null && calorieTarget! > 0;
            final cards = [
              _StatCard(
                  icon: Icons.show_chart,
                  iconColor: _Colors.cyan,
                  label: 'Total Sessions',
                  value: '$totalSessions'),
              _StatCard(
                  icon: Icons.local_fire_department,
                  iconColor: _Colors.amber,
                  label: 'Current Streak',
                  value: '$currentStreak Days'),
              _StatCard(
                  icon: Icons.emoji_events,
                  iconColor: _Colors.purple,
                  label: 'PRs Logged',
                  value: '$prsCount'),
              _StatCard(
                  icon: Icons.camera_alt,
                  iconColor: _Colors.pink,
                  label: 'Body Photos',
                  value: '$photosCount'),
              _StatCard(
                  icon: Icons.monitor_weight_outlined,
                  iconColor: _Colors.emerald,
                  label: 'Current BMI',
                  value: currentBmi == null
                      ? 'Not logged yet'
                      : '${currentBmi!.toStringAsFixed(1)} · $bmiCategory'),
              _StatCard(
                  icon: Icons.restaurant_outlined,
                  iconColor: _Colors.red,
                  label: "Today's Calories",
                  value: todayCalories == 0
                      ? 'Not logged yet'
                      : hasCalorieTarget
                          ? '$todayCalories/$calorieTarget kcal'
                          : '$todayCalories kcal'),
            ];
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: cards,
            );
          }),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Attendance',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: _Colors.textPrimary)),
                const SizedBox(height: 20),
                SizedBox(
                    height: 220,
                    child: _AttendanceChart(data: monthlyAttendance)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.track_changes, size: 18, color: _Colors.cyan),
                    const SizedBox(width: 8),
                    Text('Monthly Goal Progress',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _Colors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 20),
                _GoalProgressRow(
                    label: 'Workout Sessions',
                    current: goalCompleted,
                    target: goalTarget),
                const SizedBox(height: 16),
                _GoalProgressRow(
                    label: 'New PRs This Month',
                    current: prsThisMonth,
                    target: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return _Card(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12.5, color: _Colors.textSecondary),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _Colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceChart extends StatelessWidget {
  final List<Map<String, Object>> data;
  const _AttendanceChart({required this.data});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final maxValue = data.isEmpty
        ? 1.0
        : data
            .map((m) => (m['sessions'] as num).toDouble())
            .fold(1.0, (a, b) => b > a ? b : a);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((m) {
        final value = (m['sessions'] as num).toDouble();
        final heightFactor =
            maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFactor <= 0 ? 0.01 : heightFactor,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _Colors.cyan,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  m['month'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12.5, color: _Colors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Formats a num without a trailing ".0" for whole values, e.g. 85.0 -> "85"
/// but 85.3 -> "85.3". Used anywhere a goal/target value is displayed.
String _fmtNum(num n) =>
    n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

class _GoalProgressRow extends StatelessWidget {
  final String label;
  final num current;
  final num target;
  final String unit;

  const _GoalProgressRow({
    required this.label,
    required this.current,
    required this.target,
    this.unit = '',
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final pct = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: _Colors.textPrimary)),
            Text('${_fmtNum(current)}/${_fmtNum(target)}$unit',
                style: TextStyle(
                    fontSize: 13.5, color: _Colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 9,
            backgroundColor: _Colors.subtleBg,
            valueColor: const AlwaysStoppedAnimation(_Colors.cyan),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PR Records tab
// ---------------------------------------------------------------------------

class _PrRecordsTab extends StatelessWidget {
  final List<PersonalRecord> prs;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final String Function(DateTime) fmtDate;

  const _PrRecordsTab({
    required this.prs,
    required this.loading,
    required this.onAdd,
    required this.onRemove,
    required this.fmtDate,
  });

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Records',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textPrimary)),
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Colors.cyan,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Log PR',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: _Colors.cyan))
                : prs.isEmpty
                    ? Center(
                        child: Text(
                            'No records yet. Log your first PR to get started.',
                            style: TextStyle(color: _Colors.textMuted)),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: _Colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _Colors.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        // Custom flex-based table (instead of DataTable) so
                        // columns stretch to fill the full card width --
                        // no horizontal scrolling needed at any screen size.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              color: _Colors.bg,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 3,
                                      child: Text('Exercise',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Muscle',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Weight (kg)',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Sets',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  Expanded(
                                      flex: 1,
                                      child: Text('Reps',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('Date',
                                          style: TextStyle(
                                              color: _Colors.textSecondary,
                                              fontWeight: FontWeight.w600))),
                                  const SizedBox(width: 40),
                                ],
                              ),
                            ),
                            ...List.generate(prs.length, (i) {
                              final p = prs[i];
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  border: i < prs.length - 1
                                      ? Border(
                                          bottom: BorderSide(
                                              color: _Colors.cardBorder))
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.emoji_events,
                                              size: 16, color: _Colors.amber),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(p.exercise,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                              color: _Colors.cyanLight,
                                              borderRadius:
                                                  BorderRadius.circular(20)),
                                          child: Text(p.muscle,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  color: _Colors.cyanText,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('${p.weight} kg',
                                          style: const TextStyle(
                                              color: _Colors.emerald,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Expanded(flex: 1, child: Text('${p.sets}')),
                                    Expanded(flex: 1, child: Text('${p.reps}')),
                                    Expanded(
                                        flex: 2,
                                        child: Text(fmtDate(p.date),
                                            style: TextStyle(
                                                color: _Colors.textSecondary))),
                                    SizedBox(
                                      width: 40,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(Icons.delete_outline,
                                            size: 18, color: _Colors.textMuted),
                                        onPressed: () => onRemove(i),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body Photos tab
// ---------------------------------------------------------------------------

class _BodyPhotosTab extends StatelessWidget {
  final List<ProgressPhoto> photos;
  final bool loading;
  final VoidCallback onUpload;
  final void Function(int) onRemove;

  const _BodyPhotosTab(
      {required this.photos,
      required this.loading,
      required this.onUpload,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Body Progress Photos',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _Colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(
                        'Upload photos — AI will generate a personalized insight for each one',
                        style: TextStyle(
                            fontSize: 13.5, color: _Colors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Colors.cyan,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.upload, size: 18, color: Colors.white),
                label: const Text('Upload Photo',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _Colors.cyanLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _Colors.cyanBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.psychology_alt_outlined,
                    size: 20, color: _Colors.cyan),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'After uploading, our AI analyzes your physique and delivers tailored feedback on muscle development, body composition, and training recommendations specific to your visible progress.',
                    style: TextStyle(
                        fontSize: 13.5,
                        color: _Colors.textSecondary,
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _Colors.cyan)))
          else if (photos.isEmpty)
            InkWell(
              onTap: onUpload,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 72),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _Colors.cardBorder, width: 1.5),
                ),
                child: Column(
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        size: 40, color: _Colors.iconMuted),
                    const SizedBox(height: 14),
                    Text('Upload your first progress photo',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _Colors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('AI insights will be generated automatically',
                        style:
                            TextStyle(fontSize: 13, color: _Colors.textMuted)),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(builder: (context, constraints) {
              // 1 column when the content area is cramped (phone, or
              // tablet with the sidebar open), 2 otherwise.
              final crossAxisCount = constraints.maxWidth < 420 ? 1 : 2;
              return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: crossAxisCount == 1 ? 1.6 : 0.8,
              ),
              itemBuilder: (context, i) {
                final p = photos[i];
                return Container(
                  decoration: BoxDecoration(
                    color: _Colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _Colors.cardBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              p.url,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: _Colors.cyan));
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: _Colors.subtleBg,
                                alignment: Alignment.center,
                                child: Icon(Icons.broken_image_outlined,
                                    color: _Colors.textMuted, size: 32),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => onRemove(i),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      shape: BoxShape.circle),
                                  child: const Icon(Icons.delete_outline,
                                      size: 15, color: _Colors.red),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${p.date.year}-${p.date.month.toString().padLeft(2, '0')}-${p.date.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.psychology_alt_outlined,
                                size: 15, color: _Colors.cyan),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(p.insight,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: _Colors.textSecondary,
                                      height: 1.3)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BMI tab
// ---------------------------------------------------------------------------

class _BodyMetricsTab extends StatelessWidget {
  final List<BodyMetric> metrics;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final String Function(DateTime) fmtDate;
  final UserTargets targets;
  final VoidCallback onSetTargets;

  const _BodyMetricsTab({
    required this.metrics,
    required this.loading,
    required this.onAdd,
    required this.onRemove,
    required this.fmtDate,
    required this.targets,
    required this.onSetTargets,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return _Colors.amber;
      case 'Normal':
        return _Colors.emerald;
      case 'Overweight':
        return _Colors.amber;
      case 'Obese':
        return _Colors.red;
      default:
        return _Colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final latest = metrics.isNotEmpty ? metrics.first : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BMI Tracking',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textPrimary)),
              ElevatedButton.icon(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Colors.cyan,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Entry',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _Colors.cyan)))
          else ...[
            _Card(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: latest == null
                          ? _Colors.cardBorder
                          : _categoryColor(latest.category)
                              .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.monitor_weight_outlined,
                        size: 28,
                        color: latest == null
                            ? _Colors.textMuted
                            : _categoryColor(latest.category)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current BMI',
                            style: TextStyle(
                                fontSize: 13, color: _Colors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          latest == null ? '--' : latest.bmi.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _Colors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        if (latest != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _categoryColor(latest.category)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(latest.category,
                                style: TextStyle(
                                    color: _categoryColor(latest.category),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600)),
                          )
                        else
                          Text(
                              'Log your weight and height to see your BMI.',
                              style: TextStyle(
                                  fontSize: 12.5, color: _Colors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weight Goal',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textPrimary)),
                  const SizedBox(height: 16),
                  if (targets.targetWeight == null ||
                      targets.targetWeight! <= 0)
                    InkWell(
                      onTap: onSetTargets,
                      borderRadius: BorderRadius.circular(8),
                      child: const Text(
                          'Set your daily goals to track progress.',
                          style: TextStyle(
                              fontSize: 13,
                              color: _Colors.cyanText,
                              fontWeight: FontWeight.w500)),
                    )
                  else if (latest == null)
                    Text(
                        'Log a weight entry to track progress toward your target.',
                        style:
                            TextStyle(fontSize: 13, color: _Colors.textMuted))
                  else
                    _GoalProgressRow(
                      label: 'Current Weight',
                      current: latest.weight,
                      target: targets.targetWeight!,
                      unit: ' kg',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BMI Over Time',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textPrimary)),
                  const SizedBox(height: 20),
                  metrics.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                              child: Text('No BMI entries yet.',
                                  style: TextStyle(color: _Colors.textMuted))),
                        )
                      : SizedBox(
                          height: 220,
                          child: _BmiChart(metrics: metrics, fmtDate: fmtDate)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('History',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textPrimary)),
                  const SizedBox(height: 16),
                  if (metrics.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                          child: Text('Your logged entries will appear here.',
                              style: TextStyle(color: _Colors.textMuted))),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: _Colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _Colors.cardBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            color: _Colors.bg,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                    flex: 2,
                                    child: Text('Date',
                                        style: TextStyle(
                                            color: _Colors.textSecondary,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Weight',
                                        style: TextStyle(
                                            color: _Colors.textSecondary,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Height',
                                        style: TextStyle(
                                            color: _Colors.textSecondary,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 1,
                                    child: Text('BMI',
                                        style: TextStyle(
                                            color: _Colors.textSecondary,
                                            fontWeight: FontWeight.w600))),
                                Expanded(
                                    flex: 2,
                                    child: Text('Category',
                                        style: TextStyle(
                                            color: _Colors.textSecondary,
                                            fontWeight: FontWeight.w600))),
                                const SizedBox(width: 40),
                              ],
                            ),
                          ),
                          ...List.generate(metrics.length, (i) {
                            final m = metrics[i];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < metrics.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                            color: _Colors.cardBorder))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      flex: 2,
                                      child: Text(fmtDate(m.date),
                                          style: TextStyle(
                                              color: _Colors.textSecondary))),
                                  Expanded(
                                      flex: 2,
                                      child: Text('${_fmtNum(m.weight)} kg')),
                                  Expanded(
                                      flex: 2,
                                      child: Text('${_fmtNum(m.height)} cm')),
                                  Expanded(
                                      flex: 1,
                                      child: Text(m.bmi.toStringAsFixed(1),
                                          style: const TextStyle(
                                              color: _Colors.emerald,
                                              fontWeight: FontWeight.bold))),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _categoryColor(m.category)
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(m.category,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color:
                                                    _categoryColor(m.category),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.delete_outline,
                                          size: 18, color: _Colors.textMuted),
                                      onPressed: () => onRemove(i),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BmiChart extends StatelessWidget {
  final List<BodyMetric> metrics;
  final String Function(DateTime) fmtDate;
  const _BmiChart({required this.metrics, required this.fmtDate});

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    // metrics is newest-first; the chart reads oldest -> newest, left to right.
    final sorted = metrics.reversed.toList();
    final maxValue =
        sorted.map((m) => m.bmi).fold(0.0, (a, b) => b > a ? b : a);
    final minValue =
        sorted.map((m) => m.bmi).fold(maxValue, (a, b) => b < a ? b : a);
    final range = (maxValue - minValue) <= 0 ? 1.0 : (maxValue - minValue);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: sorted.map((m) {
        final heightFactor = ((m.bmi - minValue) / range).clamp(0.0, 1.0);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(m.bmi.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11, color: _Colors.textSecondary)),
                const SizedBox(height: 4),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: heightFactor <= 0 ? 0.05 : heightFactor,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: _Colors.purple,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  fmtDate(m.date),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10.5, color: _Colors.textSecondary),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Food Log tab
// ---------------------------------------------------------------------------

class _FoodLogTab extends StatelessWidget {
  final List<FoodLogEntry> logs;
  final bool loading;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  final UserTargets targets;
  final VoidCallback onSetTargets;
  final DateTime selectedDate;
  final void Function(DateTime) onDateChange;

  const _FoodLogTab({
    required this.logs,
    required this.loading,
    required this.onAdd,
    required this.onRemove,
    required this.targets,
    required this.onSetTargets,
    required this.selectedDate,
    required this.onDateChange,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _fmtHeaderDate(DateTime d) {
    const months = [
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
    final label = '${months[d.month - 1]} ${d.day}';
    final now = DateTime.now();
    if (_isSameDay(d, now)) return 'Today, $label';
    if (d.year != now.year) return '$label, ${d.year}';
    return label;
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) onDateChange(picked);
  }

  /// A goal-progress row when a target is set for this macro, or a plain
  /// current-value row when it isn't -- avoids a broken n/0 progress bar.
  Widget _macroRow(String label, num current, num? target, String unit) {
    if (target == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _Colors.textPrimary)),
          Text('${_fmtNum(current)}$unit',
              style: TextStyle(
                  fontSize: 13.5, color: _Colors.textSecondary)),
        ],
      );
    }
    return _GoalProgressRow(
        label: label, current: current, target: target, unit: unit);
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    // `logs` is already scoped server-side to `selectedDate`.
    final isToday = _isSameDay(selectedDate, DateTime.now());
    final totalCalories = logs.fold<int>(0, (sum, l) => sum + l.calories);
    final totalProtein = logs.fold<double>(0, (sum, l) => sum + l.protein);
    final totalCarbs = logs.fold<double>(0, (sum, l) => sum + l.carbs);
    final totalFats = logs.fold<double>(0, (sum, l) => sum + l.fats);

    final grouped = <String, List<FoodLogEntry>>{};
    for (final entry in logs) {
      grouped.putIfAbsent(entry.mealType, () => []).add(entry);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Food Log',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _Colors.textPrimary)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: onSetTargets,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Colors.cyan,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.track_changes,
                        size: 18, color: Colors.white),
                    label: const Text('Set Targets',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: isToday ? onAdd : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _Colors.cyan,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Food',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _Colors.cyan)))
          else ...[
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.track_changes, size: 18, color: _Colors.cyan),
                      const SizedBox(width: 8),
                      Text('Daily Goals',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _Colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!targets.hasAnyTarget)
                    InkWell(
                      onTap: onSetTargets,
                      borderRadius: BorderRadius.circular(8),
                      child: const Text(
                          'Set your daily goals to track progress.',
                          style: TextStyle(
                              fontSize: 13,
                              color: _Colors.cyanText,
                              fontWeight: FontWeight.w500)),
                    )
                  else ...[
                    _macroRow(
                        'Calories',
                        totalCalories,
                        (targets.calorieTarget != null &&
                                targets.calorieTarget! > 0)
                            ? targets.calorieTarget
                            : null,
                        ' kcal'),
                    const SizedBox(height: 16),
                    _macroRow(
                        'Protein', totalProtein, targets.proteinTarget, ' g'),
                    const SizedBox(height: 16),
                    _macroRow('Carbs', totalCarbs, targets.carbsTarget, ' g'),
                    const SizedBox(height: 16),
                    _macroRow('Fats', totalFats, targets.fatsTarget, ' g'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  color: _Colors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onDateChange(
                      selectedDate.subtract(const Duration(days: 1))),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Text(_fmtHeaderDate(selectedDate),
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: _Colors.textPrimary)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  color: isToday ? _Colors.textMuted : _Colors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: isToday
                      ? null
                      : () => onDateChange(
                          selectedDate.add(const Duration(days: 1))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(
                        isToday
                            ? 'No food logged today yet.'
                            : 'No food logged on this day.',
                        style: TextStyle(color: _Colors.textMuted))),
              )
            else
              ...kMealTypes
                  .where((meal) => grouped.containsKey(meal))
                  .map((meal) {
                final entries = grouped[meal]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _Colors.textSecondary)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: _Colors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _Colors.cardBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: List.generate(entries.length, (i) {
                            final entry = entries[i];
                            final globalIndex = logs.indexOf(entry);
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < entries.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                            color: _Colors.cardBorder))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(entry.foodName,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text('${entry.calories} kcal',
                                        style: const TextStyle(
                                            color: _Colors.emerald,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          'P ${entry.protein.toStringAsFixed(0)}g',
                                          style: TextStyle(
                                              color: _Colors.textSecondary))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          'C ${entry.carbs.toStringAsFixed(0)}g',
                                          style: TextStyle(
                                              color: _Colors.textSecondary))),
                                  Expanded(
                                      flex: 2,
                                      child: Text(
                                          'F ${entry.fats.toStringAsFixed(0)}g',
                                          style: TextStyle(
                                              color: _Colors.textSecondary))),
                                  SizedBox(
                                    width: 40,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.delete_outline,
                                          size: 18, color: _Colors.textMuted),
                                      onPressed: globalIndex == -1
                                          ? null
                                          : () => onRemove(globalIndex),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}
