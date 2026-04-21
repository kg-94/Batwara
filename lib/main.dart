import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import './providers/app_provider.dart';
import './providers/auth_provider.dart';
import './screens/home_screen.dart';
import './screens/add_expense_screen.dart';
import './screens/members_screen.dart';
import './screens/settlements_screen.dart';
import './screens/login_screen.dart';
import './screens/signup_screen.dart';
import './screens/profile_screen.dart';
import './screens/groups_screen.dart';
import './screens/group_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => AppProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Batwara',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF00695C),
              primary: const Color(0xFF00695C),
              secondary: const Color(0xFF00BFA5),
              surface: const Color(0xFFF8FAF9),
            ),
            textTheme: const TextTheme(
              headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
              titleLarge: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF004D40)),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF00695C),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF00695C).withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF00695C)),
              ),
            ),
          ),
          home: auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
          routes: {
            AddExpenseScreen.routeName: (ctx) => const AddExpenseScreen(),
            MembersScreen.routeName: (ctx) => const MembersScreen(),
            SettlementsScreen.routeName: (ctx) => const SettlementsScreen(),
            LoginScreen.routeName: (ctx) => const LoginScreen(),
            SignupScreen.routeName: (ctx) => const SignupScreen(),
            ProfileScreen.routeName: (ctx) => const ProfileScreen(),
            GroupsScreen.routeName: (ctx) => const GroupsScreen(),
            GroupDetailScreen.routeName: (ctx) => const GroupDetailScreen(),
          },
        ),
      ),
    );
  }
}
