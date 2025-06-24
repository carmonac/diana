import 'dart:typed_data';

import 'package:protobuf/protobuf.dart';
import 'package:shelf/shelf.dart';

import '../../core/dto_registry.dart';
import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';

class ProtobufParser {
  /// Registry for protobuf message types
  static final Map<Type, GeneratedMessage Function()> _protobufRegistry = {};

  /// Registers a protobuf message type for automatic deserialization
  ///
  /// Example:
  /// ```dart
  /// BodyParser.registerProtobuf<UserMessage>(() => UserMessage());
  /// ```
  static void registerProtobuf<T extends GeneratedMessage>(
    T Function() factory,
  ) {
    _protobufRegistry[T] = factory;
  }

  /// Clears all registered protobuf types
  static void clearProtobufRegistry() {
    _protobufRegistry.clear();
  }

  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      // Read the binary data
      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      final uint8List = Uint8List.fromList(bodyBytes);

      if (uint8List.isEmpty) {
        return null;
      }

      // For protobuf, we need a specific type to deserialize
      if (param.typeOf == null) {
        // If no specific type is provided, return the raw bytes
        // This allows the application to handle the deserialization manually
        return uint8List;
      }

      // Check if the type is registered in DtoRegistry and is a protobuf message
      if (DtoRegistry.isRegistered(param.typeOf!)) {
        return _deserializeProtobuf(uint8List, param.typeOf!);
      }

      // Try to create an instance and check if it's a GeneratedMessage
      try {
        final instance = _createProtobufInstance(param.typeOf!);
        if (instance is GeneratedMessage) {
          // Clone the instance and merge from the bytes
          final message = instance.createEmptyInstance();
          message.mergeFromBuffer(uint8List);
          return message;
        }
      } catch (e) {
        // If it fails, fall back to returning raw bytes
      }

      // Fallback: return raw bytes for manual handling
      return uint8List;
    } catch (e) {
      throw BadRequestException('Invalid Protocol Buffers body: $e');
    }
  }

  /// Attempts to deserialize protobuf data using DtoRegistry
  static dynamic _deserializeProtobuf(Uint8List data, Type type) {
    // This would need to be implemented based on how DtoRegistry handles protobuf
    // For now, we'll try the direct approach
    try {
      final instance = _createProtobufInstance(type);
      if (instance is GeneratedMessage) {
        final message = instance.createEmptyInstance();
        message.mergeFromBuffer(data);
        return message;
      }
    } catch (e) {
      // If direct instantiation fails, check if DtoRegistry can handle it
      if (DtoRegistry.isRegistered(type)) {
        // This is a placeholder - DtoRegistry would need protobuf support
        // For now, return the raw data
        return data;
      }
    }
    return data;
  }

  /// Creates an instance of a protobuf message type
  static dynamic _createProtobufInstance(Type type) {
    // Check if the type is registered in our protobuf registry
    if (_protobufRegistry.containsKey(type)) {
      return _protobufRegistry[type]!();
    }

    // If not registered, throw an exception with helpful message
    throw UnsupportedError(
      'Protobuf message type $type must be registered using BodyParser.registerProtobuf(). '
      'Example: BodyParser.registerProtobuf<$type>(() => $type());',
    );
  }
}
