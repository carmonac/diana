import 'package:diana/src/http/interfaces.dart';

mixin Deserializable {
  Future<dynamic> deserialize(DianaRequest request, Type type);
}

mixin Serializable {
  dynamic serialize(dynamic object);
}
