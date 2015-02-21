part of kourim.core;

class Mapper {
  static dynamic toObject(Model model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toObjectOne(model, _)).toList();
    } else {
      return toObjectOne(model, values);
    }
  }

  static dynamic toJson(Model model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toJsonOne(model, _));
    } else {
      return toJsonOne(model, values);
    }
  }

  static Object toObjectOne(Model model, Map<String, Object> values) {
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

  static Map<String, Object> toJsonOne(Model model, Object object, [List<String> keepFields]) {
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