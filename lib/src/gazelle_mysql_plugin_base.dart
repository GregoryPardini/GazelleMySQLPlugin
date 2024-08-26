// TODO: Put public facing types in this file.

import 'package:gazelle_core/gazelle_core.dart';

import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';
import 'package:gazelle_mysql_plugin/utils/db/gazelle_database.dart';
import 'package:gazelle_mysql_plugin/utils/query/db_transaction.dart';

import 'package:gazelle_mysql_plugin/utils/query/table_updater.dart';

class GazelleMysqlPluginBase implements GazellePlugin {
  // public attributes
  final BackendModelProvider _backendModelProvider;
  final DropType dropType;

  GazelleMysqlPluginBase({
    required BackendModelProvider backendModelProvider,
    this.dropType = DropType.soft,
  }) : _backendModelProvider = backendModelProvider;

  // private attributes
  late final GazelleDatabase _db;

  @override
  Future<void> initialize(GazelleContext context) async {
    _db = await GazelleDatabase.open(
      'gazelle.db',
      _backendModelProvider,
      dropType: dropType,
    );
    context.addRoutes(_db.routes);
  }

  /// Insert an entity into the database
  /// Returns the id of the inserted entity
  /// Throws an exception if an error occurs
  /// Example:
  /// ```dart
  /// final id = await context.getPlugin<GazelleMysqlPluginBase>().insert(User(
  ///   id: null,
  ///   name: "name",
  ///   email: "email",
  ///   age: 20,
  ///   dateOfBirth: DateTime.now(),
  ///   height: 1.8,
  ///   isDeleted: false,
  ///   password: "password",
  /// ));
  /// ```
  /// The above code will insert a new user into the database
  /// and return the id of the inserted user
  Future<String?> insert<T>(T entity) => _db.insert<T>(entity);

  /// Get an entity from the database
  /// Returns the entity if found, otherwise returns null
  /// Throws an exception if an error occurs
  /// Example:
  /// ```dart
  /// final user = context.getPlugin<GazelleMysqlPluginBase>().get<User>('id');
  /// ```
  /// The above code will get the user with the id 'id' from the database
  /// and return the user if found, otherwise return null
  /// The type of the entity is inferred from the type of the variable
  /// in which the result is stored
  /// If the entity is not found, the result will be null
  /// If an error occurs, an exception will be thrown
  Future<T?> get<T>(String id) => _db.get<T>(id);

  /// Get all entities of a given type from the database
  /// Returns a list of entities if found, otherwise returns an empty list
  /// Throws an exception if an error occurs
  /// Example:
  /// ```dart
  /// final users = context.getPlugin<GazelleMysqlPluginBase>().getAll<User>();
  /// ```
  /// The above code will get all the users from the database
  /// and return a list of users if found, otherwise return an empty list
  /// The type of the entity is inferred from the type of the variable
  /// in which the result is stored
  /// If no entities are found, the result will be an empty list
  /// If an error occurs, an exception will be thrown
  Future<List<T>> getAll<T>() => _db.getAll<T>();

  /// Update an entity in the database
  /// Returns the updated entity
  /// Throws an exception if an error occurs
  /// Example:
  /// ```dart
  /// final updatedUser = context.getPlugin<GazelleMysqlPluginBase>().update<User>(user);
  /// ```
  /// The above code will update the user in the database
  /// and return the updated user
  Future<String?> update<T>(T entity, {bool updateRecursive = true}) =>
      _db.update<T>(entity, updateRecursive);

  /// Delete an entity from the database
  /// Returns the id of the deleted entity
  /// Throws an exception if an error occurs
  /// Example:
  /// ```dart
  /// final id = context.getPlugin<GazelleMysqlPluginBase>().delete<User>('id');
  /// ```
  /// The above code will delete the user with the id 'id' from the database
  /// and return the id of the deleted user
  Future<String?> delete<T>(String id, bool deleteRecursive) =>
      _db.delete<T>(id, deleteRecursive);

  Future<List<dynamic>> transaction(List<DbTransaction> operations) =>
      _db.transaction(operations);
}
