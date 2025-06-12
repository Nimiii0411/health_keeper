import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_meal_model.dart';
import '../models/food_model.dart';
import '../service/meal_plan_service.dart';
import '../service/user_session.dart';
import 'custom_meal_plan_screen.dart';

class FoodScreen extends StatefulWidget {
  final DateTime? initialDate;
  
  const FoodScreen({super.key, this.initialDate});

  @override
  _FoodScreenState createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  DailyMeal? todayMeal;
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  String searchQuery = '';
  List<Food> searchResults = [];  @override
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
  }  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    // Load today's meal plan if user is logged in
    if (UserSession.hasAccess()) {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      
      // Debug: Kiểm tra cấu trúc database
      print('🔍 Loading meal for userId: $userId, date: $dateStr');
      await MealPlanService.debugDatabaseStructure();
      await MealPlanService.debugDailyMeals(userId, dateStr);
      
      todayMeal = await MealPlanService.getDailyMealByUserId(userId, dateStr);
      
      if (todayMeal != null) {
        print('✅ Meal loaded successfully');
        print('🍽️ Total calories: ${todayMeal!.totalCalories}');
        print('👤 User ID: ${todayMeal!.userId}');
      } else {
        print('❌ No meal found for this date');
      }
    }
    
    // Load all foods for search tab by default
    await _loadAllFoods();
    
    setState(() => isLoading = false);
  }

  Future<void> _loadAllFoods() async {
    try {
      final allFoods = await MealPlanService.getAllFoodCatalog();
      setState(() => searchResults = allFoods);
    } catch (e) {
      print('Error loading all foods: $e');
    }
  }Future<void> _generateAutoMealPlan() async {
    if (!UserSession.hasAccess()) {
      _showDialog('Lỗi', 'Vui lòng đăng nhập để sử dụng tính năng này');
      return;
    }
    
    setState(() => isLoading = true);
    
    try {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
      final newMeal = await MealPlanService.generateAutoMealPlan(userId, dateStr);
        if (newMeal != null) {
        setState(() {
          todayMeal = newMeal;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tạo thực đơn tự động thành công!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tạo thực đơn. Vui lòng kiểm tra thông tin sức khỏe của bạn.')),
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
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      // Show all foods when search is empty
      await _loadAllFoods();
      return;
    }
    
    final results = await MealPlanService.searchFoods(
      query, 
      // bmi: currentUser?.bmi, // Commented temporarily
    );
    setState(() => searchResults = results);
  }  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quản lý thực đơn',
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
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Thực đơn hôm nay'),
            Tab(icon: Icon(Icons.search), text: 'Tìm kiếm thực phẩm'),
          ],
        ),
      ),body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayMealTab(),
                _buildSearchTab(),
              ],
            ),
    );
  }

  Widget _buildTodayMealTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [          _buildDateHeader(),
          const SizedBox(height: 16),
          // if (currentUser != null) _buildBMIInfo(), // Commented temporarily
          const SizedBox(height: 16),
          if (todayMeal == null) _buildNoMealPlan() else _buildMealPlan(),
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
          Icon(Icons.calendar_today, color: theme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                if (isToday)
                  Text(
                    'Hôm nay',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryColor),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }
  Widget _buildNoMealPlan() {
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
            Icons.restaurant_menu,
            size: 64,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thực đơn cho ngày này',
            style: TextStyle(
              fontSize: 18,
              color: theme.textTheme.titleMedium?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tạo thực đơn tự động dựa trên BMI của bạn',
            style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generateAutoMealPlan,
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
                  onPressed: () => _showCreateCustomMealDialog(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Tạo tùy chỉnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.primaryColor,
                    side: BorderSide(color: theme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: todayMeal != null ? () => _showDeleteMealDialog() : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Xóa thực đơn'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: todayMeal != null ? Colors.red[600] : theme.disabledColor,
                    side: BorderSide(color: todayMeal != null ? Colors.red[600]! : theme.disabledColor),
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

  Widget _buildMealPlan() {
    return Column(
      children: [
        _buildNutritionSummary(),
        const SizedBox(height: 16),
        _buildMealSection('Bữa sáng', todayMeal!.breakfast, 'breakfast'),
        const SizedBox(height: 12),
        _buildMealSection('Bữa trưa', todayMeal!.lunch, 'lunch'),
        const SizedBox(height: 12),        _buildMealSection('Bữa tối', todayMeal!.dinner, 'dinner'),
        const SizedBox(height: 24),
        _buildMealActions(),
      ],
    );
  }
  Widget _buildNutritionSummary() {
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
                'Tổng quan dinh dưỡng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  'Calories',
                  todayMeal!.totalCalories.toStringAsFixed(0),
                  'kcal',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  'Protein',
                  todayMeal!.totalProtein.toStringAsFixed(1),
                  'g',
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem(
                  'Carbs',
                  todayMeal!.totalCarbs.toStringAsFixed(1),
                  'g',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildNutritionItem(
                  'Fat',
                  todayMeal!.totalFat.toStringAsFixed(1),
                  'g',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }  Widget _buildNutritionItem(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMealSection(String title, List<MealItem> meals, String mealType) {
    final theme = Theme.of(context);
    final isCompleted = todayMeal!.completedMeals.contains(mealType);
    
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCompleted ? theme.primaryColor.withOpacity(0.1) : null,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getMealIcon(mealType),
                  color: isCompleted ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? theme.primaryColor : theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ),                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Hoàn thành',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.check_circle_outline, 
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                    onPressed: () => _markMealCompleted(mealType),
                  ),
              ],
            ),
          ),
          if (meals.isNotEmpty)
            ...meals.map((meal) => _buildMealItem(meal))          else
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có món ăn cho bữa này',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
            ),
        ],
      ),
    );
  }  Widget _buildMealItem(MealItem meal) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)), // Simplified since no image field
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.foodName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.quantity.toStringAsFixed(1)} ${meal.unit}',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${meal.totalCalories.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildMealActions() {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showEditMealDialog(),
            icon: const Icon(Icons.edit),
            label: const Text('Chỉnh sửa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryColor,
              side: BorderSide(color: theme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _generateAutoMealPlan,
            icon: const Icon(Icons.refresh),
            label: const Text('Tạo lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildSearchTab() {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.scaffoldBackgroundColor,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Tìm kiếm thực phẩm...',
              prefixIcon: Icon(Icons.search, color: theme.textTheme.bodyMedium?.color),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor ?? theme.cardColor,
            ),
            onChanged: _searchFoods,
          ),
        ),        Expanded(
          child: searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy thực phẩm nào',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final food = searchResults[index];
                    return _buildFoodSearchItem(food);
                  },
                ),
        ),
      ],
    );
  }
  Widget _buildFoodSearchItem(Food food) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: food.image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      food.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.restaurant, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                    ),
                  )
                : Icon(Icons.restaurant, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.foodName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  food.mealTypeDisplayName,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${food.calories.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[600]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        food.bmiCategoryDisplayName,
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.primaryColor),
            onPressed: () => _addFoodToMeal(food),
          ),
        ],
      ),
    );  }

  // Helper methods
  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snacks':
        return Icons.cake;
      default:
        return Icons.restaurant;
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

  Future<void> _markMealCompleted(String mealType) async {
    if (todayMeal?.id == null) return;
    
    final success = await MealPlanService.markMealCompleted(
      todayMeal!.id!,
      mealType,
    );
    
    if (success) {
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đánh dấu hoàn thành bữa ăn')),
      );
    }
  }
  void _showCreateCustomMealDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMealPlanScreen(
          selectedDate: selectedDate,
          existingMeal: todayMeal,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Reload data if meal plan was saved
      }
    });
  }

  void _showEditMealDialog() {
    if (todayMeal == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomMealPlanScreen(
          selectedDate: selectedDate,
          existingMeal: todayMeal,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData(); // Reload data if meal plan was saved
      }
    });
  }

  void _showDeleteMealDialog() {
    if (todayMeal == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa thực đơn này?\n'
          'Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _deleteMealPlan(),
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

  Future<void> _deleteMealPlan() async {
    if (todayMeal?.id == null) return;

    Navigator.pop(context); // Close dialog

    try {
      final success = await MealPlanService.deleteMealPlan(todayMeal!.id!);
      
      if (success) {
        setState(() => todayMeal = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thực đơn thành công!')),
        );
      } else {
        throw Exception('Failed to delete meal plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa thực đơn: $e')),
      );
    }
  }void _addFoodToMeal(Food food) {
    // TODO: Implement add food to meal functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thêm ${food.foodName} vào thực đơn (đang phát triển)')),
    );
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
        );      },
    );
  }
}