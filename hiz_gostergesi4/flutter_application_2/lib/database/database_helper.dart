import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  Future<Database> _initializeDatabase() async {
    // Uygulamanın yerel dosya yolunu al
    String dbPath = join(await getDatabasesPath(), 'hiz_gostergesi.sqlite');

    // Eğer veritabanı yoksa, assets klasöründen kopyala
    if (!await File(dbPath).exists()) {
      ByteData data = await rootBundle.load('assets/database/hiz_gostergesi.sqlite');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes);
    }

    // Veritabanını aç ve döndür
    return await openDatabase(dbPath);
  }

  // Veritabanından veri alma
  Future<List<Map<String, dynamic>>> getTripData() async {
    final db = await database;
    return await db.query('trip_data'); // Tablo adınızı kontrol edin
  }

  // Veritabanını güncelleme
  Future<void> updateTripData(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'trip_data',
      data,
      where: 'id = ?',
      whereArgs: [1], // Güncellenecek satırın ID'si
    );
  }
}
