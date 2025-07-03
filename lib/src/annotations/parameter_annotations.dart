import '../core/parameter_type.dart';
import '../core/base/base.dart';

abstract class BaseParameterAnnotation {
  final ParameterType type;

  final String? key;

  final List<DianaTransformer<dynamic, dynamic>>? transforms;

  final List<DianaValidator>? validators;

  const BaseParameterAnnotation({
    required this.type,
    this.key,
    this.transforms,
    this.validators,
  });
}

abstract class SimpleParam extends BaseParameterAnnotation {
  const SimpleParam({required super.type, super.key});
}

abstract class ComplexParam extends BaseParameterAnnotation {
  const ComplexParam({
    required super.type,
    super.key,
    super.transforms,
    super.validators,
  });
}

class Query extends ComplexParam {
  const Query({super.key, super.validators, super.transforms})
    : super(type: ParameterType.query);
}

class QueryList extends ComplexParam {
  const QueryList({super.key, super.transforms, super.validators})
    : super(type: ParameterType.queryList);
}

class Param extends ComplexParam {
  const Param({super.key, super.transforms, super.validators})
    : super(type: ParameterType.path);
}

class Body extends ComplexParam {
  final List<String> contentType;
  const Body({
    super.key,
    super.transforms,
    super.validators,
    this.contentType = const ["application/json"],
  }) : super(type: ParameterType.body);
}

class Ip extends SimpleParam {
  const Ip() : super(type: ParameterType.ip);
}

class HostParam extends SimpleParam {
  const HostParam() : super(type: ParameterType.host);
}

class Session extends SimpleParam {
  const Session() : super(type: ParameterType.session);
}

class Header extends SimpleParam {
  const Header([String? key]) : super(type: ParameterType.header, key: key);
}

class FileParam extends ComplexParam {
  const FileParam({super.key, super.validators, super.transforms})
    : super(type: ParameterType.file);
}

class CookieHandler extends SimpleParam {
  const CookieHandler() : super(type: ParameterType.cookie);
}
