import 'package:flutter/material.dart';
import 'package:hate_speech/DBhelper/mongodb.dart';
import 'package:hate_speech/Screens/Detection.dart';
import 'package:hate_speech/Screens/Forgot.dart';
import 'package:hate_speech/Screens/Login.dart';
import 'package:hate_speech/Screens/Signup.dart';
import 'package:hate_speech/Screens/home.dart';
import 'package:hate_speech/Utils/themeProvider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await mongodb.connect();
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        // Keep blue colors
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // Keep blue colors
        primaryColor: Colors.blue,
        primarySwatch: Colors.blue,
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/hateSpeech') {
          final userName = settings.arguments as String? ?? 'User';
          return MaterialPageRoute(
            builder: (context) => HateSpeechScreen(userName: userName),
          );
        }
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => const Home());
          case '/signup':
            return MaterialPageRoute(
                builder: (context) => const SignUpScreen());
          // case '/newChat':
          //   final userName = settings.arguments as String? ?? 'User';
          //   return MaterialPageRoute(
          //       builder: (context) => HateSpeechScreen(userName: userName));
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/forgotPassword':
            return MaterialPageRoute(
                builder: (context) => const ForgotPasswordScreen());
          default:
            return MaterialPageRoute(builder: (context) => const Home());
        }
      },
    );
  }
}
