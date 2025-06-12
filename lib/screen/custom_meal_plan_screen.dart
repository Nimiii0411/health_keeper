import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/daily_meal_model.dart';
import '../models/food_model.dart';
import '../models/nutritional_needs_model.dart';
import '../service/meal_plan_service.dart';
import '../service/user_session.dart';
import '../service/health_diary_service.dart';
import '../service/user_service.dart';

class CustomMealPlanScreen extends StatefulWidget {
  final DateTime selectedDate;
  final DailyMeal? existingMeal;

  const CustomMealPlanScreen({
    super.key,
    required this.selectedDate,
    this.existingMeal,
  });

  @override
  _CustomMealPlanScreenState createState() => _CustomMealPlanScreenState();
}

class _CustomMealPlanScreenState extends State<CustomMealPlanScreen> {
  late List<MealItem> breakfast;
  late List<MealItem> lunch;
  late List<MealItem> dinner;
  
  NutritionalNeeds? nutritionalNeeds;
  List<Food> availableFoods = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedMealType = 'breakfast';
  
  // Nutrition tracking
  double breakfastCalories = 0;
  double lunchCalories = 0;
  double dinnerCalories = 0;
  double breakfastProtein = 0;
  double lunchProtein = 0;
  double dinnerProtein = 0;

  @override
  void initState() {
    super.initState();
    _initializeMeals();
    _loadData();
  }

  void _initializeMeals() {
    if (widget.existingMeal != null) {
      breakfast = List.from(widget.existingMeal!.breakfast);
      lunch = List.from(widget.existingMeal!.lunch);
      dinner = List.from(widget.existingMeal!.dinner);
    } else {
      breakfast = [];
      lunch = [];
      dinner = [];
    }
    _updateNutritionTotals();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      if (!UserSession.hasAccess()) {
        throw Exception('User not logged in');
      }

      final userId = UserSession.currentUserId!;
      
      // Load user's nutritional needs
      final user = await UserService.getUserById(userId);
      if (user == null) throw Exception('User not found');

      final healthData = await HealthDiaryService.getUserHealthDiary(userId);
      if (healthData.isEmpty) throw Exception('No health data found');

      final latestHealth = healthData.first;
      if (latestHealth.bmi == null) throw Exception('No BMI data found');

      final age = Food.calculateAge(user.birthDate);
      
      nutritionalNeeds = MealPlanService.calculateDailyNutritionalNeeds(
        weight: latestHealth.weight,
        height: latestHealth.height,
        age: age,
        gender: user.gender,
        bmi: latestHealth.bmi!,
      );

      // Load available foods
      final bmiCategoryId = await Food.getBMICategoryFromValue(latestHealth.bmi!);
      availableFoods = await MealPlanService.getFoodsByBMICategory(bmiCategoryId);
      
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateNutritionTotals() {
    breakfastCalories = breakfast.fold(0.0, (sum, item) => sum + item.totalCalories);
    lunchCalories = lunch.fold(0.0, (sum, item) => sum + item.totalCalories);
    dinnerCalories = dinner.fold(0.0, (sum, item) => sum + item.totalCalories);
    
    breakfastProtein = breakfast.fold(0.0, (sum, item) => sum + item.totalProtein);
    lunchProtein = lunch.fold(0.0, (sum, item) => sum + item.totalProtein);
    dinnerProtein = dinner.fold(0.0, (sum, item) => sum + item.totalProtein);
  }

  void _addFoodToMeal(Food food, String mealType, double multiplier) {
    final mealItem = MealItem(
      foodId: food.id!,
      foodName: food.foodName,
      mealType: food.mealType,
      quantity: food.servingSize * multiplier,
      unit: food.servingUnit,
      totalCalories: food.calories * multiplier,
      totalProtein: food.protein * multiplier,
      totalFat: food.fat * multiplier,
      totalFiber: food.fiber * multiplier,
      totalCarbs: food.carbs * multiplier,
    );

    setState(() {
      switch (mealType) {
        case 'breakfast':
          breakfast.add(mealItem);
          break;
        case 'lunch':
          lunch.add(mealItem);
          break;
        case 'dinner':
          dinner.add(mealItem);
          break;
      }
      _updateNutritionTotals();
    });
  }

  void _removeFoodFromMeal(int index, String mealType) {
    setState(() {
      switch (mealType) {
        case 'breakfast':
          breakfast.removeAt(index);
          break;
        case 'lunch':
          lunch.removeAt(index);
          break;
        case 'dinner':
          dinner.removeAt(index);
          break;
      }
      _updateNutritionTotals();
    });
  }

  Future<void> _saveMealPlan() async {
    if (nutritionalNeeds == null) return;

    try {
      final userId = UserSession.currentUserId!;
      final dateStr = DateFormat('dd/MM/yyyy').format(widget.selectedDate);
      
      final totalCalories = breakfastCalories + lunchCalories + dinnerCalories;
      final totalProtein = breakfastProtein + lunchProtein + dinnerProtein;
      final totalFat = breakfast.fold(0.0, (sum, item) => sum + item.totalFat) +
                      lunch.fold(0.0, (sum, item) => sum + item.totalFat) +
                      dinner.fold(0.0, (sum, item) => sum + item.totalFat);
      final totalFiber = breakfast.fold(0.0, (sum, item) => sum + item.totalFiber) +
                        lunch.fold(0.0, (sum, item) => sum + item.totalFiber) +
                        dinner.fold(0.0, (sum, item) => sum + item.totalFiber);
      final totalCarbs = breakfast.fold(0.0, (sum, item) => sum + item.totalCarbs) +
                        lunch.fold(0.0, (sum, item) => sum + item.totalCarbs) +
                        dinner.fold(0.0, (sum, item) => sum + item.totalCarbs);

      final dailyMeal = DailyMeal(
        id: widget.existingMeal?.id,
        userId: userId,
        date: dateStr,
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
        snacks: [], // No snacks
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalFat: totalFat,
        totalFiber: totalFiber,
        totalCarbs: totalCarbs,
        mealPlanType: 'custom',
        isCompleted: false,
        completedMeals: [],
        createdAt: widget.existingMeal?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = await MealPlanService.saveDailyMeal(dailyMeal);
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thực đơn tùy chỉnh thành công!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to save meal plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu thực đơn: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
      return Scaffold(
      appBar: AppBar(
        title: Text('Tùy chỉnh thực đơn'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        actions: [
          TextButton(
            onPressed: _saveMealPlan,
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
                _buildNutritionOverview(),
                _buildMealTypeSelector(),
                _buildFoodSearch(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildSelectedMealItems(),
                      ),
                      Expanded(
                        flex: 3,
                        child: _buildAvailableFoods(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  Widget _buildNutritionOverview() {
    final theme = Theme.of(context);
    if (nutritionalNeeds == null) return const SizedBox();

    final totalCalories = breakfastCalories + lunchCalories + dinnerCalories;
    final targetCalories = nutritionalNeeds!.calories;
    final caloriePercentage = (totalCalories / targetCalories * 100).clamp(0, 150);

    return Container(
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Icon(Icons.analytics, color: theme.primaryColor),
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
          const SizedBox(height: 12),
            // Overall progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng calories: ${totalCalories.toStringAsFixed(0)}/${targetCalories.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: caloriePercentage / 100,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        caloriePercentage < 80 ? Colors.orange : 
                        caloriePercentage > 120 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${caloriePercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: caloriePercentage < 80 ? Colors.orange : 
                         caloriePercentage > 120 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Meal breakdown
          Row(
            children: [
              Expanded(
                child: _buildMealNutritionCard(
                  'Sáng',
                  breakfastCalories,
                  nutritionalNeeds!.getBreakfastTarget().calories,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMealNutritionCard(
                  'Trưa',
                  lunchCalories,
                  nutritionalNeeds!.getLunchTarget().calories,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMealNutritionCard(
                  'Tối',
                  dinnerCalories,
                  nutritionalNeeds!.getDinnerTarget().calories,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildMealNutritionCard(String meal, double actual, double target, Color color) {
    final theme = Theme.of(context);
    final percentage = (actual / target * 100).clamp(0, 150);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            meal,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${actual.toStringAsFixed(0)}/${target.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage < 80 ? Colors.orange : 
              percentage > 120 ? Colors.red : color,
            ),
          ),
          const SizedBox(height: 2),
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

  Widget _buildMealTypeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _buildMealTypeTab('breakfast', 'Bữa sáng', Icons.free_breakfast),
          _buildMealTypeTab('lunch', 'Bữa trưa', Icons.lunch_dining),
          _buildMealTypeTab('dinner', 'Bữa tối', Icons.dinner_dining),
        ],
      ),
    );
  }
  Widget _buildMealTypeTab(String type, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = selectedMealType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedMealType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? theme.primaryColor : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFoodSearch() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm thực phẩm...',
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
  Widget _buildSelectedMealItems() {
    final theme = Theme.of(context);
    List<MealItem> currentMealItems;
    String mealName;
    MealNutritionalTarget? target;

    switch (selectedMealType) {
      case 'breakfast':
        currentMealItems = breakfast;
        mealName = 'Bữa sáng';
        target = nutritionalNeeds?.getBreakfastTarget();
        break;
      case 'lunch':
        currentMealItems = lunch;
        mealName = 'Bữa trưa';
        target = nutritionalNeeds?.getLunchTarget();
        break;
      case 'dinner':
        currentMealItems = dinner;
        mealName = 'Bữa tối';
        target = nutritionalNeeds?.getDinnerTarget();
        break;
      default:
        currentMealItems = [];
        mealName = '';
        target = null;
    }    return Container(
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
                  mealName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                if (target != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Mục tiêu: ${target.calories.toStringAsFixed(0)} calories',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Protein: ${target.protein.toStringAsFixed(1)}g',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),          Expanded(
            child: currentMealItems.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có món ăn nào\nThêm món từ danh sách bên phải',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                    ),
                  )
                : ListView.builder(
                    itemCount: currentMealItems.length,
                    itemBuilder: (context, index) {
                      final item = currentMealItems[index];
                      return ListTile(
                        title: Text(
                          item.foodName,
                          style: TextStyle(color: theme.textTheme.titleMedium?.color),
                        ),
                        subtitle: Text(
                          '${item.quantity.toStringAsFixed(1)} ${item.unit} - ${item.totalCalories.toStringAsFixed(0)} cal',
                          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeFoodFromMeal(index, selectedMealType),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  Widget _buildAvailableFoods() {
    final theme = Theme.of(context);
    String mealTypeFilter;
    switch (selectedMealType) {
      case 'breakfast':
        mealTypeFilter = 'Sáng';
        break;
      case 'lunch':
        mealTypeFilter = 'Trưa';
        break;
      case 'dinner':
        mealTypeFilter = 'Tối';
        break;
      default:
        mealTypeFilter = '';
    }

    final filteredFoods = availableFoods.where((food) {
      final matchesSearch = searchQuery.isEmpty ||
          food.foodName.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesMealType = food.mealType == mealTypeFilter;
      return matchesSearch && matchesMealType;
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
            child: Text(
              'Thực phẩm khả dụng (${filteredFoods.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleMedium?.color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredFoods.length,
              itemBuilder: (context, index) {
                final food = filteredFoods[index];
                return ListTile(
                  title: Text(
                    food.foodName,
                    style: TextStyle(color: theme.textTheme.titleMedium?.color),
                  ),
                  subtitle: Text(
                    '${food.calories.toStringAsFixed(0)} cal/${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle, color: theme.primaryColor),
                    onPressed: () => _showAddFoodDialog(food),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  void _showAddFoodDialog(Food food) {
    final theme = Theme.of(context);
    double multiplier = 1.0;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.dialogBackgroundColor,
          title: Text(
            'Thêm ${food.foodName}',
            style: TextStyle(color: theme.textTheme.titleLarge?.color),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Khẩu phần: ${food.servingSize.toStringAsFixed(0)}${food.servingUnit}',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Số lượng: ',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                  Expanded(
                    child: Slider(
                      value: multiplier,
                      min: 0.5,
                      max: 3.0,
                      divisions: 25,
                      label: '${multiplier.toStringAsFixed(1)}x',
                      activeColor: theme.primaryColor,
                      onChanged: (value) => setDialogState(() => multiplier = value),
                    ),
                  ),
                ],
              ),
              Text(
                '${multiplier.toStringAsFixed(1)}x = ${(food.calories * multiplier).toStringAsFixed(0)} calories',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Hủy',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _addFoodToMeal(food, selectedMealType, multiplier);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
