import 'package:gazelle_mysql_plugin/utils/query/query_manager.dart';
import '../query/sys_query.dart';
import '../query/table_updater.dart';

class DbChecker {
  final SysQuery _sysQuery;
  final QueryManager _queryManager;
  final TableUpdater _tableUpdater;

  DbChecker(this._tableUpdater, this._queryManager, this._sysQuery);

  Future<void> checkDb(
    List<Type> modelToCreate,
    DropType dropType,
  ) async {
    final tables = _sysQuery.getTables();
    for (var i = 0; i < modelToCreate.length; i++) {
      final model = modelToCreate[i];
      // Check if the table exists and create it if it doesn't
      // Otherwise update the table schema adding or removing columns
      if (tables
          .where((element) => element.name == model.toString().toLowerCase())
          .isEmpty) {
        _createTable(model);
      } else {
        _tableUpdater.updateTableSchema(
          entity: model,
          dropType: dropType,
          currentSchema: tables[i].columnsType,
        );
      }

      // Prepare the statements for the entity
      _queryManager.prepareStatementsForEntity(model);
    }

    for (var table in tables) {
      if (!modelToCreate
          .map((e) => e.toString().toLowerCase())
          .contains(table.name)) {
        // notify the user that the table is not used anymore
        print('Table ${table.name} is not used anymore');
      }
    }
  }

  void _createTable(Type model) async {
    try {
      final statement = _queryManager.createTable(model);
      statement.execute();
    } catch (e) {
      throw Exception('Error creating table: $e');
    }
  }

  void dropTable(Type model) async {
    try {
      final statement = _queryManager.dropTable(model);
      statement.execute();
    } catch (e) {
      throw Exception('Error dropping table: $e');
    }
  }
}
