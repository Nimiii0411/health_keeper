import 'package:flutter_test/flutter_test.dart';

// Helper functions for login validation testing
bool _isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

String? _validateUsername(String username) {
  if (username.trim().isEmpty) {
    return 'Vui lòng nhập tên đăng nhập';
  }
  if (username.trim().length < 3) {
    return 'Tên đăng nhập phải có ít nhất 3 ký tự';
  }
  if (username.trim().length > 20) {
    return 'Tên đăng nhập không được quá 20 ký tự';
  }
  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username.trim())) {
    return 'Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới';
  }
  return null;
}

String? _validatePassword(String password) {
  if (password.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }
  if (password.length < 6) {
    return 'Mật khẩu phải có ít nhất 6 ký tự';
  }
  return null;
}

bool _isValidLoginCredentials(String username, String password) {
  return _validateUsername(username) == null && _validatePassword(password) == null;
}

bool _isAdminAccount(String username, String password) {
  return username == 'duchuy123' && password == 'duchuy123';
}

String? _validateLoginInput(String input) {
  // Input có thể là username hoặc email
  if (input.trim().isEmpty) {
    return 'Vui lòng nhập tên đăng nhập hoặc email';
  }
  
  // Kiểm tra xem có phải email không
  if (input.contains('@')) {
    return _isValidEmail(input) ? null : 'Email không hợp lệ';
  } else {
    return _validateUsername(input);
  }
}

void main() {
  group('1. Login Input Validation', () {
    test('PASS - Valid usernames', () {
      expect(_validateUsername('user123'), isNull);
      expect(_validateUsername('testuser'), isNull);
      expect(_validateUsername('user_name'), isNull);
      expect(_validateUsername('admin123'), isNull);
      expect(_validateUsername('duchuy123'), isNull);
    });

    test('1.2 Invalid usernames', () {
      expect(_validateUsername(''), equals('Vui lòng nhập tên đăng nhập'));
      expect(_validateUsername('   '), equals('Vui lòng nhập tên đăng nhập'));
      expect(_validateUsername('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(_validateUsername('a' * 21), equals('Tên đăng nhập không được quá 20 ký tự'));
      expect(_validateUsername('user-name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user@name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user.name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
    });

    test('1.3 Valid passwords', () {
      expect(_validatePassword('123456'), isNull);
      expect(_validatePassword('password'), isNull);
      expect(_validatePassword('duchuy123'), isNull);
      expect(_validatePassword('ValidPass123!'), isNull);
      expect(_validatePassword('simple123'), isNull);
    });

    test('1.4 Invalid passwords', () {
      expect(_validatePassword(''), equals('Vui lòng nhập mật khẩu'));
      expect(_validatePassword('12345'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('abc'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('short'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
    });
  });

  group('2. Email or Username Login', () {
    test('2.1 Valid email formats for login', () {
      expect(_validateLoginInput('test@example.com'), isNull);
      expect(_validateLoginInput('user.name@domain.co.uk'), isNull);
      expect(_validateLoginInput('admin@company.com'), isNull);
      expect(_validateLoginInput('nguyen@gmail.com'), isNull);
    });

    test('2.2 Invalid email formats for login', () {
      expect(_validateLoginInput('invalid@'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('@example.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test.example.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test@'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test@domain'), equals('Email không hợp lệ'));
    });

    test('2.3 Valid usernames for login', () {
      expect(_validateLoginInput('user123'), isNull);
      expect(_validateLoginInput('testuser'), isNull);
      expect(_validateLoginInput('admin'), isNull);
      expect(_validateLoginInput('duchuy123'), isNull);
    });

    test('2.4 Invalid usernames for login', () {
      expect(_validateLoginInput('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(_validateLoginInput(''), equals('Vui lòng nhập tên đăng nhập hoặc email'));
      expect(_validateLoginInput('   '), equals('Vui lòng nhập tên đăng nhập hoặc email'));
    });
  });

  group('3. Admin Account Validation', () {
    test('3.1 Valid admin credentials', () {
      expect(_isAdminAccount('duchuy123', 'duchuy123'), isTrue);
    });

    test('3.2 Invalid admin credentials', () {
      expect(_isAdminAccount('duchuy123', 'wrongpass'), isFalse);
      expect(_isAdminAccount('wronguser', 'duchuy123'), isFalse);
      expect(_isAdminAccount('admin', 'admin'), isFalse);
      expect(_isAdminAccount('', ''), isFalse);
      expect(_isAdminAccount('duchuy123', ''), isFalse);
      expect(_isAdminAccount('', 'duchuy123'), isFalse);
    });

    test('3.3 Case sensitive admin check', () {
      expect(_isAdminAccount('DUCHUY123', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy123', 'DUCHUY123'), isFalse);
      expect(_isAdminAccount('DucHuy123', 'duchuy123'), isFalse);
    });
  });

  group('4. Complete Login Validation', () {
    test('4.1 Valid login credentials', () {
      expect(_isValidLoginCredentials('user123', '123456'), isTrue);
      expect(_isValidLoginCredentials('testuser', 'password'), isTrue);
      expect(_isValidLoginCredentials('duchuy123', 'duchuy123'), isTrue);
      expect(_isValidLoginCredentials('admin_user', 'mypassword'), isTrue);
    });

    test('4.2 Invalid login credentials', () {
      expect(_isValidLoginCredentials('', '123456'), isFalse);
      expect(_isValidLoginCredentials('user123', ''), isFalse);
      expect(_isValidLoginCredentials('', ''), isFalse);
      expect(_isValidLoginCredentials('ab', '123456'), isFalse);
      expect(_isValidLoginCredentials('user123', '12345'), isFalse);
      expect(_isValidLoginCredentials('user-name', 'password'), isFalse);
    });
  });

  group('5. Login Security Tests', () {
    test('5.1 SQL injection attempts', () {
      List<String> maliciousInputs = [
        "admin'; DROP TABLE users; --",
        "' OR '1'='1",
        "admin'/*",
        "'; DELETE FROM users; --",
        "admin' OR 1=1#",
      ];

      for (String input in maliciousInputs) {
        expect(_validateUsername(input), isNotNull,
               reason: 'Should reject malicious input: $input');
      }
    });

    test('5.2 XSS attempts in username', () {
      List<String> xssInputs = [
        '<script>alert("xss")</script>',
        'javascript:alert(1)',
        '<img src=x onerror=alert(1)>',
        'user<script>',
        'admin</script>',
      ];

      for (String input in xssInputs) {
        expect(_validateUsername(input), isNotNull,
               reason: 'Should reject XSS input: $input');
      }
    });

    test('5.3 Long input attacks', () {
      String longUsername = 'a' * 100;
      String longPassword = 'b' * 1000;

      expect(_validateUsername(longUsername), isNotNull);
      // Password length is not restricted in basic validation
      expect(_validatePassword(longPassword), isNull);
    });

    test('5.4 Empty and whitespace attacks', () {
      expect(_validateUsername('   '), isNotNull);
      expect(_validateUsername('\t\n'), isNotNull);
      expect(_validatePassword(''), isNotNull);
      expect(_validateLoginInput('   '), isNotNull);
    });
  });

  group('6. Real-world Login Scenarios', () {
    test('6.1 Common user mistakes', () {
      // Extra spaces
      expect(_validateUsername(' user123 '), isNull); // Should trim spaces
      expect(_validateUsername('user 123'), isNotNull); // Spaces in middle not allowed
      
      // Mixed case (usernames are case sensitive)
      expect(_validateUsername('User123'), isNull);
      expect(_validateUsername('USER123'), isNull);
      
      // Common password mistakes
      expect(_validatePassword('12345'), isNotNull); // Too short
      expect(_validatePassword('     '), isNotNull); // Only spaces
    });

    test('6.2 Vietnamese user inputs', () {
      // Vietnamese usernames (should not contain Vietnamese characters)
      expect(_validateUsername('nguyen123'), isNull);
      expect(_validateUsername('tran_van_a'), isNull);
      expect(_validateUsername('user_việt'), isNotNull); // Contains Vietnamese chars
      
      // Vietnamese emails
      expect(_validateLoginInput('nguyen@gmail.com'), isNull);
      expect(_validateLoginInput('tranvan@fpt.edu.vn'), isNull);
    });

    test('6.3 Corporate login patterns', () {
      // Corporate usernames
      expect(_validateUsername('john_doe'), isNull);
      expect(_validateUsername('employee001'), isNull);
      expect(_validateUsername('admin_2024'), isNull);
      
      // Corporate emails
      expect(_validateLoginInput('john.doe@company.com'), isNull);
      expect(_validateLoginInput('admin@healthcare.vn'), isNull);
    });
  });

  group('7. Password Security Levels', () {
    test('7.1 Weak passwords (still valid for login)', () {
      List<String> weakPasswords = [
        '123456',
        'password',
        'qwerty',
        'admin123',
        'user123',
      ];

      for (String password in weakPasswords) {
        expect(_validatePassword(password), isNull,
               reason: 'Weak password should still be valid for login: $password');
      }
    });

    test('7.2 Medium strength passwords', () {
      List<String> mediumPasswords = [
        'password123',
        'user12345',
        'mypassword',
        'login2024',
      ];

      for (String password in mediumPasswords) {
        expect(_validatePassword(password), isNull,
               reason: 'Medium password should be valid: $password');
      }
    });

    test('7.3 Strong passwords', () {
      List<String> strongPasswords = [
        'MyStr0ng!Pass',
        'C0mpl3x#2024',
        'S3cur3_P@ssw0rd',
        'Hea1th@pp!',
      ];

      for (String password in strongPasswords) {
        expect(_validatePassword(password), isNull,
               reason: 'Strong password should be valid: $password');
      }
    });
  });

  group('8. Login Flow Validation', () {
    test('8.1 Complete valid login scenarios', () {
      Map<String, String> validLogins = {
        'user123': 'password123',
        'testuser': '123456',
        'duchuy123': 'duchuy123',
        'admin_user': 'mypassword',
        'health_user': 'secure123',
      };

      validLogins.forEach((username, password) {
        expect(_isValidLoginCredentials(username, password), isTrue,
               reason: 'Login should be valid: $username/$password');
      });
    });

    test('8.2 Complete invalid login scenarios', () {
      Map<String, String> invalidLogins = {
        '': 'password',
        'user': '',
        'ab': 'password',
        'user123': '12345',
        'user-name': 'password',
        'user name': 'password',
      };

      invalidLogins.forEach((username, password) {
        expect(_isValidLoginCredentials(username, password), isFalse,
               reason: 'Login should be invalid: $username/$password');
      });
    });

    test('8.3 Admin vs regular user distinction', () {
      // Admin credentials
      expect(_isAdminAccount('duchuy123', 'duchuy123'), isTrue);
      expect(_isValidLoginCredentials('duchuy123', 'duchuy123'), isTrue);
      
      // Regular user with same pattern but different credentials
      expect(_isAdminAccount('duchuy124', 'duchuy124'), isFalse);
      expect(_isValidLoginCredentials('duchuy124', 'duchuy124'), isTrue);
      
      // Valid user credentials but not admin
      expect(_isAdminAccount('user123', 'password'), isFalse);
      expect(_isValidLoginCredentials('user123', 'password'), isTrue);
    });
  });

  group('9. Edge Cases and Boundary Tests', () {
    test('9.1 Username length boundaries', () {
      expect(_validateUsername('ab'), isNotNull); // Too short (2 chars)
      expect(_validateUsername('abc'), isNull); // Minimum valid (3 chars)
      expect(_validateUsername('a' * 20), isNull); // Maximum valid (20 chars)
      expect(_validateUsername('a' * 21), isNotNull); // Too long (21 chars)
    });

    test('9.2 Password length boundaries', () {
      expect(_validatePassword('12345'), isNotNull); // Too short (5 chars)
      expect(_validatePassword('123456'), isNull); // Minimum valid (6 chars)
      expect(_validatePassword('a' * 100), isNull); // Very long password (allowed)
    });

    test('9.3 Special character handling', () {
      // Allowed in usernames
      expect(_validateUsername('user_123'), isNull);
      expect(_validateUsername('test_user_2024'), isNull);
      
      // Not allowed in usernames
      expect(_validateUsername('user-123'), isNotNull);
      expect(_validateUsername('user.123'), isNotNull);
      expect(_validateUsername('user@123'), isNotNull);
      expect(_validateUsername('user#123'), isNotNull);
    });

    test('9.4 Unicode and international characters', () {
      // These should be rejected in usernames
      expect(_validateUsername('José123'), isNotNull);
      expect(_validateUsername('müller'), isNotNull);
      expect(_validateUsername('用户123'), isNotNull);
      expect(_validateUsername('пользователь'), isNotNull);
    });
  });

  group('10. Performance and Stress Tests', () {
    test('10.1 Validation performance with many inputs', () {
      List<String> testInputs = [];
      for (int i = 0; i < 1000; i++) {
        testInputs.add('user$i');
      }

      Stopwatch stopwatch = Stopwatch()..start();
      for (String input in testInputs) {
        _validateUsername(input);
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100),
             reason: 'Validation should be fast even with many inputs');
    });

    test('10.2 Memory usage with large strings', () {
      String largeUsername = 'a' * 10000;
      String largePassword = 'b' * 10000;

      // Should handle large inputs gracefully
      expect(_validateUsername(largeUsername), isNotNull);
      expect(_validatePassword(largePassword), isNull);
    });
  });

  group('11. Detailed Error Scenarios', () {
    test('11.1 Username validation errors', () {
      // Test case 1: Empty username
      expect(_validateUsername(''), equals('Vui lòng nhập tên đăng nhập'));
      
      // Test case 2: Only whitespace
      expect(_validateUsername('   '), equals('Vui lòng nhập tên đăng nhập'));
      expect(_validateUsername('\t\n\r'), equals('Vui lòng nhập tên đăng nhập'));
      
      // Test case 3: Too short username
      expect(_validateUsername('a'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(_validateUsername('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      
      // Test case 4: Too long username
      expect(_validateUsername('a' * 21), equals('Tên đăng nhập không được quá 20 ký tự'));
      expect(_validateUsername('verylongusernamethatexceedslimit'), equals('Tên đăng nhập không được quá 20 ký tự'));
      
      // Test case 5: Invalid characters - hyphen
      expect(_validateUsername('user-name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 6: Invalid characters - space
      expect(_validateUsername('user name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 7: Invalid characters - special symbols
      expect(_validateUsername('user@domain'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user.name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user#123'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));      expect(_validateUsername('user\$money'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user%percent'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
    });

    test('11.2 Password validation errors', () {
      // Test case 1: Empty password
      expect(_validatePassword(''), equals('Vui lòng nhập mật khẩu'));
      
      // Test case 2: Too short passwords
      expect(_validatePassword('1'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('12'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('123'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('1234'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('12345'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      
      // Test case 3: Only spaces (still too short)
      expect(_validatePassword('     '), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      
      // Test case 4: Exactly 5 characters
      expect(_validatePassword('short'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      expect(_validatePassword('12345'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
    });

    test('11.3 Email validation errors', () {
      // Test case 1: Missing @ symbol
      expect(_validateLoginInput('invalidemail.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('testdomain.com'), equals('Email không hợp lệ'));
      
      // Test case 2: Missing domain
      expect(_validateLoginInput('test@'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('user@'), equals('Email không hợp lệ'));
      
      // Test case 3: Missing local part
      expect(_validateLoginInput('@domain.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('@gmail.com'), equals('Email không hợp lệ'));
      
      // Test case 4: Missing TLD
      expect(_validateLoginInput('test@domain'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('user@company'), equals('Email không hợp lệ'));
      
      // Test case 5: Invalid TLD
      expect(_validateLoginInput('test@domain.c'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('user@site.1'), equals('Email không hợp lệ'));
      
      // Test case 6: Multiple @ symbols
      expect(_validateLoginInput('test@domain@com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('user@@gmail.com'), equals('Email không hợp lệ'));
      
      // Test case 7: Spaces in email
      expect(_validateLoginInput('test user@domain.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test@domain .com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test@domain. com'), equals('Email không hợp lệ'));
    });

    test('11.4 Combined login input errors', () {
      // Test case 1: Empty input
      expect(_validateLoginInput(''), equals('Vui lòng nhập tên đăng nhập hoặc email'));
      
      // Test case 2: Only whitespace
      expect(_validateLoginInput('   '), equals('Vui lòng nhập tên đăng nhập hoặc email'));
      expect(_validateLoginInput('\t'), equals('Vui lòng nhập tên đăng nhập hoặc email'));
      
      // Test case 3: Invalid email format
      expect(_validateLoginInput('bad@email'), equals('Email không hợp lệ'));
      
      // Test case 4: Username too short
      expect(_validateLoginInput('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      
      // Test case 5: Username with invalid characters
      expect(_validateLoginInput('user-name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 6: Username too long
      expect(_validateLoginInput('verylongusernamethatexceedslimit'), equals('Tên đăng nhập không được quá 20 ký tự'));
      
      // Test case 7: Malformed email patterns
      expect(_validateLoginInput('test@'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('@test.com'), equals('Email không hợp lệ'));
      expect(_validateLoginInput('test.com'), equals('Email không hợp lệ'));
    });

    test('11.5 Admin credential errors', () {
      // Test case 1: Wrong admin username
      expect(_isAdminAccount('admin', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy1234', 'duchuy123'), isFalse);
      
      // Test case 2: Wrong admin password
      expect(_isAdminAccount('duchuy123', 'admin'), isFalse);
      expect(_isAdminAccount('duchuy123', 'password'), isFalse);
      expect(_isAdminAccount('duchuy123', 'duchuy'), isFalse);
      
      // Test case 3: Case sensitivity errors
      expect(_isAdminAccount('DUCHUY123', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy123', 'DUCHUY123'), isFalse);
      expect(_isAdminAccount('DucHuy123', 'DucHuy123'), isFalse);
      
      // Test case 4: Empty credentials
      expect(_isAdminAccount('', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy123', ''), isFalse);
      expect(_isAdminAccount('', ''), isFalse);
      
      // Test case 5: Partial matches
      expect(_isAdminAccount('duchuy12', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy123', 'duchuy12'), isFalse);
      
      // Test case 6: Similar but wrong credentials
      expect(_isAdminAccount('admin123', 'admin123'), isFalse);
      expect(_isAdminAccount('root', 'root'), isFalse);
      
      // Test case 7: With spaces
      expect(_isAdminAccount(' duchuy123', 'duchuy123'), isFalse);
      expect(_isAdminAccount('duchuy123', ' duchuy123'), isFalse);
      expect(_isAdminAccount(' duchuy123 ', ' duchuy123 '), isFalse);
    });

    test('11.6 Complete login validation errors', () {
      // Test case 1: Both fields empty
      expect(_isValidLoginCredentials('', ''), isFalse);
      
      // Test case 2: Username empty, password valid
      expect(_isValidLoginCredentials('', 'validpassword'), isFalse);
      
      // Test case 3: Username valid, password empty
      expect(_isValidLoginCredentials('validuser', ''), isFalse);
      
      // Test case 4: Username too short, password valid
      expect(_isValidLoginCredentials('ab', 'validpassword'), isFalse);
      
      // Test case 5: Username valid, password too short
      expect(_isValidLoginCredentials('validuser', '12345'), isFalse);
      
      // Test case 6: Username with invalid chars, password valid
      expect(_isValidLoginCredentials('user-name', 'validpassword'), isFalse);
      expect(_isValidLoginCredentials('user name', 'validpassword'), isFalse);
      expect(_isValidLoginCredentials('user@name', 'validpassword'), isFalse);
      
      // Test case 7: Both fields invalid
      expect(_isValidLoginCredentials('ab', '12345'), isFalse);
      expect(_isValidLoginCredentials('', ''), isFalse);
      expect(_isValidLoginCredentials('user-name', 'short'), isFalse);
    });

    test('11.7 Security attack scenarios', () {
      // Test case 1: SQL Injection attempts
      List<String> sqlInjections = [
        "'; DROP TABLE users; --",
        "admin' OR '1'='1",
        "user'; DELETE * FROM accounts; --",
        "' UNION SELECT * FROM passwords --",
        "admin'/*",
        "' OR 1=1 #",
        "'; EXEC xp_cmdshell('dir'); --"
      ];
      
      for (String injection in sqlInjections) {
        expect(_validateUsername(injection), isNotNull,
               reason: 'Should reject SQL injection: $injection');
      }
      
      // Test case 2: XSS attempts
      List<String> xssAttempts = [
        '<script>alert("XSS")</script>',
        'javascript:alert(1)',
        '<img src=x onerror=alert(1)>',
        '<iframe src="javascript:alert(1)">',
        '<svg onload=alert(1)>',
        '"><script>alert(1)</script>',
        "'><script>alert(1)</script>"
      ];
      
      for (String xss in xssAttempts) {
        expect(_validateUsername(xss), isNotNull,
               reason: 'Should reject XSS attempt: $xss');
      }
      
      // Test case 3: Command injection attempts
      List<String> commandInjections = [
        'user; rm -rf /',
        'admin && del *.*',
        'user | cat /etc/passwd',
        'test`whoami`',
        'user\$(id)',
        'admin; shutdown -h now'
      ];
      
      for (String cmd in commandInjections) {
        expect(_validateUsername(cmd), isNotNull,
               reason: 'Should reject command injection: $cmd');
      }
      
      // Test case 4: Buffer overflow attempts
      String veryLongInput = 'a' * 1000;
      expect(_validateUsername(veryLongInput), isNotNull,
             reason: 'Should reject extremely long input');
      
      // Test case 5: Unicode/encoding attacks
      List<String> unicodeAttacks = [
        'admin\\u0000',  // Null byte
        'user\\u000A',   // Line feed
        'test\\u000D',   // Carriage return
        'admin\\u0009',  // Tab
        'user\\uFEFF',   // Zero width no-break space
      ];
      
      for (String unicode in unicodeAttacks) {
        expect(_validateUsername(unicode), isNotNull,
               reason: 'Should reject unicode attack: $unicode');
      }
      
      // Test case 6: Directory traversal attempts
      List<String> pathTraversals = [
        '../../../etc/passwd',
        '..\\\\..\\\\windows\\\\system32',
        '....//....//etc//passwd',
        '%2e%2e%2f%2e%2e%2f',
        '..;/etc/passwd'
      ];
      
      for (String path in pathTraversals) {
        expect(_validateUsername(path), isNotNull,
               reason: 'Should reject path traversal: $path');
      }
      
      // Test case 7: Format string attacks
      List<String> formatStrings = [
        '%n%n%n%n',
        '%x%x%x%x',
        '%s%s%s%s',
        'malicious_format_string',
        'context_injection_attempt'
      ];
      
      for (String format in formatStrings) {
        expect(_validateUsername(format), isNotNull,
               reason: 'Should reject format string: $format');
      }
    });
  });

  group('12. Edge Case Error Scenarios', () {
    test('12.1 Boundary condition errors', () {
      // Test case 1: Username exactly at boundary (invalid)
      expect(_validateUsername('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(_validateUsername('a' * 21), equals('Tên đăng nhập không được quá 20 ký tự'));
      
      // Test case 2: Password exactly at boundary (invalid)
      expect(_validatePassword('12345'), equals('Mật khẩu phải có ít nhất 6 ký tự'));
      
      // Test case 3: Email with minimum invalid domain
      expect(_validateLoginInput('a@b.c'), equals('Email không hợp lệ'));
      
      // Test case 4: Username with only numbers (but too short)
      expect(_validateUsername('12'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      
      // Test case 5: Username with only underscores (but too short)
      expect(_validateUsername('__'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      
      // Test case 6: Mixed valid/invalid character combinations
      expect(_validateUsername('ab_'), isNull); // Valid (3 chars)
      expect(_validateUsername('a_b'), isNull); // Valid (3 chars)
      expect(_validateUsername('_ab'), isNull); // Valid (3 chars)
      expect(_validateUsername('a-b'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 7: Password with only spaces (valid length but unusual)
      expect(_validatePassword('      '), isNull); // 6 spaces = valid length
      expect(_validatePassword('     '), equals('Mật khẩu phải có ít nhất 6 ký tự')); // 5 spaces = invalid
    });

    test('12.2 Cultural and language errors', () {
      // Test case 1: Vietnamese characters in username
      expect(_validateUsername('người_dùng'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('admin_việt'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 2: Chinese characters
      expect(_validateUsername('用户123'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 3: Arabic characters
      expect(_validateUsername('مستخدم123'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 4: Cyrillic characters
      expect(_validateUsername('пользователь'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 5: Accented characters
      expect(_validateUsername('café123'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('niño456'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 6: Mixed scripts
      expect(_validateUsername('user用户'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 7: Emoji and symbols
      expect(_validateUsername('user😀123'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('admin★'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
    });

    test('12.3 System-specific errors', () {
      // Test case 1: Reserved system names
      List<String> systemNames = [
        'CON', 'PRN', 'AUX', 'NUL',
        'COM1', 'COM2', 'LPT1', 'LPT2'
      ];
      
      // These are valid usernames in our system but might cause issues in Windows
      for (String name in systemNames) {
        String? result = _validateUsername(name.toLowerCase());
        // They pass our validation but we document the potential issue
        expect(result, isNull, reason: 'System name $name passes validation but may cause OS issues');
      }
      
      // Test case 2: Path-like usernames
      expect(_validateUsername('\\\\user\\\\name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('/usr/local'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 3: URL-like usernames
      expect(_validateUsername('http://evil.com'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('ftp://server'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 4: Control characters
      expect(_validateUsername('user\\x00name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('admin\\x1F'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 5: Email-like usernames (without being actual emails)
      expect(_validateUsername('user@'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('@user'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 6: Phone number patterns
      expect(_validateUsername('+84123456789'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('0123-456-789'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      
      // Test case 7: Credit card or sensitive data patterns
      expect(_validateUsername('4111-1111-1111-1111'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('123.45.678-90'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
    });
  });

  group('12. Required Failing Tests', () {
    test('FAIL - Valid username should be rejected', () {
      // This test will FAIL because valid username returns null, not error
      expect(_validateUsername('user123'), equals('Tên đăng nhập không hợp lệ'));
    });

    test('FAIL - Valid password should be rejected', () {
      // This test will FAIL because valid password returns null, not error  
      expect(_validatePassword('123456'), equals('Mật khẩu không hợp lệ'));
    });

    test('FAIL - Valid email should be invalid', () {
      // This test will FAIL because valid email returns true, not false
      expect(_isValidEmail('test@example.com'), isFalse);
    });

    test('FAIL - Admin credentials should be wrong', () {
      // This test will FAIL because correct admin credentials return true
      expect(_isAdminAccount('duchuy123', 'duchuy123'), isFalse);
    });

    test('FAIL - Valid login should be invalid', () {
      // This test will FAIL because valid credentials return true
      expect(_isValidLoginCredentials('user123', '123456'), isFalse);
    });

    test('FAIL - Login input validation wrong result', () {
      // This test will FAIL because valid input returns null
      expect(_validateLoginInput('user123'), equals('Input không hợp lệ'));
    });
  });
}