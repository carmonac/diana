import 'package:diana/diana.dart';

@ContentTypeSerializer(['application/x-www-form-urlencoded'])
class FormUrlEncondeContentType extends ContentType with Deserializable {
  FormUrlEncondeContentType(super.contentTypes);

  @override
  Future deserialize(DianaRequest request, Type type) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse form-urlencoded data
      final formData = Uri.splitQueryString(bodyString);
      if (DtoRegistry.isRegistered(type)) {
        return DtoRegistry.deserializeByType(formData, type);
      } else if (type == String) {
        return formData.toString();
      } else if (type == int) {
        return int.tryParse(formData['value'] ?? '') ?? 0;
      } else if (type == double) {
        return double.tryParse(formData['value'] ?? '') ?? 0.0;
      } else if (type == bool) {
        return formData['value']?.toLowerCase() == 'true';
      }

      return formData;
    } catch (e) {
      throw BadRequestException('Invalid form-urlencoded body: $e');
    }
  }
}
