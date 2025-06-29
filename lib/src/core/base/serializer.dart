import '../../adapter/request.dart';

mixin Deserializable {
  Future<dynamic> deserialize(DianaRequest request, Type type);
}

mixin Serializable {
  dynamic serialize(dynamic object);
}
