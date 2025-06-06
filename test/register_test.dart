import 'package:flutter_test/flutter_test.dart';

// Helper functions for validation testing
bool _isValidEmail(String email) {
  return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
}

String? _validatePassword(String password) {
  if (password.isEmpty) {
    return 'Vui lòng nhập mật khẩu';
  }
  if (password.length < 8) {
    return 'Mật khẩu phải có ít nhất 8 ký tự';
  }
  if (!RegExp(r'[A-Z]').hasMatch(password)) {
    return 'Mật khẩu phải có ít nhất 1 chữ hoa';
  }
  if (!RegExp(r'[a-z]').hasMatch(password)) {
    return 'Mật khẩu phải có ít nhất 1 chữ thường';
  }
  if (!RegExp(r'[0-9]').hasMatch(password)) {
    return 'Mật khẩu phải có ít nhất 1 số';
  }
  if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
    return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
  }
  return null;
}

bool _isValidUsername(String username) {
  return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username);
}

String? _validateFullName(String fullName) {
  if (fullName.trim().isEmpty) {
    return 'Vui lòng nhập họ tên';
  }
  if (fullName.trim().length < 2) {
    return 'Họ tên quá ngắn';
  }
  if (fullName.trim().length > 50) {
    return 'Họ tên quá dài';
  }
  return null;
}

String? _validateUsername(String username) {
  if (username.isEmpty) {
    return 'Vui lòng nhập tên đăng nhập';
  }
  if (username.length < 3) {
    return 'Tên đăng nhập phải có ít nhất 3 ký tự';
  }
  if (username.length > 20) {
    return 'Tên đăng nhập không được quá 20 ký tự';
  }
  if (!_isValidUsername(username)) {
    return 'Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới';
  }
  return null;
}

int _calculateAge(String birthDateString) {
  try {
    final birthDate = DateTime.parse(birthDateString);
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  } catch (e) {
    return 0;
  }
}

String? _validateAge(String birthDateString) {
  final age = _calculateAge(birthDateString);
  if (age == 0) {
    return 'Ngày sinh không hợp lệ';
  }
  if (age < 5) {
    return 'Tuổi phải từ 5 trở lên';
  }
  if (age > 100) {
    return 'Tuổi không được quá 100';
  }
  return null;
}

void main() {
  group('1. Họ tên validation', () {
    test('PASS - 1.1 Valid full names', () {
      expect(_validateFullName('Nguyễn Văn A'), isNull);
      expect(_validateFullName('Trần Thị Bình'), isNull);
      expect(_validateFullName('John Doe'), isNull);
      expect(_validateFullName('José María González'), isNull);
    });

    test('PASS - 1.2 Invalid full names', () {
      expect(_validateFullName(''), equals('Vui lòng nhập họ tên'));
      expect(_validateFullName('   '), equals('Vui lòng nhập họ tên'));
      expect(_validateFullName('A'), equals('Họ tên quá ngắn'));
      expect(_validateFullName('a' * 51), equals('Họ tên quá dài'));
    });
  });

  group('2. Email validation', () {
    test('PASS - 2.1 Valid email formats', () {
      expect(_isValidEmail('test@example.com'), isTrue);
      expect(_isValidEmail('user.name@domain.co.uk'), isTrue);
      expect(_isValidEmail('first.last+tag@example.org'), isTrue);
      expect(_isValidEmail('test123@test123.com'), isTrue);
      expect(_isValidEmail('user@subdomain.domain.com'), isTrue);
    });

    test('PASS - 2.2 Invalid email formats', () {
      expect(_isValidEmail('invalid_email'), isFalse);
      expect(_isValidEmail('test@'), isFalse);
      expect(_isValidEmail('@example.com'), isFalse);
      expect(_isValidEmail('test.example.com'), isFalse);
      expect(_isValidEmail('test@.com'), isFalse);
      expect(_isValidEmail('test@domain'), isFalse);
      expect(_isValidEmail(''), isFalse);
      expect(_isValidEmail('test space@example.com'), isFalse);
    });
  });

  group('3. Username validation', () {
    test('PASS - 3.1 Valid usernames', () {
      expect(_validateUsername('user123'), isNull);
      expect(_validateUsername('test_user'), isNull);
      expect(_validateUsername('username'), isNull);
      expect(_validateUsername('user_name_123'), isNull);
      expect(_validateUsername('a1b2c3'), isNull);
    });    test('PASS - 3.2 Invalid usernames', () {
      expect(_validateUsername(''), equals('Vui lòng nhập tên đăng nhập'));
      expect(_validateUsername('ab'), equals('Tên đăng nhập phải có ít nhất 3 ký tự'));
      expect(_validateUsername('a' * 21), equals('Tên đăng nhập không được quá 20 ký tự'));
      expect(_validateUsername('user-name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user@name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
      expect(_validateUsername('user.name'), equals('Tên đăng nhập chỉ được chứa chữ, số và dấu gạch dưới'));
    });
  });

  group('4. Password validation', () {
    test('PASS - 4.1 Valid passwords', () {
      expect(_validatePassword('ValidPass123!'), isNull);
      expect(_validatePassword('MySecret123@'), isNull);
      expect(_validatePassword('StrongPwd456#'), isNull);
      expect(_validatePassword('TestCase789\$'), isNull);
      expect(_validatePassword('Password123%'), isNull);
    });

    test('PASS - 4.2 Password too short', () {
      expect(_validatePassword('Short1!'), equals('Mật khẩu phải có ít nhất 8 ký tự'));
      expect(_validatePassword('Abc123!'), equals('Mật khẩu phải có ít nhất 8 ký tự'));
      expect(_validatePassword('Pass1@'), equals('Mật khẩu phải có ít nhất 8 ký tự'));
    });

    test('PASS - 4.3 Missing uppercase letters', () {
      expect(_validatePassword('lowercase123!'), equals('Mật khẩu phải có ít nhất 1 chữ hoa'));
      expect(_validatePassword('nouppercase456@'), equals('Mật khẩu phải có ít nhất 1 chữ hoa'));
      expect(_validatePassword('password789#'), equals('Mật khẩu phải có ít nhất 1 chữ hoa'));
    });

    test('PASS - 4.4 Missing lowercase letters', () {
      expect(_validatePassword('UPPERCASE123!'), equals('Mật khẩu phải có ít nhất 1 chữ thường'));
      expect(_validatePassword('NOLOWERCASE456@'), equals('Mật khẩu phải có ít nhất 1 chữ thường'));
      expect(_validatePassword('PASSWORD789#'), equals('Mật khẩu phải có ít nhất 1 chữ thường'));
    });

    test('PASS - 4.5 Missing numbers', () {
      expect(_validatePassword('NoNumberHere!'), equals('Mật khẩu phải có ít nhất 1 số'));
      expect(_validatePassword('OnlyLetters@'), equals('Mật khẩu phải có ít nhất 1 số'));
      expect(_validatePassword('Password#'), equals('Mật khẩu phải có ít nhất 1 số'));
    });

    test('PASS - 4.6 Missing special characters', () {
      expect(_validatePassword('NoSpecialChar123'), equals('Mật khẩu phải có ít nhất 1 ký tự đặc biệt'));
      expect(_validatePassword('MissingSymbol456'), equals('Mật khẩu phải có ít nhất 1 ký tự đặc biệt'));
      expect(_validatePassword('Password123'), equals('Mật khẩu phải có ít nhất 1 ký tự đặc biệt'));
    });

    test('PASS - 4.7 Empty password', () {
      expect(_validatePassword(''), equals('Vui lòng nhập mật khẩu'));
    });

    test('PASS - 4.8 Different special characters', () {
      List<String> validPasswords = [
        'TestPass123!',
        'TestPass123@',
        'TestPass123#',
        'TestPass123\$',
        'TestPass123%',
        'TestPass123^',
        'TestPass123&',
        'TestPass123*',
        'TestPass123(',
        'TestPass123)',
        'TestPass123.',
        'TestPass123,',
        'TestPass123?',
        'TestPass123:',
        'TestPass123{',
        'TestPass123}',
        'TestPass123|',
        'TestPass123<',
        'TestPass123>',
      ];

      for (String password in validPasswords) {
        expect(_validatePassword(password), isNull, 
               reason: 'Password $password should be valid');
      }
    });
  });

  group('5. Age calculation and validation', () {
    test('PASS - 5.1 Calculate age correctly', () {
      final now = DateTime.now();
      final birthDate20 = DateTime(now.year - 20, now.month, now.day).toString().split(' ')[0];
      final birthDate25 = DateTime(now.year - 25, now.month, now.day).toString().split(' ')[0];
      final birthDate30 = DateTime(now.year - 30, now.month, now.day).toString().split(' ')[0];
      
      expect(_calculateAge(birthDate20), equals(20));
      expect(_calculateAge(birthDate25), equals(25));
      expect(_calculateAge(birthDate30), equals(30));
    });

    test('PASS - 5.2 Valid age ranges', () {
      final now = DateTime.now();
      final age5 = DateTime(now.year - 5, now.month, now.day).toString().split(' ')[0];
      final age18 = DateTime(now.year - 18, now.month, now.day).toString().split(' ')[0];
      final age65 = DateTime(now.year - 65, now.month, now.day).toString().split(' ')[0];
      final age100 = DateTime(now.year - 100, now.month, now.day).toString().split(' ')[0];
      
      expect(_validateAge(age5), isNull);
      expect(_validateAge(age18), isNull);
      expect(_validateAge(age65), isNull);
      expect(_validateAge(age100), isNull);
    });

    test('PASS - 5.3 Invalid age ranges', () {
      final now = DateTime.now();
      final tooYoung = DateTime(now.year - 4, now.month, now.day).toString().split(' ')[0];
      final tooOld = DateTime(now.year - 101, now.month, now.day).toString().split(' ')[0];
      
      expect(_validateAge(tooYoung), equals('Tuổi phải từ 5 trở lên'));
      expect(_validateAge(tooOld), equals('Tuổi không được quá 100'));
    });

    test('PASS - 5.4 Invalid date formats', () {
      expect(_validateAge('invalid-date'), equals('Ngày sinh không hợp lệ'));
      expect(_validateAge(''), equals('Ngày sinh không hợp lệ'));
      expect(_validateAge('2023-13-45'), equals('Ngày sinh không hợp lệ'));
      expect(_validateAge('not-a-date'), equals('Ngày sinh không hợp lệ'));
    });
  });

  group('6. Gender validation', () {
    test('PASS - 6.1 Valid gender options', () {
      List<String> validGenders = ['Nam', 'Nữ', 'Khác'];
      
      for (String gender in validGenders) {
        expect(validGenders.contains(gender), isTrue);
      }
    });

    test('PASS - 6.2 Invalid gender options', () {
      List<String> validGenders = ['Nam', 'Nữ', 'Khác'];
      List<String> invalidGenders = ['Male', 'Female', 'Other', 'Nam/Nữ', '', 'Không xác định'];
      
      for (String gender in invalidGenders) {
        expect(validGenders.contains(gender), isFalse);
      }
    });
  });

  group('7. Complete form validation', () {
    test('PASS - 7.1 Valid complete registration data', () {
      final validData = {
        'fullName': 'Nguyễn Văn Test',
        'email': 'test@example.com', 
        'username': 'testuser123',
        'password': 'ValidPass123!',
        'gender': 'Nam',
        'birthDate': '1990-01-01',
      };

      expect(_validateFullName(validData['fullName']!), isNull);
      expect(_isValidEmail(validData['email']!), isTrue);
      expect(_validateUsername(validData['username']!), isNull);
      expect(_validatePassword(validData['password']!), isNull);
      expect(['Nam', 'Nữ', 'Khác'].contains(validData['gender']), isTrue);
      expect(_validateAge(validData['birthDate']!), isNull);
    });

    test('PASS - 7.2 Invalid complete registration data', () {
      final invalidData = {
        'fullName': '',
        'email': 'invalid-email',
        'username': 'us',
        'password': 'weak',
        'gender': 'InvalidGender',
        'birthDate': 'invalid-date',
      };

      expect(_validateFullName(invalidData['fullName']!), isNotNull);
      expect(_isValidEmail(invalidData['email']!), isFalse);
      expect(_validateUsername(invalidData['username']!), isNotNull);
      expect(_validatePassword(invalidData['password']!), isNotNull);
      expect(['Nam', 'Nữ', 'Khác'].contains(invalidData['gender']), isFalse);
      expect(_validateAge(invalidData['birthDate']!), isNotNull);
    });

    test('PASS - 7.3 Edge cases and boundary values', () {
      // Test boundary lengths
      expect(_validateFullName('Ab'), isNull); // Minimum length
      expect(_validateFullName('a' * 50), isNull); // Maximum length
      expect(_validateUsername('abc'), isNull); // Minimum length
      expect(_validateUsername('a' * 20), isNull); // Maximum length
      
      // Test special characters in names
      expect(_validateFullName('Nguyễn Văn Tèo'), isNull); // Vietnamese
      expect(_validateFullName('José María'), isNull); // Spanish accents
      expect(_validateFullName("O'Connor"), isNull); // Apostrophe
      
      // Test various email domains
      expect(_isValidEmail('test@gmail.com'), isTrue);
      expect(_isValidEmail('user@company.co.uk'), isTrue);
      expect(_isValidEmail('person@domain.info'), isTrue);
      
      // Test age boundaries
      final now = DateTime.now();
      final exactly5 = DateTime(now.year - 5, now.month, now.day).toString().split(' ')[0];
      final exactly100 = DateTime(now.year - 100, now.month, now.day).toString().split(' ')[0];
      
      expect(_validateAge(exactly5), isNull);
      expect(_validateAge(exactly100), isNull);
    });
  });

  group('8. Real-world test cases', () {
    test('PASS - 8.1 Common user input mistakes', () {
      // Missing @ in email
      expect(_isValidEmail('testexample.com'), isFalse);
      
      // Password without special characters
      expect(_validatePassword('Password123'), isNotNull);
      
      // Username with spaces
      expect(_validateUsername('user name'), isNotNull);
      
      // Single character name
      expect(_validateFullName('A'), isNotNull);
      
      // Future birth date
      final future = DateTime.now().add(Duration(days: 365)).toString().split(' ')[0];
      expect(_calculateAge(future) < 0, isTrue);
    });

    test('PASS - 8.2 Vietnamese specific inputs', () {
      // Vietnamese names with tones
      expect(_validateFullName('Trần Thị Ánh'), isNull);
      expect(_validateFullName('Nguyễn Văn Đức'), isNull);
      expect(_validateFullName('Lê Thị Hồng'), isNull);
      
      // Vietnamese email domains
      expect(_isValidEmail('nguyen@gmail.com'), isTrue);
      expect(_isValidEmail('test@fpt.edu.vn'), isTrue);
      expect(_isValidEmail('user@hust.edu.vn'), isTrue);
    });

    test('PASS - 8.3 Security considerations', () {
      // SQL injection attempts in username
      expect(_validateUsername("admin'; DROP TABLE users; --"), isNotNull);
      expect(_validateUsername('user<script>'), isNotNull);
      
      // Very long inputs
      expect(_validateFullName('a' * 100), isNotNull);
      expect(_validateUsername('a' * 50), isNotNull);
      
      // Common weak passwords
      expect(_validatePassword('123456'), isNotNull);
      expect(_validatePassword('password'), isNotNull);
      expect(_validatePassword('qwerty'), isNotNull);
      expect(_validatePassword('admin'), isNotNull);
    });
  });

  group('9. Required Failing Tests', () {
    test('FAIL - Valid full name should be rejected', () {
      // This test will FAIL because valid name returns null, not error
      expect(_validateFullName('Nguyễn Văn A'), equals('Họ tên không hợp lệ'));
    });

    test('FAIL - Valid email should be invalid', () {
      // This test will FAIL because valid email returns true, not false
      expect(_isValidEmail('test@example.com'), isFalse);
    });

    test('FAIL - Valid username should be rejected', () {
      // This test will FAIL because valid username returns null, not error
      expect(_validateUsername('user123'), equals('Username không hợp lệ'));
    });

    test('FAIL - Strong password should be weak', () {
      // This test will FAIL because strong password returns null, not error
      expect(_validatePassword('StrongPass123!'), equals('Mật khẩu yếu'));
    });

    test('FAIL - Valid age should be invalid', () {
      // This test will FAIL because valid age returns null, not error
      final now = DateTime.now();
      final validAge = DateTime(now.year - 25, now.month, now.day).toString().split(' ')[0];
      expect(_validateAge(validAge), equals('Tuổi không hợp lệ'));
    });

    test('FAIL - Age calculation should be wrong', () {
      // This test will FAIL because age calculation is correct
      final now = DateTime.now();
      final birthDate20 = DateTime(now.year - 20, now.month, now.day).toString().split(' ')[0];
      expect(_calculateAge(birthDate20), equals(25)); // Should be 20
    });
  });
}
