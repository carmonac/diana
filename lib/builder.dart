import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:diana/diana.dart';
import 'dart:async';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;

Builder dianaBuilder(BuilderOptions options) {
  return _DianaAppBuilder();
}

class _DianaAppBuilder extends Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    // Buscar todos los controladores en el proyecto
    final controllerFiles = await buildStep
        .findAssets(Glob('lib/**.dart'))
        .toList();

    final routerBuffer = StringBuffer();
    final importsBuffer = StringBuffer();
    int controllerCount = 0;

    importsBuffer.writeln("import 'package:shelf_router/shelf_router.dart';");
    importsBuffer.writeln("import 'package:shelf/shelf.dart';");
    importsBuffer.writeln();

    for (final file in controllerFiles) {
      final library = await buildStep.resolver.libraryFor(file);
      final controllers = _findControllers(library);

      for (final controller in controllers) {
        controllerCount++;
        final className = controller.name;
        final importPath = p.relative(file.path, from: p.dirname('lib/src'));

        importsBuffer.writeln("import '../$importPath';");

        routerBuffer.writeln('''
  // Routes for $className
  void _register${className}Routes(Router router) {
    final controller = $className();
''');

        for (final method in controller.methods) {
          final getAnnotation = _getAnnotation(method, Get);
          if (getAnnotation == null) continue;

          final path = getAnnotation.peek('path')?.stringValue ?? '';
          final methodName = method.name;
          final returnsFuture = method.returnType.isDartAsyncFuture;

          routerBuffer.writeln('''
    router.get('$path', (request) async {
      ${returnsFuture ? 'final response = await' : 'final response ='} controller.$methodName();
      return Response.ok(response);
    });
''');
        }

        routerBuffer.writeln('  }\n');
      }
    }

    if (controllerCount == 0) {
      // No generar código si no hay controladores
      return;
    }

    final classBuffer = StringBuffer()
      ..writeln("// GENERATED CODE - DO NOT MODIFY BY HAND")
      ..writeln()
      ..write(importsBuffer.toString())
      ..writeln()
      ..writeln('class DianaAppImpl {')
      ..writeln('  final Router _router = Router();')
      ..writeln()
      ..writeln('  DianaAppImpl() {')
      ..writeln('    _registerRoutes();')
      ..writeln('  }')
      ..writeln()
      ..writeln('  void _registerRoutes() {');

    for (final file in controllerFiles) {
      final library = await buildStep.resolver.libraryFor(file);
      final controllers = _findControllers(library);

      for (final controller in controllers) {
        final className = controller.name;
        classBuffer.writeln('    _register${className}Routes(_router);');
      }
    }

    classBuffer
      ..writeln('  }')
      ..writeln()
      ..writeln('  Handler get handler => _router;')
      ..writeln('}')
      ..write(routerBuffer.toString());

    // Escribir el archivo generado
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/generated/diana_app.g.dart'),
      classBuffer.toString(),
    );
  }

  List<ClassElement> _findControllers(LibraryElement library) {
    return library.topLevelElements.whereType<ClassElement>().where((clazz) {
      return clazz.metadata.any((annotation) {
        final reader = ConstantReader(annotation.computeConstantValue());
        return reader.instanceOf(TypeChecker.fromRuntime(Controller));
      });
    }).toList();
  }

  ConstantReader? _getAnnotation(MethodElement method, Type annotationType) {
    for (final annotation in method.metadata) {
      final reader = ConstantReader(annotation.computeConstantValue());
      if (reader.instanceOf(TypeChecker.fromRuntime(annotationType))) {
        return reader;
      }
    }
    return null;
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['generated/diana_app.g.dart'],
  };
}
