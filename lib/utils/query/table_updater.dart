import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/query/type_convert.dart';
import 'package:sqlite3/sqlite3.dart';

enum DropType {
  // soft drop will not delete the column but will set column type to nullable
  soft,
  // hard drop will delete the column
  hard,
}

class TableUpdater {
  final Database _db;
  final BackendModelProvider _backendModelProvider;
  final TypeConvert _typeConvert;

  TableUpdater(this._db, this._backendModelProvider, this._typeConvert);

  Future<void> updateTableSchema({
    required Type entity,
    required Map<String, String> currentSchema,
    required DropType dropType,
  }) async {
    var tableName = entity.toString().toLowerCase();
    var modelAttributes =
        _backendModelProvider.getModelTypeFor(entity).modelAttributes;

    // add columns that are missing
    for (var attributeName in modelAttributes.keys) {
      if (modelAttributes[attributeName] == null) {
        throw Exception('Attribute $attributeName not found in model');
      }
      final columnType =
          _typeConvert.toSqlType(modelAttributes[attributeName]!);

      if (!currentSchema.containsKey(attributeName)) {
        _addColumn(
          tableName: tableName,
          columnName: attributeName,
          columnType: columnType,
        );
      } else {
        // check if the column type is different
        if (currentSchema[attributeName] != columnType) {
          throw Exception(
              'Column $attributeName type is different in the model');
        }
      }
    }

    // remove columns that are not in the model
    for (var columnName in currentSchema.keys) {
      if (currentSchema[columnName] == null) {
        throw Exception('Column $columnName not found in schema');
      }
      if (!modelAttributes.containsKey(columnName)) {
        _dropColumn(
          tableName: tableName,
          columnName: columnName,
          columnType: currentSchema[columnName]!,
          dropType: dropType,
        );
      }
    }
  }

  void _addColumn({
    required String tableName,
    required String columnName,
    required String columnType,
  }) {
    // Crea la query per aggiungere la nuova colonna
    final String query = '''
      ALTER TABLE $tableName ADD COLUMN $columnName $columnType;
    ''';

    // Esegui la query per aggiungere la colonna
    try {
      _db.execute(query);
    } catch (e) {
      throw Exception('Failed to add column $columnName to $tableName: $e');
    }
  }

  void _dropColumn({
    required String tableName,
    required String columnName,
    required String columnType,
    required DropType dropType,
  }) {
    switch (dropType) {
      case DropType.soft:

        // Set the column to nullable
        final String makeNullableQuery = '''
        ALTER TABLE $tableName MODIFY COLUMN $columnName ${columnType.replaceAll(' NOT NULL', '')};
        ''';
        try {
          _db.execute(makeNullableQuery);
          print('Column $columnName in $tableName is not used anymore');
        } catch (e) {
          throw Exception(
              'Failed to modify column $columnName in $tableName: $e');
        }
        break;

      case DropType.hard:
        // Rimuove direttamente la colonna
        final String dropColumnQuery = '''
        ALTER TABLE $tableName DROP COLUMN $columnName;
        ''';
        try {
          _db.execute(dropColumnQuery);
          print('Column $columnName in $tableName has been dropped');
        } catch (e) {
          throw Exception(
              'Failed to drop column $columnName from $tableName: $e');
        }
        break;
    }
  }
}
