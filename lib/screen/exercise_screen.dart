import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exercise_model.dart';
import '../service/exercise_service.dart';
import '../service/user_session.dart';
import '../service/health_diary_service.dart';
import 'custom_exercise_plan_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final DateTime? initialDate;
  
  const ExerciseScreen({super.key, this.initialDate});

  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DailyExercisePlan? todayPlan;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String searchQuery = '';
  List<Exercise> searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use the passed date or default to today
    if (widget.initialDate != null) {
      selectedDate = widget.initialDate!;
    }
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    // Load today's exercise plan if user is logged in
    if (UserSession.hasAccess()) {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      
      print('🔍 Loading exercise plan for userId: $userId, date: $dateStr');
      
      todayPlan = await ExerciseService.getDailyExercisePlan(userId, dateStr);
      
      if (todayPlan != null) {
        print('✅ Exercise plan loaded successfully');
        print('🏃 Total calories to burn: ${todayPlan!.totalCaloriesBurned}');
        print('⏱️ Total duration: ${todayPlan!.totalDuration} minutes');
      } else {
        print('❌ No exercise plan found for this date');
      }
    }
    
    // Load all exercises for search tab by default
    await _loadAllExercises();
    
    setState(() => isLoading = false);
  }

  Future<void> _loadAllExercises() async {
    try {
      final allExercises = await ExerciseService.getAllExercises();
      setState(() => searchResults = allExercises);
    } catch (e) {
      print('Error loading all exercises: $e');
    }
  }

  Future<void> _generateAutoExercisePlan() async {
    if (!UserSession.hasAccess()) {
      _showDialog('Lỗi', 'Vui lòng đăng nhập để sử dụng tính năng này');
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      final newPlan = await ExerciseService.generateAutoExercisePlan(userId, dateStr);
      
      if (newPlan != null) {
        setState(() {
          todayPlan = newPlan;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo kế hoạch tập luyện tự động thành công!')),
        );      } else {
        String errorMessage = 'Không thể tạo kế hoạch tập luyện.';
        
        // Check for specific error types
        final userId = UserSession.currentUserId!;
        final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
        
        // Check if health diary exists
        final healthData = await HealthDiaryService.getUserHealthDiary(userId);
        final healthForDate = healthData.where((health) => health.entryDate == dateStr).toList();
        
        if (healthForDate.isEmpty) {
          errorMessage = 'Vui lòng tạo nhật ký sức khỏe cho ngày ${dateStr} trước khi tạo kế hoạch tập luyện.';
        } else {
          errorMessage = 'Kế hoạch tập luyện phải có ít nhất 1 bài tập khác với ngày hôm trước.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty) {
      // Show all exercises when search is empty
      await _loadAllExercises();
      return;
    }
    
    final results = await ExerciseService.searchExercisesByName(query);
    setState(() => searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quản lý tập luyện',
          style: TextStyle(
            color: theme.appBarTheme.foregroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: theme.appBarTheme.iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: theme.appBarTheme.iconTheme?.color,
            ),
            onPressed: () => _selectDate(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.appBarTheme.foregroundColor,
          unselectedLabelColor: theme.appBarTheme.foregroundColor?.withOpacity(0.6),
          indicatorColor: theme.appBarTheme.foregroundColor,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Kế hoạch hôm nay'),
            Tab(icon: Icon(Icons.search), text: 'Tìm kiếm bài tập'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayPlanTab(),
                _buildSearchTab(),
              ],
            ),
    );
  }

  Widget _buildTodayPlanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateHeader(),
          const SizedBox(height: 16),
          if (todayPlan == null) _buildNoPlan() else _buildExercisePlan(),
        ],
      ),
    );
  }

  Widget _buildDateHeader() {
    final theme = Theme.of(context);
    final isToday = DateFormat('dd/MM/yyyy').format(selectedDate) == 
                   DateFormat('dd/MM/yyyy').format(DateTime.now());
    
    return Container(
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
      child: Row(
        children: [
          Icon(
            Icons.today,
            color: theme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,              children: [
                Text(
                  isToday ? 'Hôm nay' : DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                if (!isToday)
                  Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
              ],
            ),
          ),
          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Hôm nay',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoPlan() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
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
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có kế hoạch tập luyện',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo kế hoạch tập luyện để bắt đầu hành trình khỏe mạnh của bạn',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _generateAutoExercisePlan(),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Tạo tự động'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showCreateCustomPlanDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Tạo tùy chỉnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExercisePlan() {
    return Column(
      children: [
        _buildPlanSummary(),
        const SizedBox(height: 16),
        _buildExercisesList(),
        const SizedBox(height: 24),
        _buildPlanActions(),
      ],
    );
  }

  Widget _buildPlanSummary() {
    final theme = Theme.of(context);
    
    return Container(
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
          Row(
            children: [
              Icon(Icons.assessment, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Tổng quan kế hoạch',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  todayPlan!.planType == 'auto' ? 'Tự động' : 'Tùy chỉnh',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Calories đốt cháy',
                  '${todayPlan!.totalCaloriesBurned}',
                  'cal',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Thời gian',
                  '${todayPlan!.totalDuration}',
                  'phút',
                  Icons.timer,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Bài tập',
                  '${todayPlan!.exercises.length}',
                  'bài',
                  Icons.fitness_center,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Hoàn thành',
                  '${todayPlan!.completedExercises.length}/${todayPlan!.exercises.length}',
                  '',
                  Icons.check_circle,
                  todayPlan!.isCompleted ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 12,
                      color: color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    final theme = Theme.of(context);
    
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Danh sách bài tập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayPlan!.exercises.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              final exercise = todayPlan!.exercises[index];
              final isCompleted = todayPlan!.completedExercises.contains(exercise.exerciseName);
              
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.fitness_center,
                    color: isCompleted ? Colors.white : theme.primaryColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  exercise.exerciseName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted 
                      ? theme.textTheme.bodyMedium?.color?.withOpacity(0.6)
                      : theme.textTheme.titleMedium?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${exercise.sets > 1 ? '${exercise.sets} sets × ${exercise.repsPerSet} reps' : '${exercise.durationMinutes} phút'} • ${exercise.caloriesBurned} cal',
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getIntensityColor(exercise.intensity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${exercise.exerciseType} • ${exercise.intensity}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getIntensityColor(exercise.intensity),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: isCompleted 
                  ? Icon(Icons.check_circle, color: Colors.green)
                  : IconButton(
                      icon: Icon(Icons.play_circle_outline, color: theme.primaryColor),
                      onPressed: () => _startExercise(exercise),
                    ),
                onTap: isCompleted ? null : () => _startExercise(exercise),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Widget _buildPlanActions() {
    final theme = Theme.of(context);
    
    return Container(
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
            'Hành động',
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
                child: ElevatedButton.icon(
                  onPressed: () => _showEditPlanDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Chỉnh sửa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: todayPlan != null ? () => _showDeletePlanDialog() : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa kế hoạch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: todayPlan != null ? Colors.red[600] : theme.disabledColor,
                    side: BorderSide(color: todayPlan != null ? Colors.red[600]! : theme.disabledColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTab() {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tìm kiếm bài tập',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Nhập tên bài tập...',
              prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            ),
            onChanged: (value) {
              setState(() => searchQuery = value);
              _searchExercises(value);
            },
          ),
          const SizedBox(height: 16),
          if (searchResults.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final exercise = searchResults[index];
                return _buildExerciseCard(exercise);
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không tìm thấy bài tập nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showExerciseInfoDialog(exercise),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 40,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                exercise.exerciseName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${exercise.caloriesPerSet} cal/set',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseInfoDialog(Exercise exercise) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(exercise.exerciseName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Calories per set: ${exercise.caloriesPerSet} cal',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Thêm bài tập này vào kế hoạch tùy chỉnh để bắt đầu tập luyện.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Thêm vào kế hoạch'),
              onPressed: () {
                Navigator.of(context).pop();
                _addToCustomPlan(exercise);
              },
            ),
          ],
        );
      },
    );
  }

  void _addToCustomPlan(Exercise exercise) {
    // Navigate to custom plan screen with this exercise
    _showCreateCustomPlanDialog();
  }

  void _startExercise(ExerciseItem exercise) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bắt đầu ${exercise.exerciseName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                exercise.sets > 1 
                  ? 'Thực hiện ${exercise.sets} sets × ${exercise.repsPerSet} reps'
                  : 'Tập luyện trong ${exercise.durationMinutes} phút',
              ),
              const SizedBox(height: 8),
              const Text('Nhấn "Hoàn thành" khi bạn đã tập xong!'),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text('Hoàn thành'),
              onPressed: () async {
                Navigator.of(context).pop();
                await _markExerciseCompleted(exercise.exerciseName);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _markExerciseCompleted(String exerciseName) async {
    if (todayPlan?.id == null) return;
    
    final success = await ExerciseService.markExerciseCompleted(
      todayPlan!.id!,
      exerciseName,
    );
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hoàn thành $exerciseName! Tuyệt vời!')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadData();
    }
  }
  void _showCreateCustomPlanDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomExercisePlanScreen(
          selectedDate: selectedDate,
          existingPlan: todayPlan,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Reload data if plan was saved
      }
    });
  }

  void _showEditPlanDialog() {
    if (todayPlan == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomExercisePlanScreen(
          selectedDate: selectedDate,
          existingPlan: todayPlan,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Reload data if plan was saved
      }
    });
  }

  void _showDeletePlanDialog() {
    if (todayPlan == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa kế hoạch tập luyện này?\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _deleteExercisePlan(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExercisePlan() async {
    if (todayPlan?.id == null) return;

    Navigator.pop(context); // Close dialog

    try {
      final success = await ExerciseService.deleteExercisePlan(todayPlan!.id!);
      
      if (success) {
        setState(() => todayPlan = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa kế hoạch tập luyện thành công!')),
        );
      } else {
        throw Exception('Failed to delete exercise plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa kế hoạch: $e')),
      );
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
