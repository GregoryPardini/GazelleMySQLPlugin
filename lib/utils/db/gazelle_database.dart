import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/db_checker/db_checker.dart';
import 'package:gazelle_mysql_plugin/utils/query/query_manager.dart';
import 'package:gazelle_mysql_plugin/utils/query/sys_query.dart';
import 'package:gazelle_mysql_plugin/utils/query/table_updater.dart';
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
  }

  QueryManager get queryManager => _queryManager;
  SysQuery get sysQuery => _sysQuery;
}
