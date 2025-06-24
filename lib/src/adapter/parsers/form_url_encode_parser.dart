import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class FormUrlEncodeParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse form-urlencoded data
      final formData = Uri.splitQueryString(bodyString);

      if (param.typeOf != null) {
        return deserializeToType(formData, param.typeOf!);
      }

      return formData;
    } catch (e) {
      throw BadRequestException('Invalid form-urlencoded body: $e');
    }
  }
}
