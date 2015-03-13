part of kourim.core.lib;

/// Default implementation of the interface [IMapper] used by the system in production mode.
class Mapper extends IMapper {
  @override
  dynamic toObject(IModel model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toObjectOne(model, _)).toList();
    } else {
      return toObjectOne(model, values);
    }
  }

  @override
  dynamic toJson(IModel model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toJsonOne(model, _));
    } else {
      return toJsonOne(model, values);
    }
  }

  @override
  Object toObjectOne(IModel model, Map<String, Object> values) {
    InstanceMirror instanceMirror = model.classMirror.newInstance(new Symbol(''), []);
    if (values is Map) {
      model.columnNames.forEach((columnName) {
        var column = model.getColumn(columnName).get();
        if (values.containsKey(column.name)) {
          instanceMirror.setField(column.variableMirror.simpleName, values[column.name]);
        }
      });
    } else {
      // values is primitive
      for (var columnName in model.columnNames) {
        var column = model.getColumn(columnName).get();
        if (column.key) {
          instanceMirror.setField(column.variableMirror.simpleName, values);
          break;
        }
      };
    }
    return instanceMirror.reflectee;
  }

  @override
  Map<String, Object> toJsonOne(IModel model, Object object, [List<String> keepFields]) {
    var result = <String, Object>{};
    InstanceMirror instanceMirror = reflect(object);
    model.columnNames.forEach((columnName){
      var column = model.getColumn(columnName).get();
      if (keepFields == null || keepFields.length == 0 || keepFields.contains(column.name)) {
        var valueMirror = instanceMirror.getField(column.variableMirror.simpleName);
        if (valueMirror.hasReflectee && valueMirror.reflectee != null) {
          result[column.name] = valueMirror.reflectee;
        }
      }
    });
    return result;
  }
}