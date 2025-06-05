import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return FloatingActionButton(
          mini: true,
          backgroundColor: Colors.grey[600],
          onPressed: () {
            themeProvider.toggleTheme();
          },
          child: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

class ThemeToggleListTile extends StatelessWidget {
  const ThemeToggleListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          ),
          title: Text('Chế độ tối'),
          subtitle: Text(
            themeProvider.isDarkMode ? 'Đang bật' : 'Đang tắt',
          ),
          trailing: Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme();
            },
            activeColor: Colors.blue,
          ),
        );
      },
    );
  }
}
