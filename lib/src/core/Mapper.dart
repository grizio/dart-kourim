part of kourim.core;

/// This interface describes classes providing some methods to transform an object into a map or a list of maps (convertible from and to json) in terms of a model.
/// It provide also methods to perform the inverse operation.
abstract class IMapper {
  /// Transforms a map or a list of maps into an object or a list of objects according to the given [model].
  dynamic toObject(Model model, dynamic values);

  /// Transforms an object or a list of objects into a map or a list of maps according to the given [model].
  dynamic toJson(Model model, dynamic values);

  /// Transforms a single map into a single object according the given [model].
  Object toObjectOne(Model model, Map<String, Object> values);

  /// Transforms a single object into a single map according the given [model].
  Map<String, Object> toJsonOne(Model model, Object object, [List<String> keepFields]);
}

/// Default implementation of the interface [IMapper] used by the system in production mode.
class Mapper extends IMapper {
  @override
  dynamic toObject(Model model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toObjectOne(model, _)).toList();
    } else {
      return toObjectOne(model, values);
    }
  }

  @override
  dynamic toJson(Model model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toJsonOne(model, _));
    } else {
      return toJsonOne(model, values);
    }
  }

  @override
  Object toObjectOne(Model model, Map<String, Object> values) {
    InstanceMirror instanceMirror = model.classMirror.newInstance(new Symbol(''), []);
    if (values is Map) {
      model.columns.values.forEach((column) {
        if (values.containsKey(column.name)) {
          instanceMirror.setField(column.variableMirror.simpleName, values[column.name]);
        }
      });
    } else {
      // values is primitive
      for (var column in model.columns.values) {
        if (column.key) {
          instanceMirror.setField(column.variableMirror.simpleName, values);
          break;
        }
      };
    }
    return instanceMirror.reflectee;
  }

  @override
  Map<String, Object> toJsonOne(Model model, Object object, [List<String> keepFields]) {
    var result = <String, Object>{};
    InstanceMirror instanceMirror = reflect(object);
    model.columns.values.forEach((column){
      if (keepFields == null || keepFields.length == 0 || keepFields.contains(column.key)) {
        var valueMirror = instanceMirror.getField(column.variableMirror.simpleName);
        if (valueMirror.hasReflectee && valueMirror.reflectee != null) {
          result[column.name] = valueMirror.reflectee;
        }
      }
    });
    return result;
  }
}