class TypeConverter {
  static T convertToType<T>(dynamic value) {
    if (value == null) return null as T;

    if (T == String) return value.toString() as T;
    if (T == int) return int.tryParse(value.toString()) as T;
    if (T == double) return double.tryParse(value.toString()) as T;
    if (T == bool) return (value.toString().toLowerCase() == 'true') as T;

    return value as T;
  }
}
