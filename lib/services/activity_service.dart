import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/activity.dart';
import '../models/activity_sample.dart';

/// SQLite-backed service for storing and retrieving workout activities.
class ActivityService {
  Database? _db;

  /// Visible for testing: allows injecting a pre-opened database.
  @visibleForTesting
  ActivityService({Database? database}) : _db = database;

  /// Production constructor.
  ActivityService.create();

  /// Whether the database has been initialized.
  bool get isInitialized => _db != null;

  /// Initialize the database. Must be called before any other methods.
  Future<void> init() async {
    if (_db != null) return;
    final dbPath = join(await getDatabasesPath(), 'resistance_app.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Activities table
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        avg_heart_rate INTEGER,
        max_heart_rate INTEGER,
        avg_watts INTEGER,
        max_watts INTEGER,
        avg_mph REAL,
        max_mph REAL,
        avg_cadence INTEGER,
        avg_resistance INTEGER,
        calories INTEGER,
        notes TEXT,
        source TEXT DEFAULT 'resistance_app',
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_activities_started_at ON activities(started_at DESC)',
    );

    // Activity samples table (per-second time-series data)
    await db.execute('''
      CREATE TABLE activity_samples (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        heart_rate INTEGER,
        watts INTEGER,
        cadence INTEGER,
        speed_mph REAL,
        resistance INTEGER,
        FOREIGN KEY (activity_id) REFERENCES activities(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_samples_activity_id ON activity_samples(activity_id)',
    );
    await db.execute(
      'CREATE INDEX idx_samples_timestamp ON activity_samples(activity_id, timestamp)',
    );

    // Future: user_profile table for weight, height, age, max HR, FTP
  }

  /// Insert an activity and its samples in a single transaction.
  Future<int> insertWithSamples(
    Activity activity,
    List<ActivitySample> samples,
  ) async {
    final db = _db!;
    late int activityId;

    await db.transaction((txn) async {
      activityId = await txn.insert('activities', activity.toMap());

      for (final sample in samples) {
        final map = sample.toMap();
        map['activity_id'] = activityId;
        await txn.insert('activity_samples', map);
      }
    });

    return activityId;
  }

  /// Get all activities ordered by start time (newest first).
  /// Supports pagination with [limit] and [offset].
  Future<List<Activity>> getAll({int? limit, int? offset}) async {
    final db = _db!;
    final results = await db.query(
      'activities',
      orderBy: 'started_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => Activity.fromMap(row)).toList();
  }

  /// Get a single activity by ID, or null if not found.
  Future<Activity?> getById(int id) async {
    final db = _db!;
    final results = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Activity.fromMap(results.first);
  }

  /// Get all samples for an activity, ordered by timestamp.
  Future<List<ActivitySample>> getSamples(int activityId) async {
    final db = _db!;
    final results = await db.query(
      'activity_samples',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'timestamp ASC',
    );
    return results.map((row) => ActivitySample.fromMap(row)).toList();
  }

  /// Delete an activity and its samples (cascaded by FK).
  Future<void> delete(int id) async {
    final db = _db!;
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  /// Count total number of stored activities.
  Future<int> count() async {
    final db = _db!;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM activities');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close the database.
  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
