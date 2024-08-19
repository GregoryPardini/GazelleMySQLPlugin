import 'package:sqlite3/sqlite3.dart';

class TableInformation {
  final String name;
  final Map<String, String> columnsType;

  TableInformation(this.name, this.columnsType);
}

class SysQuery {
  final Database _db;

  bool _isTransaction = false;
  SysQuery(this._db);

  bool get isTransaction => _isTransaction;

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

  List<TableInformation> getTables() {
    // base query to get the tables
    final String query = '''
      SELECT * FROM sqlite_master WHERE type='table';
    ''';

    // run the query and get the result
    try {
      final result = _db.select(query);
      // create a list to store the tables
      final List<TableInformation> tables = [];

      // iterate over the result and add the tables to the list
      for (var row in result) {
        tables.add(TableInformation(row['name'], parseCreateTable(row['sql'])));
      }

      // return the tables
      return tables;
    } catch (e) {
      throw Exception('Failed to get tables: $e');
    }
  }

  Map<String, String> parseCreateTable(String createTableQuery) {
    // Rimuove la parte iniziale e finale della query per isolare solo le definizioni delle colonne
    final columnSectionStart = createTableQuery.indexOf('(') + 1;
    final columnSectionEnd = createTableQuery.lastIndexOf(')');
    final columnDefinitions =
        createTableQuery.substring(columnSectionStart, columnSectionEnd).trim();

    // Divide le definizioni in righe separate
    List<String> columnLines = columnDefinitions.split(',');

    // Mappa per mantenere i nomi delle colonne e i tipi
    Map<String, String> columns = {};

    // Espressione regolare per estrarre il nome della colonna e il tipo, inclusi i modificatori come NOT NULL
    final columnRegex = RegExp(r'^\s*(\w+)\s+(.+?)\b(?:,|$)');

    for (var line in columnLines) {
      // Pulizia delle informazioni relative a PRIMARY KEY o altre keywords non necessarie
      String cleanedLine = line.replaceAll('PRIMARY KEY', '').trim();

      // Applica l'espressione regolare a ogni riga pulita
      final match = columnRegex.firstMatch(cleanedLine);
      if (match != null) {
        String columnName = match.group(1)!;
        String columnType =
            match.group(2)!.trim(); // Assicura di rimuovere spazi extra

        // Aggiunge solo se il nome della colonna non è vuoto
        if (columnName.isNotEmpty) {
          columns[columnName] = columnType;
        }
      }
    }

    return columns;
  }

  /// Begin a transaction
  Future<void> beginTransaction() async {
    if (_isTransaction) return;
    try {
      _db.execute('BEGIN TRANSACTION;');
      _isTransaction = true;
    } catch (e) {
      throw Exception('Failed to begin transaction: $e');
    }
  }

  /// Commit a transaction
  Future<void> commitTransaction() async {
    if (!_isTransaction) return;
    try {
      _db.execute('COMMIT;');
      _isTransaction = false;
    } catch (e) {
      throw Exception('Failed to commit transaction: $e');
    }
  }

  /// Rollback a transaction
  Future<void> rollbackTransaction() async {
    if (!_isTransaction) return;
    try {
      _db.execute('ROLLBACK;');
      _isTransaction = false;
    } catch (e) {
      throw Exception('Failed to rollback transaction: $e');
    }
  }
}
