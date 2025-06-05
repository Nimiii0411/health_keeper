import 'package:flutter/material.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<Exercise> exercises = [
    Exercise(
      name: 'Chạy bộ',
      duration: 30,
      calories: 300,
      icon: Icons.directions_run,
      color: Colors.orange,
    ),
    Exercise(
      name: 'Đẩy tạ',
      duration: 45,
      calories: 250,
      icon: Icons.fitness_center,
      color: Colors.purple,
    ),
    Exercise(
      name: 'Yoga',
      duration: 60,
      calories: 200,
      icon: Icons.self_improvement,
      color: Colors.green,
    ),
    Exercise(
      name: 'Bơi lội',
      duration: 40,
      calories: 400,
      icon: Icons.pool,
      color: Colors.blue,
    ),
  ];

  List<ExerciseSession> completedSessions = [
    ExerciseSession(
      exerciseName: 'Chạy bộ',
      date: DateTime.now().subtract(Duration(days: 1)),
      duration: 25,
      calories: 250,
    ),
    ExerciseSession(
      exerciseName: 'Yoga',
      date: DateTime.now().subtract(Duration(days: 2)),
      duration: 45,
      calories: 150,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: AppBar(
            automaticallyImplyLeading: false,
            bottom: TabBar(
              tabs: [
                Tab(text: 'Bài tập'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildExerciseTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn bài tập',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  elevation: 4,
                  child: InkWell(
                    onTap: () => _showExerciseDialog(exercise),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            exercise.icon,
                            size: 48,
                            color: exercise.color,
                          ),
                          SizedBox(height: 8),
                          Text(
                            exercise.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${exercise.duration} phút',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${exercise.calories} cal',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
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
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lịch sử tập luyện',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: completedSessions.length,
              itemBuilder: (context, index) {
                final session = completedSessions[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                    title: Text(session.exerciseName),
                    subtitle: Text(
                      '${session.date.day}/${session.date.month}/${session.date.year} - ${session.duration} phút',
                    ),
                    trailing: Text(
                      '${session.calories} cal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Bắt đầu ${exercise.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                exercise.icon,
                size: 64,
                color: exercise.color,
              ),
              SizedBox(height: 16),
              Text(
                'Thời gian: ${exercise.duration} phút',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Calories đốt cháy: ${exercise.calories} cal',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Bắt đầu'),
              onPressed: () {
                Navigator.of(context).pop();
                _startExercise(exercise);
              },
            ),
          ],
        );
      },
    );
  }

  void _startExercise(Exercise exercise) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đang tập ${exercise.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Hãy tập luyện và nhấn "Hoàn thành" khi xong!'),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Hoàn thành'),
              onPressed: () {
                setState(() {
                  completedSessions.insert(
                    0,
                    ExerciseSession(
                      exerciseName: exercise.name,
                      date: DateTime.now(),
                      duration: exercise.duration,
                      calories: exercise.calories,
                    ),
                  );
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hoàn thành ${exercise.name}! Tuyệt vời!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class Exercise {
  final String name;
  final int duration;
  final int calories;
  final IconData icon;
  final Color color;

  Exercise({
    required this.name,
    required this.duration,
    required this.calories,
    required this.icon,
    required this.color,
  });
}

class ExerciseSession {
  final String exerciseName;
  final DateTime date;
  final int duration;
  final int calories;

  ExerciseSession({
    required this.exerciseName,
    required this.date,
    required this.duration,
    required this.calories,
  });
}
