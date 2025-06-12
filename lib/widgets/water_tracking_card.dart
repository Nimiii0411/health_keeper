import 'package:flutter/material.dart';
import '../models/water_tracking_model.dart';
import '../service/water_tracking_service.dart';
import '../service/user_session.dart';

class WaterTrackingCard extends StatefulWidget {
  const WaterTrackingCard({super.key});

  @override
  _WaterTrackingCardState createState() => _WaterTrackingCardState();
}

class _WaterTrackingCardState extends State<WaterTrackingCard> with TickerProviderStateMixin {
  WaterTracking? _waterTracking;
  WaterStreak? _waterStreak;
  bool _isLoading = true;
  final WaterTrackingService _waterService = WaterTrackingService();
  late AnimationController _waveController;
  late AnimationController _dropController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadWaterData();
  }

  void _initializeAnimations() {
    _waveController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _dropController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _waveController.dispose();
    _dropController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final currentUser = UserSession.currentUser;
      if (currentUser == null) return;

      final now = DateTime.now();
      final today = "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";      // Lấy hoặc tạo water tracking cho hôm nay
      WaterTracking? waterTracking = await _waterService.getWaterTrackingByDate(currentUser.idUser, today);
      
      if (waterTracking == null) {
        waterTracking = await _waterService.createWaterTrackingForToday(currentUser.idUser);
      }

      // Lấy streak
      final streak = await _waterService.getWaterStreak(currentUser.idUser);

      if (mounted) {
        setState(() {
          _waterTracking = waterTracking;
          _waterStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi load water data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addWaterIntake(double amount) async {
    if (_waterTracking == null) return;

    try {
      final success = await _waterService.addWaterIntake(
        _waterTracking!.userId,
        _waterTracking!.date,
        amount,
      );

      if (success) {
        _dropController.forward().then((_) => _dropController.reset());
        await _loadWaterData();
        
        if (_waterTracking != null && _waterTracking!.isCompleted) {
          _showCompletionDialog();
        }
      }
    } catch (e) {
      print('❌ Lỗi thêm water intake: $e');
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.orange),
            SizedBox(width: 8),
            Text('🎉 Chúc mừng!'),
          ],
        ),
        content: Text(
          'Bạn đã hoàn thành mục tiêu uống nước hôm nay!\nHãy tiếp tục duy trì thói quen tốt này! 💪',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tuyệt vời!'),
          ),
        ],
      ),
    );
  }

  void _showAddWaterDialog() {
    final amounts = [250, 500, 750, 1000]; // ml
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.local_drink, color: Colors.blue),
            SizedBox(width: 8),
            Text('Thêm lượng nước'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chọn lượng nước đã uống:'),
            SizedBox(height: 16),
            ...amounts.map((amount) => Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addWaterIntake(amount.toDouble());
                },
                icon: Icon(Icons.local_drink),
                label: Text('${amount}ml'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Container(
          height: 180,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_waterTracking == null) {
      return Card(
        child: Container(
          height: 180,
          padding: EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  'Không thể tải dữ liệu uống nước',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loadWaterData,
                  child: Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final percentage = _waterTracking!.completionPercentage;
    final currentLiters = _waterTracking!.currentAmount / 1000;
    final targetLiters = _waterTracking!.targetAmount / 1000;

    return Card(
      elevation: 4,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                AnimatedBuilder(
                  animation: _dropController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _dropController.value * -10),
                      child: Icon(
                        Icons.water_drop,
                        color: Colors.blue,
                        size: 24,
                      ),
                    );
                  },
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uống nước hôm nay',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      if (_waterStreak != null && _waterStreak!.currentStreak > 0)
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, 
                                 color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text(
                              '${_waterStreak!.currentStreak} ngày liên tiếp',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showAddWaterDialog,
                  icon: Icon(Icons.add_circle, color: Colors.blue),
                  iconSize: 28,
                ),
              ],
            ),
            SizedBox(height: 16),

            // Progress Section
            Row(
              children: [
                // Water Wave Animation
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 80,
                    child: Stack(
                      children: [
                        // Background Circle
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue.shade200, width: 2),
                          ),
                        ),
                        // Water Fill
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Container(
                            width: 80,
                            height: 80,
                            child: Stack(
                              children: [
                                // Water Fill
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 500),
                                    width: 80,
                                    height: 80 * (percentage / 100),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.blue.shade300,
                                          Colors.blue.shade500,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Wave Animation
                                AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (context, child) {
                                    return Positioned(
                                      bottom: 80 * (percentage / 100) - 10,
                                      left: -40 + (_waveController.value * 80),
                                      child: Container(
                                        width: 160,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade400,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Percentage Text
                                Center(
                                  child: Text(
                                    '${percentage.toInt()}%',
                                    style: TextStyle(
                                      color: percentage > 50 ? Colors.white : Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Stats
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current / Target
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: '${currentLiters.toStringAsFixed(1)}L',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            TextSpan(
                              text: ' / ${targetLiters.toStringAsFixed(1)}L',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8),

                      // Progress Bar
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.grey[300],
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (percentage / 100).clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),

                      // Status
                      Text(
                        _waterTracking!.isCompleted 
                            ? '🎉 Đã hoàn thành mục tiêu!'
                            : 'Còn ${(targetLiters - currentLiters).toStringAsFixed(1)}L nữa',
                        style: TextStyle(
                          color: _waterTracking!.isCompleted 
                              ? Colors.green.shade700 
                              : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: _waterTracking!.isCompleted 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Recent Intakes (if any)
            if (_waterTracking!.intakes.isNotEmpty) ...[
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Gần đây:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Container(
                height: 30,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _waterTracking!.intakes.length,
                  itemBuilder: (context, index) {
                    final intake = _waterTracking!.intakes[index];
                    final timeStr = "${intake.time.hour.toString().padLeft(2, '0')}:${intake.time.minute.toString().padLeft(2, '0')}";
                    
                    return Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_drink, size: 14, color: Colors.blue.shade700),
                          SizedBox(width: 4),
                          Text(
                            '${intake.amount.toInt()}ml',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}