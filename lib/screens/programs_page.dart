import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// 👇 Connects this screen to your PHP programs API (programs_api.php).
// Adjust the path if programs_service.dart lives somewhere else.
import '../services/programs_service.dart';
import '../theme/app_theme.dart';
import 'user_session.dart';

/// Dark-mode-aware color tokens for this screen's chrome (page/dialog
/// backgrounds, card surfaces, borders, and text) -- per-program brand
/// colors (cardBg/borderColor/themeColor/badge colors, all data-driven
/// from the Programs table) are left untouched since they're content,
/// not page theme. Call [sync] once at the top of each build() in this
/// file before reading any other getter.
class _Colors {
  static bool _dark = false;
  static void sync(BuildContext c) => _dark = Theme.of(c).brightness == Brightness.dark;

  static Color get bg => _dark ? AppColors.darkBg : Colors.white;
  static Color get surface => _dark ? AppColors.darkCard : const Color(0xFFF8FAFC);
  static Color get surfaceAlt => _dark ? AppColors.darkCard : const Color(0xFFF1F5F9);
  static Color get border => _dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
  static Color get textPrimary => _dark ? Colors.white : Colors.black87;
  static Color get textSecondary => _dark ? AppColors.textMutedOnDark : Colors.grey.shade600;
  static Color get textMuted => _dark ? AppColors.textMutedOnDark : Colors.grey.shade400;
}

// --- MAIN WORKOUT INTERFACE WITH PERSISTENT SIDEBAR ---
class WorkoutProgramsScreen extends StatefulWidget {
  const WorkoutProgramsScreen({super.key});

  @override
  State<WorkoutProgramsScreen> createState() => _WorkoutProgramsScreenState();
}

class _WorkoutProgramsScreenState extends State<WorkoutProgramsScreen> {
  String _selectedFilter = 'All';
  Map<String, dynamic>? _selectedWorkout;

  // Fetched from the Programs / ProgramDays / ProgramExercises tables
  // via programs_api.php -- see _loadPrograms() below.
  List<Map<String, dynamic>> _allWorkouts = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Color _hexToColor(dynamic hex, Color fallback) {
    if (hex == null) return fallback;
    var s = hex.toString().replaceAll('#', '');
    if (s.length != 6) return fallback;
    final value = int.tryParse('FF$s', radix: 16);
    return value != null ? Color(value) : fallback;
  }

  Future<void> _loadPrograms() async {
    final result = await ProgramsService.fetchPrograms();

    if (!mounted) return;

    if (result['success'] == true && result['programs'] is List) {
      final parsed = (result['programs'] as List).map<Map<String, dynamic>>((p) {
        final days = (p['days'] as List? ?? []);

        final tabs = days.map((d) => d['DayLabel']?.toString() ?? '').toList();

        final routines = <String, List<Map<String, dynamic>>>{};
        for (final d in days) {
          final dayLabel = d['DayLabel']?.toString() ?? '';
          final exercises = (d['exercises'] as List? ?? []);
          routines[dayLabel] = exercises.asMap().entries.map((entry) {
            final ex = entry.value;
            return {
              'num': '${entry.key + 1}',
              'name': ex['ExerciseName']?.toString() ?? '',
              'tip': ex['Tip']?.toString() ?? '',
              'sets': ex['Sets']?.toString() ?? '',
              'reps': ex['Reps']?.toString() ?? '',
              'rest': ex['Rest']?.toString() ?? '',
            };
          }).toList();
        }

        final freq = p['FrequencyPerWeek']?.toString() ?? '';

        return {
          'title': p['ProgramName']?.toString() ?? '',
          'category': p['MuscleGroup']?.toString() ?? '',
          'description': p['Description']?.toString() ?? '',
          'duration': p['DurationRange']?.toString() ?? '',
          'frequency': freq.isNotEmpty ? '${freq}x / week' : '',
          'level': p['Level']?.toString() ?? '',
          'imageUrl': p['ImageURL']?.toString() ?? '',
          'themeColor': _hexToColor(p['ThemeColorHex'], const Color(0xFF00B4D8)),
          'cardBg': _hexToColor(p['CardBgHex'], const Color(0xFFF4FBFD)),
          'borderColor': _hexToColor(p['BorderColorHex'], const Color(0xFFCFEEF7)),
          'badgeBg': _hexToColor(p['BadgeBgHex'], const Color(0xFFFFF3CD)),
          'badgeTextColor': _hexToColor(p['BadgeTextColorHex'], const Color(0xFFFFB703)),
          'tabs': tabs,
          'routines': routines,
        };
      }).toList();

      setState(() {
        _allWorkouts = parsed;
        _loading = false;
      });
    } else {
      setState(() {
        _loadError = result['message']?.toString() ?? 'Could not load programs.';
        _loading = false;
      });
    }
  }

  // ==================== CREATE PROGRAM ====================

  Future<void> _openCreateProgramDialog() async {
    final memberId = UserSession.instance.dbMemberId;
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member session not found. Please log in again.')),
      );
      return;
    }

    final nameCtrl = TextEditingController();
    final muscleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final freqCtrl = TextEditingController(text: '2');
    String level = 'Beginner';
    Uint8List? imageBytes;
    String? imageFilename;
    bool saving = false;

    // Each day: {label: TextEditingController, exercises: [ {name, tip, sets, reps, rest} controllers ]}
    final List<Map<String, dynamic>> days = [
      {
        'label': TextEditingController(text: 'Day A'),
        'exercises': <Map<String, TextEditingController>>[
          {
            'name': TextEditingController(),
            'tip': TextEditingController(),
            'sets': TextEditingController(),
            'reps': TextEditingController(),
            'rest': TextEditingController(),
          }
        ],
      }
    ];

    await showDialog(
      context: context,
      builder: (ctx) {
        _Colors.sync(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final XFile? picked = await picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1200,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              setDialogState(() {
                imageBytes = bytes;
                imageFilename = picked.name;
              });
            }

            void addDay() {
              setDialogState(() {
                days.add({
                  'label': TextEditingController(text: 'Day ${String.fromCharCode(65 + days.length)}'),
                  'exercises': <Map<String, TextEditingController>>[
                    {
                      'name': TextEditingController(),
                      'tip': TextEditingController(),
                      'sets': TextEditingController(),
                      'reps': TextEditingController(),
                      'rest': TextEditingController(),
                    }
                  ],
                });
              });
            }

            void removeDay(int dayIndex) {
              setDialogState(() => days.removeAt(dayIndex));
            }

            void addExercise(int dayIndex) {
              setDialogState(() {
                (days[dayIndex]['exercises'] as List).add({
                  'name': TextEditingController(),
                  'tip': TextEditingController(),
                  'sets': TextEditingController(),
                  'reps': TextEditingController(),
                  'rest': TextEditingController(),
                });
              });
            }

            void removeExercise(int dayIndex, int exIndex) {
              setDialogState(() => (days[dayIndex]['exercises'] as List).removeAt(exIndex));
            }

            Future<void> handleSave() async {
              if (nameCtrl.text.trim().isEmpty || muscleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Program name and muscle group are required.')),
                );
                return;
              }

              setDialogState(() => saving = true);

              final daysPayload = days.map((d) {
                final exercises = (d['exercises'] as List<Map<String, TextEditingController>>)
                    .where((ex) => ex['name']!.text.trim().isNotEmpty)
                    .map((ex) => {
                          'name': ex['name']!.text.trim(),
                          'tip': ex['tip']!.text.trim(),
                          'sets': ex['sets']!.text.trim(),
                          'reps': ex['reps']!.text.trim(),
                          'rest': ex['rest']!.text.trim(),
                        })
                    .toList();
                return {
                  'label': (d['label'] as TextEditingController).text.trim(),
                  'exercises': exercises,
                };
              }).toList();

              final result = await ProgramsService.createProgram(
                memberId: memberId,
                programName: nameCtrl.text.trim(),
                muscleGroup: muscleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                durationRange: durationCtrl.text.trim(),
                frequencyPerWeek: int.tryParse(freqCtrl.text.trim()) ?? 2,
                level: level,
                days: daysPayload,
                imageBytes: imageBytes,
                imageFilename: imageFilename,
              );

              if (!ctx.mounted) return;

              if (result['success'] == true) {
                Navigator.of(ctx).pop();
                await _loadPrograms(); // refresh the catalog with the new program
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Program created successfully.')),
                  );
                }
              } else {
                setDialogState(() => saving = false);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(result['message']?.toString() ?? 'Could not create program.')),
                );
              }
            }

            return Dialog(
              backgroundColor: _Colors.bg,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Create Program', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Icon(Icons.close, color: _Colors.textMuted, size: 22),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: _Colors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(10),
                                      image: imageBytes != null
                                          ? DecorationImage(image: MemoryImage(imageBytes!), fit: BoxFit.cover)
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: imageBytes == null
                                        ? Icon(Icons.image_outlined, color: _Colors.textMuted)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: pickImage,
                                    child: Text(imageBytes == null ? 'Add Cover Image (optional)' : 'Change Image'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _dialogLabel('Program Name'),
                              _dialogInput(nameCtrl, hint: 'e.g., Full Body Blast'),
                              _dialogLabel('Muscle Group'),
                              _dialogInput(muscleCtrl, hint: 'e.g., Full Body'),
                              _dialogLabel('Description'),
                              _dialogInput(descCtrl, hint: 'Short description of this program', maxLines: 2),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _dialogLabel('Duration'),
                                        _dialogInput(durationCtrl, hint: 'e.g., 40-50 min'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _dialogLabel('Frequency / week'),
                                        _dialogInput(freqCtrl, hint: '2', number: true),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              _dialogLabel('Level'),
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: _Colors.border),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: level,
                                    isExpanded: true,
                                    items: const ['Beginner', 'Intermediate', 'Advanced']
                                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                                        .toList(),
                                    onChanged: (v) => setDialogState(() => level = v ?? level),
                                  ),
                                ),
                              ),
                              const Divider(height: 32),
                              const Text('Workout Days', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              ...days.asMap().entries.map((dayEntry) {
                                final dayIndex = dayEntry.key;
                                final day = dayEntry.value;
                                final exercises = day['exercises'] as List<Map<String, TextEditingController>>;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _Colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _Colors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: day['label'] as TextEditingController,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                hintText: 'Day label (e.g. Day A - Strength)',
                                              ),
                                            ),
                                          ),
                                          if (days.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                              onPressed: () => removeDay(dayIndex),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ...exercises.asMap().entries.map((exEntry) {
                                        final exIndex = exEntry.key;
                                        final ex = exEntry.value;
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: TextField(
                                                  controller: ex['name'],
                                                  decoration: const InputDecoration(isDense: true, hintText: 'Exercise name'),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                flex: 1,
                                                child: TextField(
                                                  controller: ex['sets'],
                                                  decoration: const InputDecoration(isDense: true, hintText: 'Sets'),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                flex: 1,
                                                child: TextField(
                                                  controller: ex['reps'],
                                                  decoration: const InputDecoration(isDense: true, hintText: 'Reps'),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                flex: 1,
                                                child: TextField(
                                                  controller: ex['rest'],
                                                  decoration: const InputDecoration(isDense: true, hintText: 'Rest'),
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close, size: 18, color: _Colors.textMuted),
                                                onPressed: () => removeExercise(dayIndex, exIndex),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                      TextButton.icon(
                                        onPressed: () => addExercise(dayIndex),
                                        icon: const Icon(Icons.add, size: 16),
                                        label: const Text('Add Exercise'),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              TextButton.icon(
                                onPressed: addDay,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add Another Day'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4D8)),
                              onPressed: saving ? null : handleSave,
                              child: Text(saving ? 'Saving…' : 'Save Program',
                                  style: const TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _dialogInput(TextEditingController controller, {String? hint, int maxLines = 1, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    final List<Map<String, dynamic>> displayedWorkouts = _selectedFilter == 'All'
        ? _allWorkouts
        : _allWorkouts.where((workout) => workout['level'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: _Colors.bg,
      body: SafeArea(
        child: _selectedWorkout == null
            ? _buildMainGridPanel(displayedWorkouts)
            : ProgramDetailEmbeddedWidget(
                programData: _selectedWorkout!,
                onBack: () => setState(() => _selectedWorkout = null),
              ),
      ),
    );
  }

  Widget _buildMainGridPanel(List<Map<String, dynamic>> displayedWorkouts) {
    return Padding(
      padding: const EdgeInsets.only(left: 28.0, right: 28.0, top: 28.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildFilterButton('All'),
              _buildFilterButton('Beginner'),
              _buildFilterButton('Intermediate'),
              _buildFilterButton('Advanced'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openCreateProgramDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4D8),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Create Program', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B4D8)))
                : _loadError != null
                    ? Center(child: Text(_loadError!, style: TextStyle(color: _Colors.textSecondary)))
                    : displayedWorkouts.isEmpty
                        ? Center(
                            child: Text('No programs found.', style: TextStyle(color: _Colors.textSecondary)),
                          )
                        : SingleChildScrollView(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 900),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 420,
                                    mainAxisExtent: 185,
                                    crossAxisSpacing: 32,
                                    mainAxisSpacing: 24,
                                  ),
                                  itemCount: displayedWorkouts.length,
                                  itemBuilder: (context, index) {
                                    final workout = displayedWorkouts[index];
                                    return InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setState(() => _selectedWorkout = workout);
                                      },
                                      child: _buildWorkoutCard(workout),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String text) {
    final bool isActive = _selectedFilter == text;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: OutlinedButton(
        onPressed: () => setState(() => _selectedFilter = text),
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF00B4D8) : _Colors.surface,
          side: BorderSide(color: isActive ? const Color(0xFF00B4D8) : _Colors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : _Colors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(Map<String, dynamic> workout) {
    final imageUrl = workout['imageUrl'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: workout['cardBg'],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: workout['borderColor'], width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (imageUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox(width: 36, height: 36),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            workout['title'],
                            // Fixed (not _Colors.*): this card's background is
                            // workout['cardBg'] -- a per-program pastel color
                            // from the DB that stays light in both themes, so
                            // its text must stay dark regardless of app theme.
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                workout['category'],
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: workout['themeColor']),
              ),
              const SizedBox(height: 8),
              Text(
                workout['description'],
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(workout['duration'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(width: 12),
                  Icon(Icons.flash_on, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 2),
                  Text(workout['frequency'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: workout['badgeBg'], borderRadius: BorderRadius.circular(12)),
                child: Text(
                  workout['level'],
                  style: TextStyle(color: workout['badgeTextColor'], fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==========================================
// KANANG PANEL VIEW WIDGET (EMBEDDED VIEW)
// ==========================================
class ProgramDetailEmbeddedWidget extends StatefulWidget {
  final Map<String, dynamic> programData;
  final VoidCallback onBack;

  const ProgramDetailEmbeddedWidget({
    super.key,
    required this.programData,
    required this.onBack,
  });

  @override
  State<ProgramDetailEmbeddedWidget> createState() => _ProgramDetailEmbeddedWidgetState();
}

class _ProgramDetailEmbeddedWidgetState extends State<ProgramDetailEmbeddedWidget> {
  late String _activeSubTab;

  @override
  void initState() {
    super.initState();
    _activeSubTab = widget.programData['tabs'].isNotEmpty ? widget.programData['tabs'][0] : '';
  }

  @override
  Widget build(BuildContext context) {
    _Colors.sync(context);
    var data = widget.programData;
    List<dynamic> currentExercises = (data['routines'] != null && _activeSubTab.isNotEmpty)
        ? (data['routines'][_activeSubTab] ?? [])
        : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 28.0, right: 28.0, top: 24.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: widget.onBack,
            icon: Icon(Icons.arrow_back, size: 16, color: _Colors.textMuted),
            label: Text('Back to programs', style: TextStyle(color: _Colors.textMuted, fontSize: 14)),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
          ),
          const SizedBox(height: 16),
          if ((data['imageUrl'] as String? ?? '').isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                data['imageUrl'],
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Fixed (not _Colors.*) throughout: this card's background is
          // data['cardBg'] -- a per-program pastel color from the DB that
          // stays light in both themes, so its content must stay dark
          // regardless of app theme.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: data['cardBg'],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: data['borderColor'], width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(data['title'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: data['badgeBg'], borderRadius: BorderRadius.circular(12)),
                      child: Text(data['level'], style: TextStyle(color: data['badgeTextColor'], fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                Text(data['category'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: data['themeColor'])),
                const SizedBox(height: 12),
                Text(data['description'], style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(data['duration'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(width: 14),
                    Icon(Icons.flash_on, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(data['frequency'], style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          if (data['tabs'].isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                ...(data['tabs'] as List<String>).map((tabName) {
                  bool isTabActive = _activeSubTab == tabName;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: ElevatedButton(
                      onPressed: () => setState(() => _activeSubTab = tabName),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isTabActive ? const Color(0xFF00B4D8) : _Colors.surface,
                        foregroundColor: isTabActive ? Colors.white : _Colors.textSecondary,
                        elevation: 0,
                        side: BorderSide(color: isTabActive ? const Color(0xFF00B4D8) : _Colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(tabName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    ),
                  );
                }),
              ],
            ),
          ],
          if (currentExercises.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _Colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Colors.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(_activeSubTab.replaceAll(' - ', ' — '), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  ...currentExercises.map((exercise) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: _Colors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                            alignment: Alignment.center,
                            child: Text(exercise['num'], style: TextStyle(color: data['themeColor'], fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exercise['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Colors.textPrimary)),
                                if ((exercise['tip'] as String).isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tip: ${exercise['tip']}',
                                    style: TextStyle(fontSize: 12, color: _Colors.textMuted, fontStyle: FontStyle.italic),
                                  ),
                                ]
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(exercise['sets'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                              Text('sets', style: TextStyle(fontSize: 11, color: _Colors.textMuted)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(exercise['reps'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00B4D8))),
                              Text('reps', style: TextStyle(fontSize: 11, color: _Colors.textMuted)),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(exercise['rest'], style: TextStyle(fontWeight: FontWeight.bold, color: _Colors.textMuted)),
                              Text('rest', style: TextStyle(fontSize: 11, color: _Colors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                    );
                  })
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
