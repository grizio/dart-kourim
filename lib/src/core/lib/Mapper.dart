part of kourim.core.lib;

/// Default implementation of the interface [IMapper] used by the system in production mode.
class Mapper extends IMapper {
  @override
  dynamic toObject(IModel model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toObjectOne(model, _)).toList();
    } else if (values is Option) {
      return (values as Option).map((_) => toObjectOne(model, _));
    } else {
      return toObjectOne(model, values);
    }
  }

  @override
  dynamic toJson(IModel model, dynamic values) {
    if (values is List) {
      return (values as List).map((_) => toJsonOne(model, _));
    } else if (values is Option) {
      return (values as Option).map((_) => toJsonOne(model, _));
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
        var columnValue = values[column.name];
        if (column.isModelDescription) {
          var nestedModel = factory.modelDescription.findByName(column.type).get();
          value = toObject(nestedModel, columnValue);
        } else {
          var converter = converterStore[column.type];
          if (columnValue is List) {
            value = (columnValue as List).map(converter.jsonToType).toList();
          } else {
            value = converter.jsonToType(columnValue);
          }
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
            var converter = converterStore[column.type];
            if (valueMirror.reflectee is List) {
              value = (valueMirror.reflectee as List).map(converter.typeToJson).toList();
            } else {
              value = converter.typeToJson(valueMirror.reflectee);
            }
          }
          result[column.name] = value;
        }
      }
    });
    return result;
  }
}