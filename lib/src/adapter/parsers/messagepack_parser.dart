import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class MessagePackParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      // Read the binary data
      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      final uint8List = Uint8List.fromList(bodyBytes);

      if (uint8List.isEmpty) {
        return null;
      }

      // Decode MessagePack data using the msgpack_dart library
      final unpackedData = deserialize(uint8List);

      // If no specific type is requested, return the unpacked data as-is
      if (param.typeOf == null) {
        return unpackedData;
      }

      // If the unpacked data is a Map and we have a specific type, try to deserialize
      if (unpackedData is Map<String, dynamic>) {
        return deserializeToType(unpackedData, param.typeOf!);
      }

      // If unpacked data is a Map with dynamic keys, convert to Map<String, dynamic>
      if (unpackedData is Map) {
        final convertedMap = <String, dynamic>{};
        unpackedData.forEach((key, value) {
          convertedMap[key.toString()] = value;
        });
        return deserializeToType(convertedMap, param.typeOf!);
      }

      // If the unpacked data is a List and we expect a List type, try to deserialize each item
      if (unpackedData is List && param.typeOf != null) {
        return unpackedData.map((item) {
          if (item is Map<String, dynamic>) {
            return deserializeToType(item, param.typeOf!);
          } else if (item is Map) {
            // Convert Map to Map<String, dynamic>
            final convertedMap = <String, dynamic>{};
            item.forEach((key, value) {
              convertedMap[key.toString()] = value;
            });
            return deserializeToType(convertedMap, param.typeOf!);
          }
          return item;
        }).toList();
      }

      // Return the unpacked data if no specific deserialization is needed
      return unpackedData;
    } catch (e) {
      throw BadRequestException('Invalid MessagePack body: $e');
    }
  }
}
