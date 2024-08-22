import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/entities/post.dart';
import 'package:gazelle_mysql_plugin/entities/user.dart';
import 'package:gazelle_mysql_plugin/gazelle_mysql_plugin.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';

import 'dart:core';

import 'package:gazelle_mysql_plugin/utils/query/db_transaction.dart';

void main() async {
  final modelProvider = BackendModelProvider();
  final app = GazelleApp(
    port: 3001,
    plugins: [GazelleMysqlPluginBase(backendModelProvider: modelProvider)],
    modelProvider: modelProvider,
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
                      post: null,
                    ));
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: "Insert Done! id: $id",
            );
          }),
      GazelleRoute(
          name: 'insert_post',
          get: (context, request, response) async {
            final id = await context.getPlugin<GazelleMysqlPluginBase>().insert(
                  Post(
                    id: null,
                    title: "title",
                    body: "body",
                    likes: 0,
                    createdAt: DateTime.now(),
                    isDeleted: false,
                    viralScore: 0.0,
                    user: User(
                      id: null,
                      name: "name",
                      email: "email",
                      age: 20,
                      dateOfBirth: DateTime.now(),
                      height: 1.8,
                      isDeleted: false,
                      password: "password",
                      post: Post(
                        id: null,
                        title: "title",
                        body: "body",
                        likes: 0,
                        createdAt: DateTime.now(),
                        isDeleted: false,
                        viralScore: 0.0,
                        user: null,
                      ),
                    ),
                  ),
                );
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
            get: (context, request, response) async {
              if (request.pathParameters['id'] == null) {
                return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.badRequest_400,
                  body: "id is required",
                );
              }
              var stopWatch = Stopwatch()..start();
              final artists = await context
                  .getPlugin<GazelleMysqlPluginBase>()
                  .get<Post>(request.pathParameters['id']!);
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
      GazelleRoute(name: 'patch', children: [
        GazelleRoute.parameter(
          name: 'id',
          get: (context, request, response) async {
            if (request.pathParameters['id'] == null) {
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.error.badRequest_400,
                body: "id is required",
              );
            }
            var stopWatch = Stopwatch()..start();
            final artists =
                await context.getPlugin<GazelleMysqlPluginBase>().update<Post>(
                      Post(
                        id: "3ac38594-4f98-4eba-95a9-d1cd1e08bd97",
                        title: "title",
                        body: "body",
                        likes: 0,
                        createdAt: DateTime.now(),
                        isDeleted: false,
                        viralScore: 0.0,
                        user: User(
                          id: null,
                          name: "name",
                          email: "email",
                          age: 20,
                          dateOfBirth: DateTime.now(),
                          height: 1.8,
                          isDeleted: false,
                          password: "password",
                          post: Post(
                            id: null,
                            title: "title",
                            body: "body",
                            likes: 0,
                            createdAt: DateTime.now(),
                            isDeleted: false,
                            viralScore: 0.0,
                            user: null,
                          ),
                        ),
                      ),
                    );
            stopWatch.stop();
            print('Execution time: ${stopWatch.elapsedMilliseconds}ms');
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: artists,
            );
          },
        )
      ]),
      GazelleRoute(
          name: 'getAll',
          get: (context, request, response) async {
            final artists = await context
                .getPlugin<GazelleMysqlPluginBase>()
                .getAll<Post>();
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: artists,
            );
          }),
      GazelleRoute(name: 'delete', children: [
        GazelleRoute.parameter(
          name: 'id',
          get: (context, request, response) async {
            if (request.pathParameters['id'] == null) {
              return GazelleResponse(
                statusCode: GazelleHttpStatusCode.error.badRequest_400,
                body: "id is required",
              );
            }
            var stopWatch = Stopwatch()..start();
            final artists = await context
                .getPlugin<GazelleMysqlPluginBase>()
                .delete<Post>(request.pathParameters['id']!);
            stopWatch.stop();
            print('Execution time: ${stopWatch.elapsedMilliseconds}ms');
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: artists,
            );
          },
        )
      ]),
      GazelleRoute(
          name: 'drop_table',
          get: (context, request, response) async {
            // context.getPlugin<GazelleMysqlPluginBase>().dropTable(User);
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: "Table dropped",
            );
          }),
      GazelleRoute(
        name: 'transaction',
        get: (context, request, response) async {
          final res =
              await context.getPlugin<GazelleMysqlPluginBase>().transaction([
            InsertTransaction(
                entity: User(
              id: null,
              name: "name",
              email: "email",
              age: 20,
              dateOfBirth: DateTime.now(),
              height: 1.8,
              isDeleted: false,
              password: "password",
              post: null,
            )),
            InsertTransaction(
                entity: User(
              id: null,
              name: "name",
              email: "email",
              age: 20,
              dateOfBirth: DateTime.now(),
              height: 1.8,
              isDeleted: false,
              password: "password",
              post: null,
            )),
          ]);

          return GazelleResponse(
            statusCode: GazelleHttpStatusCode.success.ok_200,
            body:
                "Transaction Done!: ${res[0].toString()} ${res[1].toString()}",
          );
        },
      ),
    ],
  );

  await app.start();
  print("Gazelle listening at ${app.serverAddress}");
}
