import 'package:sqlite3/sqlite3.dart';

class SysQuery {
  final Database _db;

  SysQuery(this._db);

  Map<String, String> getCurrentSchema(String tableName) {
    // base query to get the schema of the table
    final String query = '''
      SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT, EXTRA
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_NAME = $tableName;
    ''';

    // run the query and get the result
    final result = _db.select(query);

    if (result.isEmpty) {
      throw Exception('Table $tableName does not exist');
    }

    // create a map to store the schema
    final schema = <String, String>{};

    // iterate over the result and add the schema to the map
    for (var row in result) {
      schema[row['COLUMN_NAME']] = "${row['DATA_TYPE']} ${row['IS_NULLABLE']}";
    }
    // return the schema
    return schema;
  }

  List<String> getTables() {
    // base query to get the tables
    final String query = '''
      SELECT table_name
      FROM information_schema.TABLES;
    ''';

    // run the query and get the result
    try {
      final result = _db.select(query);
      // create a list to store the tables
      final List<String> tables = [];

      // iterate over the result and add the tables to the list
      for (var row in result) {
        tables.add(row['TABLE_NAME']);
      }

      // return the tables
      return tables;
    } catch (e) {
      throw Exception('Failed to get tables: $e');
    }
  }
}
