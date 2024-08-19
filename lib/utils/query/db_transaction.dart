import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/query/query_manager.dart';
import 'package:gazelle_mysql_plugin/utils/query/sys_query.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

abstract class DbTransaction<T> {
  T execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery);
}

class InsertTransaction<T> implements DbTransaction<String?> {
  final T entity;

  InsertTransaction({required this.entity});

  @override
  String? execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery) {
    final PreparedStatement statement = queryManager.insert<T>();

    // get the model type
    final modelType = backendModelProvider.getModelTypeFor(entity.runtimeType);

    // get the json data from the model
    final jsonData = modelType.toJson(entity).map((key, value) {
      return MapEntry(":$key", value);
    });

    // modelType.modelAttributes.forEach((key, value) {
    //   if (value.endsWith('?')) {
    //     value = value.substring(0, value.length - 1);
    //   }
    //   if (backendModelProvider.modelTypes.entries
    //       .map((e) => e.key.toString())
    //       .toList()
    //       .contains(value)) {
    //     if (jsonData[':$key']['id'] == null) {
    //       // We need to insert the related model first
    //       sysQuery.beginTransaction();
    //       try {
    //         final modelTypeToInsert = backendModelProvider.modelTypes.entries
    //             .firstWhere((element) => element.key.toString() == value);
    //         final entityToInsert =
    //             modelTypeToInsert.value.fromJson(jsonData[':$key']);
    //       final Type type = modelTypeToInsert.key;
    //       // final Type type = entityToInsert.runtimeType;
    //         final id = InsertTransaction<type>(entity: entityToInsert)
    //             .execute(queryManager, backendModelProvider, sysQuery);
    //         jsonData[':$key']['id'] = id;
    //       } catch (e) {
    //         sysQuery.rollbackTransaction();
    //         throw Exception('Error inserting related data: $e');
    //       }
    //     } else {
    //       jsonData[':$key'] = jsonData[':$key']['id'];
    //     }
    //   }
    // });

    // Check and assign UUID if id is null
    if (jsonData[':id'] == null) {
      var uuid = Uuid();
      jsonData[':id'] = uuid.v4(); // Generate a version 4 UUID
    }

    try {
      statement.executeWith(StatementParameters.named(jsonData));
      sysQuery.commitTransaction();
      return jsonData[':id'];
    } catch (e) {
      sysQuery.rollbackTransaction();
      throw Exception('Error inserting data: $e');
    }
  }
}

class UpdateTransaction<T> implements DbTransaction<T> {
  final T entity;

  UpdateTransaction({required this.entity});

  @override
  T execute(
      QueryManager queryManager, BackendModelProvider backendModelProvider, _) {
    final PreparedStatement statement = queryManager.update<T>();

    // get the model type
    final modelType = backendModelProvider.getModelTypeFor(entity.runtimeType);

    // get the json data from the model
    final jsonData = modelType.toJson(entity).map((key, value) {
      return MapEntry(":$key", value);
    });

    try {
      statement.executeWith(StatementParameters.named(jsonData));
      return entity;
    } catch (e) {
      throw Exception('Error updating data: $e');
    }
  }
}

class DeleteTransaction<T> implements DbTransaction<String?> {
  final String id;

  DeleteTransaction({required this.id});

  @override
  String? execute(
      QueryManager queryManager, BackendModelProvider backendModelProvider, _) {
    final PreparedStatement statement = queryManager.delete<T>();
    try {
      statement.executeWith(StatementParameters([id]));
      return id;
    } catch (e) {
      throw Exception('Error deleting data: $e');
    }
  }
}

class GetTransaction<T> implements DbTransaction<T?> {
  final String id;

  const GetTransaction({required this.id});
  @override
  T? execute(
      QueryManager queryManager, BackendModelProvider backendModelProvider, _) {
    final PreparedStatement statement = queryManager.get<T>();
    final result = statement.select([id]);
    if (result.isEmpty) {
      return null;
    }
    // get the model type
    final modelType = backendModelProvider.getModelTypeFor(T);

    try {
      final model = modelType.fromJson(result.first);
      return model;
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }
}

class GetAllTransaction<T> implements DbTransaction<List<T>> {
  @override
  List<T> execute(
      QueryManager queryManager, BackendModelProvider backendModelProvider, _) {
    final PreparedStatement statement = queryManager.getAll<T>();

    // run the statement
    final result = statement.select();

    // check if the result is empty
    if (result.isEmpty) {
      return [];
    }

    // get the model type
    final modelType = backendModelProvider.getModelTypeFor(T);

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
}
