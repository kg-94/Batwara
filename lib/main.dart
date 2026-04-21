import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './providers/app_provider.dart';
import './screens/home_screen.dart';
import './screens/add_expense_screen.dart';
import './screens/members_screen.dart';
import './screens/settlements_screen.dart';
import './screens/login_screen.dart';
import './screens/signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => AppProvider(),
      child: MaterialApp(
        title: 'Batwara',
        theme: ThemeData(
          primarySwatch: Colors.teal,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        routes: {
          AddExpenseScreen.routeName: (ctx) => const AddExpenseScreen(),
          MembersScreen.routeName: (ctx) => const MembersScreen(),
          SettlementsScreen.routeName: (ctx) => const SettlementsScreen(),
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          SignupScreen.routeName: (ctx) => const SignupScreen(),
        },
      ),
    );
  }
}
