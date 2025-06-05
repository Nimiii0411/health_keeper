import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  _DiaryScreenState createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> diaryEntries = [
    DiaryEntry(
      date: DateTime.now().subtract(Duration(days: 1)),
      title: 'Tập thể dục buổi sáng',
      content: 'Chạy bộ 30 phút tại công viên',
      mood: 'Tốt',
    ),
    DiaryEntry(
      date: DateTime.now().subtract(Duration(days: 2)),
      title: 'Khám sức khỏe định kỳ',
      content: 'Kiểm tra sức khỏe tổng quát, các chỉ số đều bình thường',
      mood: 'Rất tốt',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      body: Column(
        children: [
          // Header với background gradient
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                  ? [Colors.grey.shade800, Colors.grey.shade700]
                  : [Colors.blue.shade50, Colors.blue.shade100],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.book,
                  size: 24,
                  color: isDark ? Colors.blue.shade300 : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Nhật ký sức khỏe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: () {
                    themeProvider.toggleTheme();
                  },
                ),
              ],
            ),
          ),
          
          // Danh sách entries
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: diaryEntries.length,
              itemBuilder: (context, index) {
                final entry = diaryEntries[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  elevation: isDark ? 8 : 4,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: isDark 
                        ? LinearGradient(
                            colors: [Colors.grey.shade800, Colors.grey.shade700],
                          )
                        : null,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getMoodColor(entry.mood, isDark),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.mood,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            entry.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            entry.content,
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEntryDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getMoodColor(String mood, bool isDark) {
    switch (mood) {
      case 'Rất tốt':
        return Colors.green;
      case 'Tốt':
        return Colors.blue;
      case 'Bình thường':
        return Colors.orange;
      case 'Không tốt':
        return Colors.red;
      default:
        return isDark ? Colors.grey.shade600 : Colors.grey;
    }
  }

  void _showAddEntryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedMood = 'Tốt';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Thêm nhật ký mới'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Nội dung',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedMood,
                      decoration: InputDecoration(
                        labelText: 'Tâm trạng',
                        border: OutlineInputBorder(),
                      ),
                      items: ['Rất tốt', 'Tốt', 'Bình thường', 'Không tốt']
                          .map((mood) => DropdownMenuItem(
                                value: mood,
                                child: Text(mood),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMood = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Thêm'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty &&
                        contentController.text.isNotEmpty) {
                      setState(() {
                        diaryEntries.insert(
                          0,
                          DiaryEntry(
                            date: DateTime.now(),
                            title: titleController.text,
                            content: contentController.text,
                            mood: selectedMood,
                          ),
                        );
                      });
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      setState(() {});
    });
  }
}

class DiaryEntry {
  final DateTime date;
  final String title;
  final String content;
  final String mood;

  DiaryEntry({
    required this.date,
    required this.title,
    required this.content,
    required this.mood,
  });
}
