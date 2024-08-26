import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/query/query_manager.dart';
import 'package:gazelle_mysql_plugin/utils/query/sys_query.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

abstract class DbTransaction {
  Future<dynamic> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery);
}

class InsertTransaction<T> implements DbTransaction {
  final T entity;

  InsertTransaction({required this.entity});

  @override
  Future<String> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery) async {
    final PreparedStatement statement = queryManager.insert(entity);

    // get the model type
    final modelType = backendModelProvider.getModelTypeFor(entity.runtimeType);

    // get the json data from the model
    final jsonData = modelType.toJson(entity);

    sysQuery.beginTransaction();

    for (var entry in modelType.modelAttributes.entries) {
      final key = entry.key;
      var value = entry.value;
      if (value.endsWith('?')) {
        value = value.substring(0, value.length - 1);
      }
      if (backendModelProvider.modelTypes.entries
          .map((e) => e.key.toString())
          .toList()
          .contains(value)) {
        // Check if the related object is null
        if (jsonData[key] == null) {
          // Skip insertion of null related objects
          continue;
        }

        if (jsonData[key]['id'] == null) {
          // We need to insert the related model first
          sysQuery.beginTransaction();
          try {
            final modelTypeToInsert = backendModelProvider.modelTypes.entries
                .firstWhere((element) => element.key.toString() == value);
            final entityToInsert =
                modelTypeToInsert.value.fromJson(jsonData[key]);

            final id = await InsertTransaction(entity: entityToInsert)
                .execute(queryManager, backendModelProvider, sysQuery);
            jsonData[key] = id;
            sysQuery.commitTransaction();
          } catch (e) {
            sysQuery.rollbackTransaction();
            throw Exception('Error inserting related data: $e');
          }
        } else {
          jsonData[key] = jsonData[key]['id'];
        }
      }
    }

    // Check and assign UUID if id is null
    if (jsonData['id'] == null) {
      var uuid = Uuid();
      jsonData['id'] = uuid.v4(); // Generate a version 4 UUID
    }

    final parametersData = addPrefixRecursively(jsonData, ':');

    try {
      statement.executeWith(StatementParameters.named(parametersData));
      sysQuery.commitTransaction();
      return Future.value(jsonData['id']);
    } catch (e) {
      sysQuery.rollbackTransaction();
      throw Exception('Error inserting data: $e');
    }
  }

  Map<String, dynamic> addPrefixRecursively(
      Map<String, dynamic> data, String prefix,
      {int depth = 0, int maxDepth = 100}) {
    if (depth >= maxDepth) {
      throw Exception('Max depth reached. Possible circular reference.');
    }

    return data.map((key, value) {
      String newKey = '$prefix$key';
      dynamic newValue = value;

      if (value is Map<String, dynamic>) {
        newValue = addPrefixRecursively(value, prefix,
            depth: depth + 1, maxDepth: maxDepth);
      } else if (value is List) {
        newValue = value.map((item) {
          if (item is Map<String, dynamic>) {
            return addPrefixRecursively(item, prefix,
                depth: depth + 1, maxDepth: maxDepth);
          }
          return item;
        }).toList();
      }

      return MapEntry(newKey, newValue);
    });
  }
}

class UpdateTransaction<T> implements DbTransaction {
  final T entity;
  final bool updateRecursive;

  UpdateTransaction({required this.entity, required this.updateRecursive});

  @override
  Future<String> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery) async {
    final PreparedStatement statement = queryManager.update(entity);
    // Get the model type
    final modelType = backendModelProvider.getModelTypeFor(entity.runtimeType);
    // Get the json data from the model
    final jsonData = modelType.toJson(entity);
    sysQuery.beginTransaction();
    if (updateRecursive) {
      for (var entry in modelType.modelAttributes.entries) {
        final key = entry.key;
        var value = entry.value;

        if (value.endsWith('?')) {
          value = value.substring(0, value.length - 1);
        }
        if (backendModelProvider.modelTypes.entries
            .map((e) => e.key.toString())
            .toList()
            .contains(value)) {
          if (jsonData[key] != null) {
            // Update or insert the related model
            sysQuery.beginTransaction();
            try {
              final modelTypeToUpdate = backendModelProvider.modelTypes.entries
                  .firstWhere((element) => element.key.toString() == value);
              final entityToUpdate =
                  modelTypeToUpdate.value.fromJson(jsonData[key]);

              if (jsonData[key]['id'] != null) {
                // Update existing related entity
                final id = await UpdateTransaction(
                        entity: entityToUpdate, updateRecursive: true)
                    .execute(queryManager, backendModelProvider, sysQuery);
                // TODO> Fix this
                jsonData[key] = id;
              } else {
                // Insert new related entity
                final id = await InsertTransaction(entity: entityToUpdate)
                    .execute(queryManager, backendModelProvider, sysQuery);
                jsonData[key] = id;
              }
              sysQuery.commitTransaction();
            } catch (e) {
              sysQuery.rollbackTransaction();
              throw Exception('Error updating/inserting related data: $e');
            }
          }
        }
      }
    }
    final parametersData = addPrefixRecursively(jsonData, ':');

    try {
      statement.executeWith(StatementParameters.named(parametersData));
      sysQuery.commitTransaction();
      // Return the updated entity
      return Future.value(jsonData['id']);
    } catch (e) {
      sysQuery.rollbackTransaction();
      throw Exception('Error updating data: $e');
    }
  }

  Map<String, dynamic> addPrefixRecursively(
      Map<String, dynamic> data, String prefix,
      {int depth = 0, int maxDepth = 100}) {
    if (depth >= maxDepth) {
      throw Exception('Max depth reached. Possible circular reference.');
    }

    return data.map((key, value) {
      String newKey = '$prefix$key';
      dynamic newValue = value;

      if (value is Map<String, dynamic>) {
        newValue = addPrefixRecursively(value, prefix,
            depth: depth + 1, maxDepth: maxDepth);
      } else if (value is List) {
        newValue = value.map((item) {
          if (item is Map<String, dynamic>) {
            return addPrefixRecursively(item, prefix,
                depth: depth + 1, maxDepth: maxDepth);
          }
          return item;
        }).toList();
      }

      return MapEntry(newKey, newValue);
    });
  }
}

class DeleteTransaction implements DbTransaction {
  final String id;
  final Type entityType;
  final bool deleteRecursive;

  DeleteTransaction({
    required this.id,
    required this.entityType,
    required this.deleteRecursive,
  });

  @override
  Future<String> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery) async {
    final PreparedStatement statement = queryManager.delete(entityType);
    final modelType = backendModelProvider.getModelTypeFor(entityType);

    sysQuery.beginTransaction();

    try {
      if (deleteRecursive) {
        // Fetch the entity if we need to delete related entities
        final entity = await GetTransaction(id: id, entityType: entityType)
            .execute(queryManager, backendModelProvider, sysQuery);
        if (entity != null) {
          if (deleteRecursive) {
            final jsonData = modelType.toJson(entity);

            for (var entry in modelType.modelAttributes.entries) {
              final key = entry.key;
              var value = entry.value;
              if (value.endsWith('?')) {
                value = value.substring(0, value.length - 1);
              }
              if (backendModelProvider.modelTypes.entries
                  .map((e) => e.key.toString())
                  .toList()
                  .contains(value)) {
                if (jsonData[key] != null) {
                  final modelTypeToDelete = backendModelProvider
                      .modelTypes.entries
                      .firstWhere((element) => element.key.toString() == value);
                  final entityToDelete =
                      modelTypeToDelete.value.fromJson(jsonData[key]);
                  if (entityToDelete['id'] != null) {
                    await DeleteTransaction(
                      id: entityToDelete['id'],
                      deleteRecursive: true,
                      entityType: entityToDelete.runtimeType,
                    ).execute(queryManager, backendModelProvider, sysQuery);
                  }
                }
              }
            }
          }
        }
      }

      statement.executeWith(StatementParameters([id]));
      sysQuery.commitTransaction();
      return Future.value(id);
    } catch (e) {
      sysQuery.rollbackTransaction();
      throw Exception('Error deleting data: $e');
    }
  }
}

class GetTransaction implements DbTransaction {
  final String id;
  final Type entityType;

  final int _maxDepth;
  final Set<String> _visitedIds;

  GetTransaction({
    required this.id,
    required this.entityType,
    int maxDepth = 10,
    Set<String>? visitedIds,
  })  : _maxDepth = maxDepth,
        _visitedIds = (visitedIds != null) ? Set<String>.from(visitedIds) : {};

  @override
  Future<dynamic> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, SysQuery sysQuery) async {
    if (_visitedIds.contains(id) || _maxDepth <= 0) {
      throw Exception('Circular reference detected or max depth reached');
    }
    final modelType = backendModelProvider.getModelTypeFor(entityType);
    final PreparedStatement statement = queryManager.get(entityType);

    try {
      final result = statement.select([id]);
      if (result.isEmpty) {
        return null;
      }

      Map<String, dynamic> jsonData = Map<String, dynamic>.from(result.first);
      _visitedIds.add(id);

      for (var entry in modelType.modelAttributes.entries) {
        final key = entry.key;
        var value = entry.value;
        if (value.endsWith('?')) {
          value = value.substring(0, value.length - 1);
        }
        if (backendModelProvider.modelTypes.entries
            .map((e) => e.key.toString())
            .toList()
            .contains(value)) {
          if (jsonData[key] != null) {
            final relatedModelType = backendModelProvider.modelTypes.entries
                .firstWhere((element) => element.key.toString() == value);
            final relatedId = jsonData[key];
            if (relatedId != null) {
              // Fetch the related entity
              final relatedEntity = await GetTransaction(
                id: relatedId,
                entityType: relatedModelType.key,
                maxDepth: _maxDepth - 1,
                visitedIds: _visitedIds,
              ).execute(queryManager, backendModelProvider, sysQuery);
              if (relatedEntity != null) {
                jsonData[key] = relatedModelType.value.toJson(relatedEntity);
              }
            }
          }
        }
      }

      return Future.value(modelType.fromJson(jsonData));
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }
}

class GetAllTransaction<T> implements DbTransaction {
  @override
  Future<List<T>> execute(QueryManager queryManager,
      BackendModelProvider backendModelProvider, _) async {
    final PreparedStatement statement = queryManager.getAllIds<T>();

    // run the statement
    final result = statement.select();

    // check if the result is empty
    if (result.isEmpty) {
      return [];
    }

    try {
      List<Future<T>> futures = result.map((row) async {
        final model = await GetTransaction(
          id: row['id'],
          entityType: T,
        ).execute(queryManager, backendModelProvider, _);
        return model as T;
      }).toList();

      return await Future.wait(futures);
    } catch (e) {
      throw Exception('Error getting data: $e');
    }
  }
}
