import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/entities/user.dart';
import 'package:gazelle_mysql_plugin/gazelle_mysql_plugin.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';

import 'dart:core';

void main() async {
  final app = GazelleApp(
    port: 3001,
    plugins: [
      GazelleMysqlPluginBase(
        modelToCreate: BackendModelProvider().modelTypes.keys.toList(),
      )
    ],
    modelProvider: BackendModelProvider(),
    routes: [
      GazelleRoute(
          name: "hello_gazelle",
          get: (context, request, response) async {
            final id =
                await context.getPlugin<GazelleMysqlPluginBase>().insert(User(
                      id: null,
                      name: "name",
                      email: "email",
                      age: 20,
                      dateOfBirth: DateTime.now(),
                      height: 1.8,
                      isDeleted: false,
                      password: "password",
                    ));
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: "Insert Done! id: $id",
            );
          }),
      GazelleRoute(
        name: "get",
        children: [
          GazelleRoute.parameter(
            name: "id",
            get: (context, request, response) {
              if (request.pathParameters['id'] == null) {
                return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.badRequest_400,
                  body: "id is required",
                );
              }
              var stopWatch = Stopwatch()..start();
              final artists = context
                  .getPlugin<GazelleMysqlPluginBase>()
                  .get<User>(request.pathParameters['id']!);
              stopWatch.stop();
              print('Execution time: ${stopWatch.elapsedMilliseconds}ms');
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.success.ok_200,
                body: artists,
              );
            },
          )
        ],
      ),
      GazelleRoute(
          name: 'getAll',
          get: (context, request, response) {
            final artists =
                context.getPlugin<GazelleMysqlPluginBase>().getAll<User>();
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: artists,
            );
          }),
      GazelleRoute(
          name: 'drop_table',
          get: (context, request, response) async {
            context.getPlugin<GazelleMysqlPluginBase>().dropTable(User);
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: "Table dropped",
            );
          }),
    ],
  );

  await app.start();
  print("Gazelle listening at ${app.serverAddress}");
}
