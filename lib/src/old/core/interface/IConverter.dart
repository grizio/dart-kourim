part of kourim.core.interface;

typedef dynamic ConvertToType(dynamic value);
typedef dynamic ConvertToString(dynamic value);

/// This class permits to store converters used by Kourim system to map objects and JSON values.
abstract class IConverterStore {
  /// Adds a new converter to the store by providing the key name (used with annotations) and the associated [IConverter].
  void add(String name, IConverter converter);

  /// Gets the converter defined for given name.
  IConverter operator [](String name);
}

/// This class provides methods to convert a value from string to a type and the contrary.
abstract class IConverter {
  /// Transforms the given value into wanted type.
  dynamic jsonToType(dynamic value);

  /// Transform the given value into a JSON type (string or number).
  dynamic typeToJson(dynamic value);
}