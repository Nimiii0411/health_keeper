import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screen/login_screen.dart';
import 'screen/home_screen.dart';
import 'providers/theme_provider.dart';
import 'service/notification_service.dart';
import 'database/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo notification service
  await NotificationService.initialize();
  await NotificationService.createNotificationChannel();
  await NotificationService.requestPermissions();
  
  // Khởi tạo database connection
  try {
    print('🔌 Đang khởi tạo kết nối database...');
    await DatabaseConnection.connect();
    print('✅ Database đã sẵn sàng!');
  } catch (e) {
    print('⚠️ Lỗi kết nối database trong main: $e');
    print('📱 App sẽ khởi chạy nhưng cần kết nối lại trong các màn hình');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {          return MaterialApp(
            title: 'HealthKeeper',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: LoginScreen(),
            routes: {
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
