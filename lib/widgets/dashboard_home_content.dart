import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../service/user_session.dart';
import '../service/health_diary_service.dart';
import '../models/health_diary_model.dart';

class DashboardHomeContent extends StatefulWidget {
  final Function(int) onNavigate;

  const DashboardHomeContent({super.key, required this.onNavigate});

  @override
  _DashboardHomeContentState createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  HealthDiary? latestHealthData;
  bool isLoading = true;
  String selectedPeriod = 'Tháng'; // Tuần, Tháng, 3 Tháng, 6 Tháng
  
  // Data for health metrics chart
  List<HealthDiary> healthHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  DateTime _parseDate(String dateStr) {
    try {
      List<String> parts = dateStr.split('/');
      if (parts.length == 3) {
        int day = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        int year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('❌ Lỗi parse date: $e');
    }
    return DateTime.now();
  }

  Future<void> _loadHealthData() async {
    if (!UserSession.hasAccess()) return;

    if (mounted) {
      setState(() => isLoading = true);
    }
    
    final userId = UserSession.currentUserId!;

    try {
      // Load latest health data
      final userHealthHistory = await HealthDiaryService.getUserHealthDiary(userId);
      HealthDiary? latestHealth;
      if (userHealthHistory.isNotEmpty) {
        userHealthHistory.sort((a, b) {
          DateTime dateA = _parseDate(a.entryDate);
          DateTime dateB = _parseDate(b.entryDate);
          return dateB.compareTo(dateA);
        });
        latestHealth = userHealthHistory.first;
      }

      // Load health chart data based on selected period
      await _loadChartData(userId);

      if (mounted) {
        setState(() {
          latestHealthData = latestHealth;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Lỗi khi load dữ liệu health: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadChartData(int userId) async {
    try {
      final today = DateTime.now();
      int daysBack;
      
      switch (selectedPeriod) {
        case 'Tuần':
          daysBack = 7;
          break;
        case 'Tháng':
          daysBack = 30;
          break;
        case '3 Tháng':
          daysBack = 90;
          break;
        case '6 Tháng':
          daysBack = 180;
          break;
        default:
          daysBack = 30;
      }

      // Load health history for chart
      final allHealthData = await HealthDiaryService.getUserHealthDiary(userId);
      healthHistory = allHealthData.where((entry) {
        DateTime entryDate = _parseDate(entry.entryDate);
        return today.difference(entryDate).inDays <= daysBack;
      }).toList();
      
      healthHistory.sort((a, b) {
        DateTime dateA = _parseDate(a.entryDate);
        DateTime dateB = _parseDate(b.entryDate);
        return dateA.compareTo(dateB);
      });
      
    } catch (e) {
      print('❌ Lỗi khi load chart data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadHealthData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            SizedBox(height: 20),
            _buildLatestHealthInfo(),
            SizedBox(height: 20),
            _buildHealthChart(),
            SizedBox(height: 20),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Tổng Quan Sức Khỏe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Chào mừng ${UserSession.getDisplayName()}!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Theo dõi chỉ số sức khỏe của bạn',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestHealthInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Thông tin sức khỏe gần nhất',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (latestHealthData == null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.health_and_safety_outlined, 
                         size: 48, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có dữ liệu sức khỏe',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => widget.onNavigate(2),
                      child: Text('Thêm dữ liệu'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Ngày ghi nhận',
                          latestHealthData!.entryDate,
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'Cân nặng',
                          '${latestHealthData!.weight.toStringAsFixed(1)} kg',
                          Icons.monitor_weight,
                          Colors.green,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          'Chiều cao',
                          '${latestHealthData!.height.toStringAsFixed(1)} cm',
                          Icons.height,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          'BMI',
                          latestHealthData!.bmi?.toStringAsFixed(1) ?? '--',
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoItem(
                          'Phân loại',
                          _getBMICategory(latestHealthData!.bmi ?? 0),
                          Icons.assessment,
                          _getBMIColor(latestHealthData!.bmi ?? 0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25) return 'Bình thường';
    if (bmi < 30) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildHealthChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.show_chart, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Biểu đồ sức khỏe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                DropdownButton<String>(
                  value: selectedPeriod,
                  items: ['Tuần', 'Tháng', '3 Tháng', '6 Tháng']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null && mounted) {
                      setState(() {
                        selectedPeriod = newValue;
                      });
                      _loadChartData(UserSession.currentUserId!);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            healthHistory.isEmpty
                ? Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, 
                               size: 48, color: Colors.grey[400]),
                          SizedBox(height: 8),
                          Text(
                            'Chưa có dữ liệu để hiển thị biểu đồ',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => widget.onNavigate(2),
                            child: Text('Thêm dữ liệu'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Biểu đồ Cân nặng
                      _buildWeightChart(),
                      SizedBox(height: 20),
                      // Biểu đồ Chiều cao
                      _buildHeightChart(),
                      SizedBox(height: 20),
                      // Biểu đồ BMI
                      _buildBMIChart(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'Hành động nhanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              title: 'Thêm nhật ký',
              icon: Icons.add_circle,
              color: Colors.green,
              onTap: () => widget.onNavigate(2),
            ),
            _buildActionCard(
              title: 'Xem thực đơn',
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              onTap: () => widget.onNavigate(3),
            ),
            _buildActionCard(
              title: 'Bắt đầu tập',
              icon: Icons.play_arrow,
              color: Colors.red,
              onTap: () => widget.onNavigate(4),
            ),
            _buildActionCard(
              title: 'Đặt nhắc nhở',
              icon: Icons.alarm_add,
              color: Colors.purple,
              onTap: () => widget.onNavigate(5),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Cân nặng (kg)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: healthHistory
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.weight,
                            ))
                        .toList(),
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}kg',
                          style: TextStyle(fontSize: 10, color: Colors.green[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: healthHistory.length > 10 ? (healthHistory.length / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < healthHistory.length) {
                          final date = _parseDate(healthHistory[index].entryDate);
                          return Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.green.withOpacity(0.3))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightChart() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.height, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Chiều cao (cm)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: healthHistory
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value.height,
                            ))
                        .toList(),
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toStringAsFixed(0)}cm',
                          style: TextStyle(fontSize: 10, color: Colors.orange[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: healthHistory.length > 10 ? (healthHistory.length / 5).ceil().toDouble() : 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < healthHistory.length) {
                          final date = _parseDate(healthHistory[index].entryDate);
                          return Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.orange.withOpacity(0.3))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIChart() {
    final bmiData = healthHistory.where((entry) => entry.bmi != null).toList();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple, size: 20),
              SizedBox(width: 8),
              Text(
                'BMI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            height: 180,
            child: bmiData.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có dữ liệu BMI',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: bmiData
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value.bmi!,
                                  ))
                              .toList(),
                          isCurved: true,
                          color: Colors.purple,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.purple.withOpacity(0.1),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(fontSize: 10, color: Colors.purple[600]),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: bmiData.length > 10 ? (bmiData.length / 5).ceil().toDouble() : 1,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < bmiData.length) {
                                final date = _parseDate(bmiData[index].entryDate);
                                return Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Text(
                                    '${date.day}/${date.month}',
                                    style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                                  ),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.purple.withOpacity(0.3))),
                      // Thêm các đường tham chiếu BMI
                      extraLinesData: ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: 18.5,
                            color: Colors.blue.withOpacity(0.5),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                          HorizontalLine(
                            y: 25,
                            color: Colors.green.withOpacity(0.5),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                          HorizontalLine(
                            y: 30,
                            color: Colors.orange.withOpacity(0.5),
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 8),
          // BMI Reference
          Wrap(
            spacing: 8,
            children: [
              _buildBMIReference('< 18.5 Thiếu cân', Colors.blue),
              _buildBMIReference('18.5-25 Bình thường', Colors.green),
              _buildBMIReference('25-30 Thừa cân', Colors.orange),
              _buildBMIReference('> 30 Béo phì', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBMIReference(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
