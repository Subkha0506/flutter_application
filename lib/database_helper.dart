import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
 
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
 
  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final db = await database;
       
      final existingUser = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (existingUser.isNotEmpty) {
        return {
          'success': false,
          'message': 'Email sudah terdaftar',
        };
      }
 
      final hashedPassword = _hashPassword(password);
      final now = DateTime.now().toIso8601String();

      final userId = await db.insert('users', {
        'email': email,
        'password': hashedPassword,
        'name': name,
        'created_at': now,
      });

      return {
        'success': true,
        'message': 'Registrasi berhasil',
        'userId': userId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
 
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final db = await database;
      final hashedPassword = _hashPassword(password);

      final user = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );

      if (user.isEmpty) {
        return {
          'success': false,
          'message': 'Email atau password salah',
        };
      }

      return {
        'success': true,
        'message': 'Login berhasil',
        'user': user.first,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
 
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      return users.isNotEmpty ? users.first : null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }
 
  Future<bool> updateUser({
    required int userId,
    required String name,
    required String email,
  }) async {
    try {
      final db = await database;
      final result = await db.update(
        'users',
        {'name': name, 'email': email},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
 
  Future<bool> deleteUser(int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
 
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final db = await database;
      return await db.query('users');
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }
}