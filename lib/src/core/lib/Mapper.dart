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
    var converterStore = factory.converterStore;
    InstanceMirror instanceMirror = model.classMirror.newInstance(new Symbol(''), []);
    model.columnNames.forEach((columnName) {
      var column = model.getColumn(columnName).get();
      if (values.containsKey(column.name)) {
        var value;
        if (column.isModelDescription) {
          var nestedModel = factory.modelDescription.findByName(column.type).get();
          value = toObject(nestedModel, values[column.name]);
        } else {
          value = converterStore[column.type].jsonToType(values[column.name]);
        }
        instanceMirror.setField(column.variableMirror.simpleName, value);
      }
    });
    return instanceMirror.reflectee;
  }

  @override
  Map<String, Object> toJsonOne(IModel model, Object object, [List<String> keepFields]) {
    var converterStore = factory.converterStore;
    var result = <String, Object>{};
    InstanceMirror instanceMirror = reflect(object);
    model.columnNames.forEach((columnName){
      var column = model.getColumn(columnName).get();
      if (keepFields == null || keepFields.length == 0 || keepFields.contains(column.name)) {
        var valueMirror = instanceMirror.getField(column.variableMirror.simpleName);
        if (valueMirror.hasReflectee && valueMirror.reflectee != null) {
          var value;
          if (column.isModelDescription) {
            var nestedModel = factory.modelDescription.findByName(column.type).get();
            value = toJson(nestedModel, valueMirror.reflectee);
          } else {
            var value = converterStore[column.type].typeToJson(valueMirror.reflectee);
          }
          result[column.name] = value;
        }
      }
    });
    return result;
  }
}