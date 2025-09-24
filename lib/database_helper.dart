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
    String path = join(await getDatabasesPath(), 'smkn40_news.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'user',
        profile_image TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE news(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        image TEXT,
        author TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'umum',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Insert default admin
    final hashedPassword = _hashPassword('jayaraya40');
    await db.insert('users', {
      'email': 'admin40@gmail.com',
      'password': hashedPassword,
      'name': 'Administrator SMKN 40',
      'role': 'admin',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Insert sample news
    final now = DateTime.now().toIso8601String();
    await db.insert('news', {
      'title': 'Selamat Datang di SMKN 40 Jakarta',
      'content': 'Aplikasi berita resmi SMKN 40 Jakarta telah diluncurkan. Dapatkan informasi terbaru seputar kegiatan sekolah, pengumuman, dan prestasi siswa.',
      'image': 'https://via.placeholder.com/400x200?text=SMKN+40+Jakarta',
      'author': 'Administrator SMKN 40',
      'category': 'pengumuman',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('news', {
      'title': 'Penerimaan Peserta Didik Baru 2024',
      'content': 'Pendaftaran PPDB SMKN 40 Jakarta tahun ajaran 2024/2025 telah dibuka. Informasi lengkap dapat dilihat di website resmi sekolah.',
      'image': 'https://via.placeholder.com/400x200?text=PPDB+2024',
      'author': 'Tim PPDB',
      'category': 'ppdb',
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN role TEXT NOT NULL DEFAULT "user"');
      await _createDatabase(db, newVersion);
    }
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
        'role': 'user',
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

  // News CRUD operations
  Future<List<Map<String, dynamic>>> getAllNews() async {
    try {
      final db = await database;
      return await db.query(
        'news',
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting all news: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    try {
      final db = await database;
      return await db.query(
        'news',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error searching news: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getNewsByCategory(String category) async {
    try {
      final db = await database;
      return await db.query(
        'news',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      print('Error getting news by category: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addNews({
    required String title,
    required String content,
    required String author,
    required String category,
    String? image,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final newsId = await db.insert('news', {
        'title': title,
        'content': content,
        'image': image,
        'author': author,
        'category': category,
        'created_at': now,
        'updated_at': now,
      });

      return {
        'success': true,
        'message': 'Berita berhasil ditambahkan',
        'newsId': newsId,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> updateNews({
    required int newsId,
    required String title,
    required String content,
    required String category,
    String? image,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();

      final result = await db.update(
        'news',
        {
          'title': title,
          'content': content,
          'category': category,
          'image': image,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [newsId],
      );

      return {
        'success': result > 0,
        'message': result > 0 ? 'Berita berhasil diperbarui' : 'Berita tidak ditemukan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> deleteNews(int newsId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'news',
        where: 'id = ?',
        whereArgs: [newsId],
      );

      return {
        'success': result > 0,
        'message': result > 0 ? 'Berita berhasil dihapus' : 'Berita tidak ditemukan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // User management
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
    String? profileImage,
  }) async {
    try {
      final db = await database;
      Map<String, dynamic> updateData = {'name': name, 'email': email};
      
      if (profileImage != null) {
        updateData['profile_image'] = profileImage;
      }
      
      final result = await db.update(
        'users',
        updateData,
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  Future<bool> updateUserProfileImage({
    required int userId,
    required String profileImage,
  }) async {
    try {
      final db = await database;
      final result = await db.update(
        'users',
        {'profile_image': profileImage},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return result > 0;
    } catch (e) {
      print('Error updating profile image: $e');
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