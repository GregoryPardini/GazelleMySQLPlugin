import 'package:gazelle_mysql_plugin/models/backend_model_provider.dart';

class TypeConvert {
  final BackendModelProvider _modelProvider;
  late final List<String> _customTypes;

  TypeConvert({required BackendModelProvider modelProvider})
      : _modelProvider = modelProvider {
    _customTypes =
        _modelProvider.modelTypes.entries.map((e) => e.key.toString()).toList();
  }

  /// convert a dart type to a SQL type
  String toSqlType(String type) {
    String sqlType = '';
    bool isNullable = type.endsWith('?');
    if (isNullable) {
      type = type.substring(0, type.length - 1);
    }

    switch (type) {
      case 'String':
        sqlType = 'TEXT';
        break;
      case 'int':
        sqlType = 'INTEGER';
      case 'double':
        sqlType = 'DOUBLE';
        break;
      case 'bool':
        sqlType = 'TINYINT(1)';
        break;
      case 'DateTime':
        sqlType = 'DATETIME';
        break;
      default:
        if (_customTypes.contains(type)) {
          sqlType = 'TEXT';
        } else {
          throw Exception('Invalid type');
        }
    }

    if (!isNullable) {
      sqlType += ' NOT NULL';
    }
    return sqlType;
  }

  /// convert a SQL type to a dart type
  static String fromSqlType(String sqlType) {
    String dartType = '';
    bool isNullable = !sqlType.contains('NOT NULL');

    sqlType = sqlType.replaceAll(
        ' NOT NULL', ''); // Pulisce il tipo SQL dai modificatori

    switch (sqlType) {
      case 'TEXT':
        dartType = 'String';
        break;
      case 'INTEGER':
        dartType = 'int';
        break;
      case 'DOUBLE':
        dartType = 'double';
        break;
      case 'TINYINT(1)':
        dartType = 'bool';
        break;
      case 'DATETIME':
        dartType = 'DateTime';
        break;
      default:
        throw Exception('Invalid SQL type');
    }

    if (isNullable) {
      dartType += '?';
    }

    return dartType;
  }
}
