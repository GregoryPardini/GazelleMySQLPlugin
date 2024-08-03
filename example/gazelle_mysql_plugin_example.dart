import 'package:gazelle_core/gazelle_core.dart';
import 'package:gazelle_mysql_plugin/entities/user.dart';
import 'package:gazelle_mysql_plugin/gazelle_mysql_plugin.dart';
import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';

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
            await context.getPlugin<GazelleMysqlPluginBase>().insert(User(
                  id: null,
                  name: "name",
                  email: "email",
                  age: 20,
                  dateOfBirth: DateTime.now(),
                  height: 1.8,
                  isDeleted: false,
                ));
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: "Insert Done!!",
            );
          }),
      GazelleRoute(
          name: "bye_gazelle",
          get: (context, request, response) {
            final artists =
                context.getPlugin<GazelleMysqlPluginBase>().get<User>('a');
            return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.ok_200,
              body: artists,
            );
          }),
      GazelleRoute(
          name: 'get',
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
