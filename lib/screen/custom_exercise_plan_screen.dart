import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_model.dart';
import '../service/exercise_service.dart';
import '../service/user_session.dart';
import '../service/health_diary_service.dart';
import '../service/user_service.dart';

class CustomExercisePlanScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DailyExercisePlan? existingPlan;

  const CustomExercisePlanScreen({
    super.key,
    required this.selectedDate,
    this.existingPlan,
  });

  @override
  _CustomExercisePlanScreenState createState() => _CustomExercisePlanScreenState();
}

class _CustomExercisePlanScreenState extends State<CustomExercisePlanScreen> {
  late List<ExerciseItem> exercises;
  
  ExerciseNeeds? exerciseNeeds;
  List<Exercise> availableExercises = [];
  bool isLoading = true;
  String searchQuery = '';
  
  // Exercise tracking
  int totalCaloriesBurned = 0;
  int totalDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeExercises();
    _loadData();
  }

  void _initializeExercises() {
    if (widget.existingPlan != null) {
      exercises = List.from(widget.existingPlan!.exercises);
    } else {
      exercises = [];
    }
    _updateTotals();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      if (!UserSession.hasAccess()) {
        throw Exception('User not logged in');
      }

      final userId = UserSession.currentUserId!;
      
      // Load user's exercise needs
      final user = await UserService.getUserById(userId);
      if (user == null) throw Exception('User not found');

      final healthData = await HealthDiaryService.getUserHealthDiary(userId);
      if (healthData.isEmpty) throw Exception('No health data found');

      final latestHealth = healthData.first;
      if (latestHealth.bmi == null) throw Exception('No BMI data found');

      final age = _calculateAge(user.birthDate);
      
      exerciseNeeds = ExerciseService.calculateDailyExerciseNeeds(
        weight: latestHealth.weight,
        height: latestHealth.height,
        age: age,
        gender: user.gender,
        bmi: latestHealth.bmi!,
        fitnessLevel: 'beginner', // Could be stored in user profile
      );

      // Load available exercises
      availableExercises = await ExerciseService.getAllExercises();
      
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateTotals() {
    totalCaloriesBurned = exercises.fold(0, (sum, item) => sum + item.caloriesBurned);
    totalDuration = exercises.fold(0, (sum, item) => sum + item.durationMinutes);
  }

  void _addExerciseToList(Exercise exercise, int sets, int reps, int duration, String intensity) {
    final exerciseItem = ExerciseItem(
      exerciseId: exercise.id!,
      exerciseName: exercise.exerciseName,
      exerciseType: 'Custom', // Default type for custom exercises
      sets: sets,
      repsPerSet: reps,
      durationMinutes: duration,
      caloriesBurned: (exercise.caloriesPerSet * sets).clamp(50, 500),
      intensity: intensity,
    );

    setState(() {
      exercises.add(exerciseItem);
      _updateTotals();
    });
  }

  void _removeExerciseFromList(int index) {
    setState(() {
      exercises.removeAt(index);
      _updateTotals();
    });
  }

  Future<void> _saveExercisePlan() async {
    if (exerciseNeeds == null) return;

    try {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(widget.selectedDate);

      final dailyExercisePlan = DailyExercisePlan(
        id: widget.existingPlan?.id,
        userId: userId,
        date: dateStr,
        exercises: exercises,
        totalCaloriesBurned: totalCaloriesBurned,
        totalDuration: totalDuration,
        planType: 'custom',
        isCompleted: false,
        completedExercises: [],
        createdAt: widget.existingPlan?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await ExerciseService.saveDailyExercisePlan(dailyExercisePlan);
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kế hoạch tập luyện tùy chỉnh thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save exercise plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu kế hoạch: $e')),
      );
    }
  }

  int _calculateAge(String birthDate) {
    try {
      // birthDate format: "dd/MM/yyyy"
      final parts = birthDate.split('/');
      if (parts.length != 3) return 25; // default age
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final birth = DateTime(year, month, day);
      final now = DateTime.now();
      
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      
      return age;
    } catch (e) {
      print('❌ Error calculating age: $e');
      return 25; // default age
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Scaffold(
      appBar: AppBar(
        title: const Text('Tùy chỉnh kế hoạch tập luyện'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _saveExercisePlan,
            child: Text(
              'Lưu',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildExerciseOverview(),
                _buildExerciseSearch(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildSelectedExercises(),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildAvailableExercises(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExerciseOverview() {
    final theme = Theme.of(context);
    if (exerciseNeeds == null) return const SizedBox();

    final targetCalories = exerciseNeeds!.targetCaloriesToBurn;
    final targetDuration = exerciseNeeds!.recommendedDuration;
    
    final caloriesProgress = totalCaloriesBurned / targetCalories;
    final durationProgress = totalDuration / targetDuration;

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan kế hoạch',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Calories đốt cháy',
                  totalCaloriesBurned,
                  targetCalories,
                  'cal',
                  caloriesProgress,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  'Thời gian',
                  totalDuration,
                  targetDuration,
                  'phút',
                  durationProgress,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Khuyến nghị: ${exerciseNeeds!.recommendedTypes.join(", ")}',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            'Cường độ: ${exerciseNeeds!.intensity} • ${exerciseNeeds!.sessionsPerWeek} buổi/tuần',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, int current, int target, String unit, double progress, Color color) {
    final theme = Theme.of(context);
    final percentage = (progress * 100).clamp(0, 999);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 4),
          Text(
            '$current/$target $unit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: percentage < 80 ? Colors.orange : 
                     percentage > 120 ? Colors.red : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSearch() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm bài tập...',
          prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primaryColor),
          ),
          filled: true,
          fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
        ),
        onChanged: (value) => setState(() => searchQuery = value),
      ),
    );
  }

  Widget _buildSelectedExercises() {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bài tập đã chọn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercises.length} bài tập • ${totalCaloriesBurned} cal • ${totalDuration} phút',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có bài tập nào',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return ListTile(
                        title: Text(
                          exercise.exerciseName,
                          style: TextStyle(color: theme.textTheme.titleMedium?.color),
                        ),
                        subtitle: Text(
                          '${exercise.sets > 1 ? '${exercise.sets} sets × ${exercise.repsPerSet} reps' : '${exercise.durationMinutes} phút'} • ${exercise.caloriesBurned} cal',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeExerciseFromList(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableExercises() {
    final theme = Theme.of(context);

    final filteredExercises = availableExercises.where((exercise) {
      final matchesSearch = searchQuery.isEmpty ||
          exercise.exerciseName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600]!.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bài tập có sẵn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filteredExercises.length} bài tập',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Không tìm thấy bài tập',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          exercise.exerciseName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                        subtitle: Text(
                          '${exercise.caloriesPerSet} cal/set',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.add_circle,
                            color: theme.primaryColor,
                          ),
                          onPressed: () => _showAddExerciseDialog(exercise),
                        ),
                        onTap: () => _showAddExerciseDialog(exercise),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(Exercise exercise) {
    int sets = 3;
    int reps = 10;
    int duration = 15;
    String intensity = 'Moderate';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Thêm ${exercise.exerciseName}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sets: $sets'),
                  Slider(
                    value: sets.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (value) => setDialogState(() => sets = value.round()),
                  ),
                  Text('Reps per set: $reps'),
                  Slider(
                    value: reps.toDouble(),
                    min: 1,
                    max: 50,
                    divisions: 49,
                    onChanged: (value) => setDialogState(() => reps = value.round()),
                  ),
                  Text('Duration: $duration phút'),
                  Slider(
                    value: duration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    onChanged: (value) => setDialogState(() => duration = value.round()),
                  ),
                  DropdownButtonFormField<String>(
                    value: intensity,
                    decoration: const InputDecoration(labelText: 'Cường độ'),
                    items: ['Low', 'Moderate', 'High'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => intensity = value!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addExerciseToList(exercise, sets, reps, duration, intensity);
                    Navigator.pop(context);
                  },
                  child: const Text('Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
