part of kourim.core.interface;

/// This interface describes classes providing some methods to transform an object into a map or a list of maps (convertible from and to json) in terms of a model.
/// It provide also methods to perform the inverse operation.
abstract class IMapper {
  /// Transforms a map or a list of maps into an object or a list of objects according to the given [model].
  dynamic toObject(IModel model, dynamic values);

  /// Transforms an object or a list of objects into a map or a list of maps according to the given [model].
  dynamic toJson(IModel model, dynamic values);

  /// Transforms a single map into a single object according the given [model].
  Object toObjectOne(IModel model, Map<String, Object> values);

  /// Transforms a single object into a single map according the given [model].
  Map<String, Object> toJsonOne(IModel model, Object object, [List<String> keepFields]);
}