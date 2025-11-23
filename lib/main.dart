import 'package:flutter/material.dart';
import 'services/api_service.dart';      
import 'pages/login_page.dart';          
import 'pages/home_page.dart';           
import 'themes/app_theme.dart';          

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextStep',                
      theme: AppTheme.lightTheme,    
      home: const CheckLoginScreen(),
    );
  }
}

class CheckLoginScreen extends StatefulWidget {
  const CheckLoginScreen({super.key});

  @override
  State<CheckLoginScreen> createState() => _CheckLoginScreenState();
}

class _CheckLoginScreenState extends State<CheckLoginScreen> {
  
  @override
  void initState() {
    super.initState();
    checkIfUserIsLoggedIn();
  }

  Future<void> checkIfUserIsLoggedIn() async {
    ApiService api = ApiService(); 
    var user = await api.getCurrentUser();
    
    if (user != null) {
      goToHomePage();
    } 
    else {
      goToLoginPage();
    }
  }

  void goToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  void goToLoginPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(), 
    );
  }
}
