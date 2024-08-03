// TODO: Put public facing types in this file.

import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/entities/user.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/query/query_builder.dart';
import 'package:gazelle_mysql_plugin/utils/query/sys_query.dart';
import 'package:gazelle_mysql_plugin/utils/query/table_updater.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

class GazelleMysqlPluginBase implements GazellePlugin {
  // public attributes
  final List<Type> modelToCreate;

  GazelleMysqlPluginBase({required this.modelToCreate});

  // private attributes
  late final Database _db;
  final List<Type> _modelTables = [];

  @override
  Future<void> initialize(GazelleContext context) async {
    _db = sqlite3.open('gazelle.db');

    _createTable(User);
  }

  Future<String?> insert<T>(T model) async {
    // get the model type
    final modelType = BackendModelProvider().getModelTypeFor(model.runtimeType);

    // get the map of the model attributes
    final modelAttributeMap = modelType.modelAttributes;

    // get the json data from the model
    final jsonData = modelType.toJson(model);

    // Check and assign UUID if id is null
    if (jsonData['id'] == null) {
      var uuid = Uuid();
      jsonData['id'] = uuid.v4(); // Generate a version 4 UUID
    }

    // create part of the query for the fields
    String fields = modelAttributeMap.keys.join(", ");

    // create part of the query for the values placeholders
    String valuesPlaceholder =
        List.filled(modelAttributeMap.length, "?").join(", ");

    // create the query
    String query =
        "INSERT INTO ${model.runtimeType.toString().toLowerCase()} ($fields) VALUES ($valuesPlaceholder)";

    // get the values from the json data
    List<dynamic> values =
        modelAttributeMap.keys.map((key) => jsonData[key]).toList();

    try {
      _db.execute(query, values);
    } catch (e) {
      throw Exception('Error inserting data: $e');
    }
  }

  T? get<T>(String id) {
    // get the model type that is the name of the table
    final String table = T.toString().toLowerCase();

    // check if the table exists
    if (!_modelTables.contains(T)) {
      throw Exception('Table $table does not exist');
    }

    // create the query
    final query = 'SELECT * FROM $table WHERE id = ?';

    // get the result from the query
    final result = _db.select(query, [id]);

    // check if the result is empty
    if (result.isEmpty) {
      return null;
    }

    // get the first row from the result
    final row = result.first;

    // get the model type
    final modelType = BackendModelProvider().getModelTypeFor(T);

    try {
      // get the model from the row
      final User user = modelType.fromJson(row);

      // return the model
      return user as T;
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }

  List<T> getAll<T>() {
    // get the model type that is the name of the table
    final String table = T.toString().toLowerCase();

    // check if the table exists
    if (!_modelTables.contains(T)) {
      throw Exception('Table $table does not exist');
    }

    // create the query
    final query = 'SELECT * FROM $table ';

    // get the result from the query
    final result = _db.select(query);

    // check if the result is empty
    if (result.isEmpty) {
      return [];
    }

    // get the model type
    final modelType = BackendModelProvider().getModelTypeFor(T);

    try {
      List<T> resultList = [];
      for (var row in result) {
        // get the model from the row
        final T model = modelType.fromJson(row);
        // add the model to the list
        resultList.add(model);
      }

      return resultList;
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }

  void _checkDbTables() {
    final tables = SysQuery(_db).getTables();

    for (var model in modelToCreate) {
      // Check if the table exists and create it if it doesn't
      // Otherwise update the table schema adding or removing columns
      if (!tables.contains(model.toString().toLowerCase())) {
        _createTable(model);
      } else {
        TableUpdater(_db).updateTableSchema(model);
      }

      for (var table in tables) {
        if (!modelToCreate
            .map((e) => e.toString().toLowerCase())
            .contains(table)) {
          // notify the user that the table is not used anymore
          print('Table $table is not used anymore');
        }
      }
    }
  }

  void _createTable(Type modelType) async {
    try {
      _db.execute(QueryBuilder.createTable(modelType));
      _modelTables.add(modelType);
    } catch (e) {
      throw Exception('Error creating table: $e');
    }
  }

  void dropTable(Type modelType) async {
    try {
      _db.execute('DROP TABLE IF EXISTS ${modelType.toString().toLowerCase()}');
      _modelTables.remove(modelType);
    } catch (e) {
      throw Exception('Error dropping table: $e');
    }
  }
}
