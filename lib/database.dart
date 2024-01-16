import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';

class DatabaseHelper {
  static Database? _database;
  static const String tableName = 'contacts';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'contacts.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tableName(
            id INTEGER PRIMARY KEY,
            name TEXT,
            phoneNumber TEXT,
            address TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Handle database schema upgrades here
      },
    );
  }

  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return await db.insert(tableName, contact.toMap());
  }

  Future<List<Contact>> getContacts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return List.generate(maps.length, (i) {
      return Contact(
        id: maps[i]['id'] as int?,
        name: maps[i]['name'] as String,
        phoneNumber: maps[i]['phoneNumber'] as String,
        address: maps[i]['address'] as String,
      );
    });
  }

  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return await db.update(tableName, contact.toMap(), where: 'id = ?', whereArgs: [contact.id]);
  }

  Future<int> deleteContact(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }
}
