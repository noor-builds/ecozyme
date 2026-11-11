import 'package:ecoenzyme/core/router/app_router.dart';
import 'package:ecoenzyme/core/theme/theme.dart';
import 'package:ecoenzyme/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _selectedLanguage = 'en';
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  bool _isLoading = false;

  static const Map<String, String> _languageNames = {
    'en': 'English',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'mr': 'मराठी',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
  };

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'title1': 'Login,',
      'title2': 'To Grow',
      'nameHint': 'name',
      'emailHint': 'email id',
      'loginButton': 'Login',
      'accountText': 'Don\'t have an account? ',
      'signUp': 'Sign up',
    },
    'hi': {
      'title1': 'लॉगिन,',
      'title2': 'बढ़ने के लिए',
      'nameHint': 'नाम',
      'emailHint': 'ईमेल आईडी',
      'loginButton': 'लॉगिन',
      'accountText': 'क्या आपका कोई अकाउंट नहीं है? ',
      'signUp': 'साइन अप',
    },
    'bn': {
      'title1': 'লগইন,',
      'title2': 'বড় হতে',
      'nameHint': 'নাম',
      'emailHint': 'ইমেইল আইডি',
      'loginButton': 'লগইন',
      'accountText': 'একাউন্ট নেই? ',
      'signUp': 'সাইন আপ',
    },
    'ta': {
      'title1': 'உள்நுழைவு,',
      'title2': 'வளர',
      'nameHint': 'பெயர்',
      'emailHint': 'மின்னஞ்சல் ஐடி',
      'loginButton': 'உள்நுழைக',
      'accountText': 'கணக்கு இல்லையா? ',
      'signUp': 'சைன் அப்',
    },
    'te': {
      'title1': 'లాగిన్,',
      'title2': 'వాలడానికి',
      'nameHint': 'పేరు',
      'emailHint': 'ఇమెయిల్ ఐడి',
      'loginButton': 'లాగిన్',
      'accountText': 'ఖాతా లేదా? ',
      'signUp': 'సైన్ అప్',
    },
    'mr': {
      'title1': 'लॉगिन,',
      'title2': 'वाढण्यासाठी',
      'nameHint': 'नाव',
      'emailHint': 'ईमेल आयडी',
      'loginButton': 'लॉग इन',
      'accountText': 'खाते नाही का? ',
      'signUp': 'साइन अप',
    },
    'kn': {
      'title1': 'ಲಾಗಿನ್,',
      'title2': 'ಹೆಚ್ಚಾಗಲು',
      'nameHint': 'ಹೆಸರು',
      'emailHint': 'ಇಮೈಲ್ ಐಡಿ',
      'loginButton': 'ಲಾಗಿನ್',
      'accountText': 'ಖಾತೆ ಇಲ್ಲವಾ? ',
      'signUp': 'ಸೈನ್ ಅಪ್',
    },
    'ml': {
      'title1': 'ലോഗിൻ,',
      'title2': 'വളരാൻ',
      'nameHint': 'പേര്',
      'emailHint': 'ഇമെയിൽ ഐഡി',
      'loginButton': 'ലോഗിൻ',
      'accountText': 'അക്കൗണ്ട് ഇല്ലേ? ',
      'signUp': 'സൈൻ അപ്പ്',
    },
  };

  Map<String, String> get _currentText => _translations[_selectedLanguage]!;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await AuthService().loginUser(email);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (!result.isSuccess) {
      _showSnackBar(result.message);
      return;
    }

    context.push(
      Uri(
        path: AppRoutes.otp,
        queryParameters: {'email': email, 'type': OtpType.email.name},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      borderRadius: BorderRadius.circular(12),
                      items: _languageNames.entries
                          .map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _currentText['title1']!,
                      style: AppTheme.lightTheme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentText['title2']!,
                      style: AppTheme.lightTheme.textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: _currentText['nameHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        obscureText: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: _currentText['emailHint'],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_currentText['loginButton']!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentText['accountText']!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push(AppRoutes.register);
                            },
                            child: Text(
                              _currentText['signUp']!,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
