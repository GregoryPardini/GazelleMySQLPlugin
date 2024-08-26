import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/db_checker/db_checker.dart';
import 'package:gazelle_mysql_plugin/utils/query/db_transaction.dart';
import 'package:gazelle_mysql_plugin/utils/query/query_manager.dart';
import 'package:gazelle_mysql_plugin/utils/query/sys_query.dart';
import 'package:gazelle_mysql_plugin/utils/query/table_updater.dart';
import 'package:gazelle_mysql_plugin/utils/router/create_routes.dart';
import 'package:sqlite3/sqlite3.dart';

import '../query/type_convert.dart';

class GazelleDatabase {
  final String filename;
  final DropType dropType;

  final BackendModelProvider _backendModelProvider;
  final Database _db;

  late final QueryManager _queryManager;
  late final TableUpdater _tableUpdater;
  late final DbChecker _dbChecker;
  late final SysQuery _sysQuery;
  late final CreateRoutes _createRoutes;

  /// Creates a new instance of [GazelleDatabase]
  /// [filename] is the name of the database file
  /// [_backendModelProvider] is the model provider
  /// [dropType] is the type of drop to use
  /// [DropType.soft] will not delete the column but will set column type to nullable
  /// [DropType.hard] will delete the column
  /// [DropType.soft] is the default
  GazelleDatabase._(
    this.filename,
    this._backendModelProvider, {
    required this.dropType,
  }) : _db = sqlite3.open(filename) {
    TypeConvert typeConvert = TypeConvert(modelProvider: _backendModelProvider);

    _sysQuery = SysQuery(_db);
    _queryManager = QueryManager(_db, _backendModelProvider, typeConvert);
    _tableUpdater = TableUpdater(_db, _backendModelProvider, typeConvert);
    _dbChecker = DbChecker(_tableUpdater, _queryManager, _sysQuery);
    _createRoutes = CreateRoutes(_backendModelProvider);
  }

  static Future<GazelleDatabase> open(
    String filename,
    BackendModelProvider backendModelProvider, {
    required DropType dropType,
  }) async {
    final db =
        GazelleDatabase._(filename, backendModelProvider, dropType: dropType);
    await db.initialize();
    return db;
  }

  Future<void> initialize() async {
    final List<Type> modelToCreate =
        _backendModelProvider.modelTypes.keys.toList();
    await _dbChecker.checkDb(modelToCreate, dropType);
    await _createRoutes.createRoute(
        modelToCreate, insert, get, getAll, update, delete);
  }

  /// Close the database
  /// This should be called when the database is no longer needed
  /// Example:
  /// ```dart
  /// await db.close();
  /// ```
  void close() {
    _db.dispose();
  }

  Future<String> insert<T>(T entity) async {
    InsertTransaction insertTransaction = InsertTransaction(entity: entity);

    try {
      final id = await insertTransaction.execute(
          _queryManager, _backendModelProvider, _sysQuery);
      return id;
    } catch (e) {
      throw Exception('Error inserting data: $e');
    }
  }

  Future<T?> get<T>(String id, {Type? type}) async {
    GetTransaction getTransaction =
        GetTransaction(id: id, entityType: type ?? T);
    try {
      final entity = await getTransaction.execute(
          _queryManager, _backendModelProvider, _sysQuery);
      return entity;
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }

  Future<List<T>> getAll<T>() async {
    GetAllTransaction<T> getAllTransaction = GetAllTransaction<T>();
    try {
      final List<T> entities = await getAllTransaction.execute(
          _queryManager, _backendModelProvider, _sysQuery);
      return entities;
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }

  Future<String> update<T>(T entity, bool updateRecursive) async {
    UpdateTransaction updateTransaction =
        UpdateTransaction(entity: entity, updateRecursive: updateRecursive);

    try {
      final updatedEntity = updateTransaction.execute(
          _queryManager, _backendModelProvider, _sysQuery);
      return await updatedEntity;
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }

  Future<String> delete<T>(String id, bool deleteRecursive,
      {Type? type}) async {
    DeleteTransaction deleteTransaction = DeleteTransaction(
      id: id,
      entityType: type ?? T,
      deleteRecursive: deleteRecursive,
    );
    try {
      final id = await deleteTransaction.execute(
          _queryManager, _backendModelProvider, _sysQuery);
      return id;
    } catch (e) {
      throw Exception('Error deleting data: $e');
    }
  }

  Future<List<dynamic>> transaction(List<DbTransaction> operations) async {
    try {
      _sysQuery.beginTransaction();

      final List<dynamic> results = [];
      for (var operation in operations) {
        final result = await operation.execute(
          _queryManager,
          _backendModelProvider,
          _sysQuery,
        );
        results.add(result);
      }

      _sysQuery.commitTransaction();
      print('Transaction completed successfully.');
      return results;
    } catch (e) {
      _sysQuery.rollbackTransaction();
      print('Error during transaction: $e');
      throw Exception('Transaction failed: $e');
    }
  }

  QueryManager get queryManager => _queryManager;
  SysQuery get sysQuery => _sysQuery;
  List<GazelleRoute> get routes => _createRoutes.routes;
}
