import 'package:csv/csv.dart';
import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class CsvParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse CSV data
      const csvConverter = CsvToListConverter();
      final List<List<dynamic>> csvData = csvConverter.convert(bodyString);

      if (csvData.isEmpty) {
        return [];
      }

      // Check if first row contains headers
      final hasHeaders = _isLikelyHeaderRow(csvData.first);

      if (hasHeaders && csvData.length > 1) {
        // Convert to list of maps using first row as keys
        final headers = csvData.first
            .map((header) => header.toString())
            .toList();
        final List<Map<String, dynamic>> result = [];

        for (int i = 1; i < csvData.length; i++) {
          final Map<String, dynamic> row = {};
          for (int j = 0; j < headers.length && j < csvData[i].length; j++) {
            row[headers[j]] = csvData[i][j];
          }
          result.add(row);
        }

        if (param.typeOf != null) {
          // If expecting a specific type, try to deserialize each row
          return result
              .map((row) => deserializeToType(row, param.typeOf!))
              .toList();
        }

        return result;
      } else {
        // Return raw CSV data as list of lists
        if (param.typeOf != null && csvData.length == 1) {
          // If single row and specific type expected, try to deserialize
          final Map<String, dynamic> singleRowMap = {};
          for (int i = 0; i < csvData.first.length; i++) {
            singleRowMap['value$i'] = csvData.first[i];
          }
          return deserializeToType(singleRowMap, param.typeOf!);
        }

        return csvData;
      }
    } catch (e) {
      throw BadRequestException('Invalid CSV body: $e');
    }
  }

  /// Determines if a CSV row is likely to contain headers
  static bool _isLikelyHeaderRow(List<dynamic> row) {
    // Simple heuristic: if all values are strings and contain no numbers-only values
    return row.every((cell) {
      final cellStr = cell.toString().trim();
      return cellStr.isNotEmpty && !RegExp(r'^\d+(\.\d+)?$').hasMatch(cellStr);
    });
  }
}
