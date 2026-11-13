import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection; // ✅ تم الإصلاح هنا
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fl_chart/fl_chart.dart';

// ==========================================
// 1. Main Function & App Configuration
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDatabase.instance.database;
  runApp(const AmanApp());
}

class AmanApp extends StatelessWidget {
  const AmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أمان | AMAN',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// 2. Theme Configuration
// ==========================================
class AppTheme {
  static const Color primaryBlue = Color(0xFF1677F2);
  static const Color darkBlue = Color(0xFF103B78);
  static const Color background = Color(0xFFF4F7FC);
  static const Color successGreen = Color(0xFF20C45A);
  static const Color dangerRed = Color(0xFFF04444);

  static ThemeData get lightTheme => ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primaryBlue,
          secondary: darkBlue,
          error: dangerRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: darkBlue),
          titleTextStyle: TextStyle(
              color: darkBlue, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue),
          ),
          prefixIconColor: Colors.grey,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: primaryBlue,
          secondary: primaryBlue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
}

// ==========================================
// 3. Models
// ==========================================
class UserModel {
  final int? id;
  final String fullName;
  final String email;
  final String passwordHash;
  final String accountType;

  UserModel({this.id, required this.fullName, required this.email, required this.passwordHash, required this.accountType});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'account_type': accountType,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

class ChildModel {
  final int? id;
  final int parentId;
  final String fullName;
  final String email;
  final String passwordHash;

  ChildModel({this.id, required this.parentId, required this.fullName, required this.email, required this.passwordHash});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'full_name': fullName,
      'email': email,
      'password_hash': passwordHash,
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

class NotificationModel {
  final int? id;
  final int userId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationModel({this.id, required this.userId, required this.title, required this.message, this.isRead = false, required this.createdAt});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
    };
  }
}

// ==========================================
// 4. App Database (SQLite)
// ==========================================
class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aman_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      full_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      account_type TEXT NOT NULL,
      created_at TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE children (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL,
      full_name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE linked_accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_id INTEGER NOT NULL,
      child_id INTEGER NOT NULL,
      linking_code TEXT,
      status TEXT NOT NULL,
      linked_at TEXT NOT NULL,
      FOREIGN KEY (parent_id) REFERENCES users (id) ON DELETE CASCADE,
      FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE notifications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      title TEXT NOT NULL,
      message TEXT NOT NULL,
      is_read INTEGER DEFAULT 0,
      created_at TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE app_rules (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      child_id INTEGER NOT NULL,
      app_name TEXT NOT NULL,
      is_allowed INTEGER DEFAULT 1,
      daily_limit INTEGER DEFAULT 60,
      FOREIGN KEY (child_id) REFERENCES children (id) ON DELETE CASCADE
    )
    ''');
  }

  Future<int> createUser(UserModel user) async {
    final db = await instance.database;
    return await db.insert('users', user.toMap());
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isNotEmpty) {
      final map = result.first;
      return UserModel(
        id: map['id'] as int?,
        fullName: map['full_name'] as String,
        email: map['email'] as String,
        passwordHash: map['password_hash'] as String,
        accountType: map['account_type'] as String,
      );
    }
    return null;
  }

  Future<int> createChild(ChildModel child) async {
    final db = await instance.database;
    return await db.insert('children', child.toMap());
  }

  Future<List<ChildModel>> getChildren(int parentId) async {
    final db = await instance.database;
    final result = await db.query('children', where: 'parent_id = ?', whereArgs: [parentId]);
    return result.map((e) => ChildModel(
      id: e['id'] as int?,
      parentId: e['parent_id'] as int,
      fullName: e['full_name'] as String,
      email: e['email'] as String,
      passwordHash: e['password_hash'] as String,
    )).toList();
  }

  Future<int> addNotification(NotificationModel notif) async {
    final db = await instance.database;
    return await db.insert('notifications', notif.toMap());
  }

  Future<List<NotificationModel>> getNotifications(int userId) async {
    final db = await instance.database;
    final result = await db.query('notifications', where: 'user_id = ?', whereArgs: [userId], orderBy: 'created_at DESC');
    return result.map((e) => NotificationModel(
      id: e['id'] as int?,
      userId: e['user_id'] as int,
      title: e['title'] as String,
      message: e['message'] as String,
      isRead: (e['is_read'] as int) == 1,
      createdAt: e['created_at'] as String,
    )).toList();
  }
}

// ==========================================
// 5. Services (Auth & Utils)
// ==========================================
class AuthService {
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<bool> registerParent(String name, String email, String password) async {
    final existing = await AppDatabase.instance.getUserByEmail(email);
    if (existing != null) return false;

    final user = UserModel(
      fullName: name,
      email: email,
      passwordHash: hashPassword(password),
      accountType: 'parent',
    );
    final id = await AppDatabase.instance.createUser(user);
    await _saveSession(id);
    return true;
  }

  static Future<UserModel?> loginParent(String email, String password) async {
    final user = await AppDatabase.instance.getUserByEmail(email);
    if (user != null && user.passwordHash == hashPassword(password)) {
      await _saveSession(user.id!);
      return user;
    }
    return null;
  }

  static Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
    await prefs.setString('role', 'parent');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<int?> getSessionUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }
}

// ==========================================
// 6. Reusable Widgets
// ==========================================
class CustomTextField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  const CustomTextField({super.key, required this.hint, required this.icon, this.obscureText = false, this.controller, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color? color;

  const PrimaryButton({super.key, required this.text, required this.onPressed, this.isLoading = false, this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color ?? AppTheme.primaryBlue),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(text),
    );
  }
}

// ==========================================
// 7. Screens
// ==========================================

// --- Splash Screen ---
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    final userId = await AuthService.getSessionUserId();
    if (!mounted) return;

    if (userId != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ParentDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text('أمان', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('حماية عائلتك في العالم الرقمي', style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Role Selection Screen ---
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.shield, size: 60, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              const Text('أمان', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.darkBlue)),
              const SizedBox(height: 40),
              const Text('اختر نوع حسابك للمتابعة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              _buildRoleCard(
                context,
                title: 'أنا ولي أمر',
                subtitle: 'إدارة ومراقبة أجهزة أطفالي',
                icon: Icons.person,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentLoginScreen())),
              ),
              const SizedBox(height: 20),
              _buildRoleCard(
                context,
                title: 'هذا هاتف طفلي',
                subtitle: 'استخدام خاضع للرقابة',
                icon: Icons.phone_android,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildLoginScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.primaryBlue, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_back_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Auth Screens ---
class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final user = await AuthService.loginParent(_emailController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);

    if (user != null) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ParentDashboard()), (route) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول ولي الأمر')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CustomTextField(hint: 'البريد الإلكتروني', icon: Icons.email, controller: _emailController),
            CustomTextField(hint: 'كلمة المرور', icon: Icons.lock, obscureText: true, controller: _passwordController),
            const SizedBox(height: 20),
            PrimaryButton(text: 'تسجيل الدخول', onPressed: _login, isLoading: _isLoading),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentRegisterScreen())),
              child: const Text('إنشاء حساب جديد'),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }
    setState(() => _isLoading = true);
    final success = await AuthService.registerParent(_nameController.text.trim(), _emailController.text.trim(), _passwordController.text);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ParentDashboard()), (route) => false);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('البريد الإلكتروني مستخدم بالفعل')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب ولي الأمر')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomTextField(hint: 'الاسم الكامل', icon: Icons.person, controller: _nameController),
            CustomTextField(hint: 'البريد الإلكتروني', icon: Icons.email, controller: _emailController),
            CustomTextField(hint: 'كلمة المرور', icon: Icons.lock, obscureText: true, controller: _passwordController),
            Row(
              children: [
                Checkbox(value: true, onChanged: (v) {}),
                const Expanded(child: Text('أوافق على شروط الاستخدام وسياسة الخصوصية', style: TextStyle(fontSize: 12))),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(text: 'إنشاء حساب', onPressed: _register, isLoading: _isLoading),
          ],
        ),
      ),
    );
  }
}

class ChildLoginScreen extends StatelessWidget {
  const ChildLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل دخول الطفل')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CustomTextField(hint: 'البريد الإلكتروني', icon: Icons.email),
            const CustomTextField(hint: 'كلمة المرور', icon: Icons.lock, obscureText: true),
            const SizedBox(height: 20),
            PrimaryButton(text: 'دخول', onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const ChildDashboard()), (route) => false);
            }),
          ],
        ),
      ),
    );
  }
}

// --- Parent Dashboard ---
class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ParentHomeTab(),
    const ChildrenTab(),
    const LocationTab(),
    const ReportsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الأطفال'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'الموقع'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

class ParentHomeTab extends StatelessWidget {
  const ParentHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.darkBlue]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('مرحباً بك،', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('يوسف ولي أمر', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatCard('وقت الشاشة اليوم', '3 س 42 د', Icons.timer, AppTheme.primaryBlue)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('البطارية', '78%', Icons.battery_std, AppTheme.successGreen)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('أكثر التطبيقات استخداماً', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(color: AppTheme.primaryBlue, value: 40, title: '40%', radius: 20),
                            PieChartSectionData(color: Colors.orange, value: 30, title: '30%', radius: 20),
                            PieChartSectionData(color: AppTheme.successGreen, value: 30, title: '30%', radius: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegend(AppTheme.primaryBlue, 'تطبيقات تعليمية'),
                          _buildLegend(Colors.orange, 'ألعاب فيديو'),
                          _buildLegend(AppTheme.successGreen, 'تواصل اجتماعي'),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class ChildrenTab extends StatefulWidget {
  const ChildrenTab({super.key});

  @override
  State<ChildrenTab> createState() => _ChildrenTabState();
}

class _ChildrenTabState extends State<ChildrenTab> {
  List<ChildModel> _children = [];

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final userId = await AuthService.getSessionUserId();
    if (userId != null) {
      final children = await AppDatabase.instance.getChildren(userId);
      if (mounted) {
        setState(() => _children = children);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأطفال')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryBlue,
        onPressed: () => _showAddChildDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _children.isEmpty
          ? const Center(child: Text('لا يوجد أطفال مسجلين حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _children.length,
              itemBuilder: (context, index) {
                final child = _children[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.child_care, color: Colors.white)),
                    title: Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(child.email),
                    trailing: const Icon(Icons.arrow_back_ios, size: 16),
                  ),
                );
              },
            ),
    );
  }

  void _showAddChildDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة طفل جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الطفل')),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final userId = await AuthService.getSessionUserId();
              if (userId != null && nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                await AppDatabase.instance.createChild(ChildModel(
                  parentId: userId,
                  fullName: nameCtrl.text,
                  email: emailCtrl.text,
                  passwordHash: AuthService.hashPassword('123456'),
                ));
                if (mounted) Navigator.pop(dialogContext);
                _loadChildren();
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}

class LocationTab extends StatelessWidget {
  const LocationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموقع الجغرافي')),
      body: Stack(
        children: [
          Container(
            color: Colors.grey.shade200,
            child: const Center(child: Text('خريطة تفاعلية (تتطلب إعداد Google Maps)', style: TextStyle(color: Colors.grey))),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.home, color: AppTheme.successGreen, size: 30),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('المنزل (منطقة آمنة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('آخر تحديث: منذ 5 دقائق', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والإحصائيات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('الاستخدام الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 8,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            show: true,
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = ['السبت', 'الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة'];
                                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: [
                            _buildBar(0, 4),
                            _buildBar(1, 6),
                            _buildBar(2, 5),
                            _buildBar(3, 7),
                            _buildBar(4, 3),
                            _buildBar(5, 2),
                            _buildBar(6, 5),
                          ],
                        ),
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

  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(toY: y, color: AppTheme.primaryBlue, width: 16, borderRadius: BorderRadius.circular(4)),
    ]);
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          const ListTile(
            leading: CircleAvatar(backgroundColor: AppTheme.primaryBlue, child: Icon(Icons.person, color: Colors.white)),
            title: Text('يوسف ولي أمر', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('yossef@example.com'),
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.people), title: const Text('إدارة الأطفال'), onTap: () {}),
          ListTile(leading: const Icon(Icons.security), title: const Text('الخصوصية والأمان'), onTap: () {}),
          ListTile(leading: const Icon(Icons.dark_mode), title: const Text('الوضع الداكن'), trailing: Switch(value: false, onChanged: (v) {}), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.dangerRed),
            title: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.dangerRed)),
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.dangerRed),
            title: const Text('حذف الحساب', style: TextStyle(color: AppTheme.dangerRed)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = await AuthService.getSessionUserId();
    if (userId != null) {
      final notifs = await AppDatabase.instance.getNotifications(userId);
      if (mounted) {
        setState(() => _notifications = notifs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات')),
      body: _notifications.isEmpty
          ? const Center(child: Text('لا توجد تنبيهات حالياً'))
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return ListTile(
                  leading: const Icon(Icons.notifications, color: AppTheme.primaryBlue),
                  title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notif.message),
                  trailing: Text(DateFormat('hh:mm a').format(DateTime.parse(notif.createdAt)), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                );
              },
            ),
    );
  }
}

class ChildDashboard extends StatelessWidget {
  const ChildDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهة الطفل'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await AuthService.logout();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()), (route) => false);
            }
          })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppTheme.primaryBlue,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('مرحباً يوسف!', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    const Text('الوقت المتبقي اليوم:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const Text('1 س 18 د', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: 0.6, backgroundColor: Colors.white30, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add),
                    label: const Text('طلب وقت إضافي'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('جدول اليوم', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.school, color: AppTheme.primaryBlue),
                title: const Text('وقت الدراسة'),
                subtitle: const Text('من 4:00 م إلى 6:00 م'),
                trailing: const Icon(Icons.check_circle, color: AppTheme.successGreen),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bedtime, color: Colors.purple),
                title: const Text('وقت النوم'),
                subtitle: const Text('من 9:00 م إلى 6:00 ص'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}