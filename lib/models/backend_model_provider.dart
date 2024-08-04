import 'package:gazelle_mysql_plugin/entities/post.dart';
import 'package:gazelle_mysql_plugin/models/post_model_type.dart';
import 'package:gazelle_serialization/gazelle_serialization.dart';

import '../entities/user.dart';
import 'user_model_type.dart';

class BackendModelProvider extends GazelleModelProvider {
  @override
  Map<Type, GazelleModelType> get modelTypes {
    return {
      User: UserModelType(),
      Post: PostModelType(),
    };
  }
}
