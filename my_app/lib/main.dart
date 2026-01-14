import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/src/screens/AddTaskScreen.dart';
import 'package:my_app/src/screens/DailyPlanScreen.dart';
import 'package:my_app/src/screens/SignIn.dart';
import 'package:my_app/src/screens/TasksScreen.dart';
import 'package:my_app/src/services/notification_service.dart';
import 'package:my_app/src/theme/app_theme.dart';
import 'firebase_options.dart';
import 'src/screens/HomeScreen.dart';
import 'src/screens/SignUp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routes: {
        '/signin': (_) => const SignInScreen(),
        '/signup': (_) => const SignUpScreen(),
        '/home': (_) => const HomeScreen(),
        '/add': (_) => const AddTaskScreen(),
        '/tasks': (_) => const TasksScreen(),
        '/daily-plan': (_) => const DailyPlanScreen()
      },
      home: const SignInScreen(),
    );
  }
}
