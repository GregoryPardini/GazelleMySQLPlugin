import 'package:gazelle_mysql_plugin/utils/query/type_convert.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../models/backend_model_provider.dart';

class QueryManager {
  final Database _db;
  final BackendModelProvider _modelProvider;
  final TypeConvert _typeConvert;
  final Map<Type, Map<String, PreparedStatement>> _preparedStatements = {};

  QueryManager(this._db, this._modelProvider, this._typeConvert);

  /// Prepare the statements for the given entity
  /// example: prepareStatementsForEntity<User>();
  Future<void> prepareStatementsForEntity(Type entity) async {
    // add the statement to the prepared statements
    if (!_preparedStatements.containsKey(entity)) {
      _preparedStatements[entity] = {};
    }

    // get the model type
    final modelType = _modelProvider.getModelTypeFor(entity);

    // get the map of the model attributes
    final modelAttributeMap = modelType.modelAttributes;

    // create the insert query
    String fields = modelAttributeMap.keys.join(", ");
    String valuesPlaceholder =
        modelAttributeMap.keys.map((key) => ":$key").join(", ");
    String query =
        "INSERT INTO ${entity.toString().toLowerCase()} ($fields) VALUES ($valuesPlaceholder)";

    // prepare the statement
    final insertStatement = _db.prepare(query, persistent: true);
    _preparedStatements[entity]!['insert'] = insertStatement;

    // create the update query
    String updateFields =
        modelAttributeMap.keys.map((key) => "$key = :$key").join(", ");
    String updateQuery =
        "UPDATE ${entity.toString().toLowerCase()} SET $updateFields WHERE id = :id";

    // prepare the statement
    final updateStatement = _db.prepare(updateQuery, persistent: true);
    _preparedStatements[entity]!['update'] = updateStatement;

    // create the delete query
    String deleteQuery =
        "DELETE FROM ${entity.toString().toLowerCase()} WHERE id = ?";

    // prepare the statement
    final deleteStatement = _db.prepare(deleteQuery, persistent: true);
    _preparedStatements[entity]!['delete'] = deleteStatement;

    // create the select query
    String selectQuery =
        "SELECT * FROM ${entity.toString().toLowerCase()} WHERE id = ?";

    // prepare the statement
    final selectStatement = _db.prepare(selectQuery, persistent: true);
    _preparedStatements[entity]!['select'] = selectStatement;

    // create the table query
    String createTableQuery = _createTableQuery(entity);

    // prepare the statement
    final createTableStatement =
        _db.prepare(createTableQuery, persistent: false);
    _preparedStatements[entity]!['createTable'] = createTableStatement;

    // create the delete table query
    String dropTableQuery =
        "DROP TABLE IF EXISTS ${entity.toString().toLowerCase()}";

    // prepare the statement
    final deleteTableStatement = _db.prepare(dropTableQuery, persistent: false);
    _preparedStatements[entity]!['dropTable'] = deleteTableStatement;
  }

  /// Get the prepared statement get for the given entity
  /// example: get<User>();
  PreparedStatement get(Type entityTye) {
    if (!_preparedStatements.containsKey(entityTye)) {
      throw Exception('Entity not prepared');
    }
    return _preparedStatements[entityTye]!['select']!;
  }

  /// Get the prepared statement insert for the given entity
  /// example: insert<User>();
  PreparedStatement insert(dynamic entity) {
    if (!_preparedStatements.containsKey(entity.runtimeType)) {
      throw Exception('Entity not prepared');
    }
    return _preparedStatements[entity.runtimeType]!['insert']!;
  }

  /// Get the prepared statement update for the given entity
  /// example: update<User>();
  PreparedStatement update(dynamic entity) {
    if (!_preparedStatements.containsKey(entity.runtimeType)) {
      throw Exception('Entity not prepared');
    }
    return _preparedStatements[entity.runtimeType]!['update']!;
  }

  /// Get the prepared statement delete for the given entity
  /// example: delete<User>();
  PreparedStatement delete(Type entityType) {
    if (!_preparedStatements.containsKey(entityType)) {
      throw Exception('Entity not prepared');
    }
    return _preparedStatements[entityType]!['delete']!;
  }

  /// Get the prepared statement getAll for the given entity
  /// example: getAll<User>();
  /// This will return all the data in the table
  PreparedStatement getAll<T>() {
    // check if the entity is prepared
    if (!_preparedStatements.containsKey(T)) {
      throw Exception('Entity not prepared');
    }
    // create the query
    final query = 'SELECT * FROM ${T.toString().toLowerCase()} ';

    // prepare the statement
    final statement = _db.prepare(query);

    return statement;
  }

  PreparedStatement getAllIds<T>() {
    // check if the entity is prepared
    if (!_preparedStatements.containsKey(T)) {
      throw Exception('Entity not prepared');
    }
    // create the query
    final query = 'SELECT id FROM ${T.toString().toLowerCase()} ';

    // prepare the statement
    final statement = _db.prepare(query);

    return statement;
  }

  /// Create the table for the given model type
  /// example: createTable<User>();
  /// This will create the table for the User model
  /// if it does not exist
  /// This is useful for testing purposes
  /// and should not be used in production
  PreparedStatement createTable(Type entity) {
    if (_preparedStatements.containsKey(entity)) {
      throw Exception('Table already exists');
    }
    return _preparedStatements[entity]!['createTable']!;
  }

  /// Delete the table for the given model type
  /// example: deleteTable<User>();
  /// This will delete the table for the User model
  /// and all the data in it
  /// This is useful for testing purposes
  /// and should not be used in production
  /// as it will delete all the data in the table
  /// and the table itself
  PreparedStatement dropTable(Type entity) {
    if (!_preparedStatements.containsKey(entity)) {
      throw Exception('Entity not prepared');
    }
    return _preparedStatements[entity]!['dropTable']!;
  }

  /// Create the table for the given model type
  String _createTableQuery(Type entity) {
    final map = _modelProvider.getModelTypeFor(entity).modelAttributes;
    if (map['id'] == null) {
      throw Exception('Model must have an id attribute String');
    }
    if (map['id'] != 'String' && map['id'] != 'String?') {
      throw Exception(
          'Model( ${entity.toString()} ) id attribute must be of type String');
    }

    var buffer = StringBuffer();
    buffer.write(
        'CREATE TABLE IF NOT EXISTS ${entity.toString().toLowerCase()} (');

    map.forEach((attribute, type) {
      var sqlType = _typeConvert.toSqlType(type);
      buffer.write('$attribute $sqlType, ');
    });

    buffer.write('PRIMARY KEY(id));');

    return buffer.toString();
  }
}
