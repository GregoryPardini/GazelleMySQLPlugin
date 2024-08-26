import 'dart:convert';

import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';

class CreateRoutes {
  final BackendModelProvider _backendModelProvider;
  final List<GazelleRoute> routes = [];
  CreateRoutes(this._backendModelProvider);

  Future<void> createRoute(
    List<Type> modelToCreate,
    Future<String> Function<T>(T) insert,
    Future<T?> Function<T>(String, {Type type}) get,
    Future<List<T>> Function<T>() getAll,
    Future<String> Function<T>(T, bool) update,
    Future<String> Function<T>(String, bool, {Type type}) delete,
  ) async {
    for (var entityType in modelToCreate) {
      final modelType = _backendModelProvider.getModelTypeFor(entityType);

      routes.add(
        GazelleRoute(
          name: entityType.toString().toLowerCase(),
          post: (context, request, response) async {
            final body = await request.body;
            if (body == null) {
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.error.badRequest_400,
                body: 'Body is required',
              );
            }
            final Map<String, dynamic> bodyJson;
            try {
              bodyJson = jsonDecode(body);
            } catch (e) {
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.error.badRequest_400,
                body: 'Invalid body',
              );
            }

            try {
              final entity = modelType.fromJson(bodyJson);
              try {
                final id = await insert(entity);
                return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.success.ok_200,
                  body: id,
                );
              } catch (e) {
                return GazelleResponse(
                  statusCode:
                      GazelleHttpStatusCode.error.internalServerError_500,
                  body: 'Error inserting entity: $e',
                );
              }
            } catch (e) {
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.error.badRequest_400,
                body: 'Invalid body',
              );
            }
          },
          children: [
            GazelleRoute.parameter(
              name: 'id',
              get: (context, request, response) async {
                final id = request.pathParameters['id'];
                if (id == null) {
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.error.badRequest_400,
                    body: 'Id is required',
                  );
                }
                try {
                  final entity = await get(id, type: entityType);

                  if (entity == null) {
                    return GazelleResponse(
                      statusCode: GazelleHttpStatusCode.error.notFound_404,
                      body: 'Entity not found',
                    );
                  }
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.success.ok_200,
                    body: jsonEncode(modelType.toJson(entity)),
                  );
                } catch (e) {
                  return GazelleResponse(
                    statusCode:
                        GazelleHttpStatusCode.error.internalServerError_500,
                    body: 'Error getting entity: $e',
                  );
                }
              },
              put: (context, request, response) async {
                final id = request.pathParameters['id'];
                if (id == null) {
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.error.badRequest_400,
                    body: 'Id is required',
                  );
                }
                final body = await request.body;
                if (body == null) {
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.error.badRequest_400,
                    body: 'Body is required',
                  );
                }
                final bodyJson = jsonDecode(body);
                try {
                  final entity = modelType.fromJson(bodyJson);
                  try {
                    final updatedId = await update(entity, true);
                    return GazelleResponse(
                      statusCode: GazelleHttpStatusCode.success.ok_200,
                      body: updatedId,
                    );
                  } catch (e) {
                    return GazelleResponse(
                      statusCode:
                          GazelleHttpStatusCode.error.internalServerError_500,
                      body: 'Error updating entity: $e',
                    );
                  }
                } catch (e) {
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.error.badRequest_400,
                    body: 'Invalid body',
                  );
                }
              },
              delete: (context, request, response) {
                final id = request.pathParameters['id'];
                if (id == null) {
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.error.badRequest_400,
                    body: 'Id is required',
                  );
                }
                try {
                  final deletedId = delete(id, true, type: entityType);
                  return GazelleResponse(
                    statusCode: GazelleHttpStatusCode.success.ok_200,
                    body: deletedId,
                  );
                } catch (e) {
                  return GazelleResponse(
                    statusCode:
                        GazelleHttpStatusCode.error.internalServerError_500,
                    body: 'Error deleting entity: $e',
                  );
                }
              },
            ),
          ],
        ),
      );
    }
  }
}
