part of kourim.core.lib;

/// Prepares the Kourim system to be usable by the developer.
Future prepare() {
  var modelValidation = factory.modelValidation;
  return factory.database.open().then((_){
    return factory.internalDatabase.open().then((_){
      var mirrors = currentMirrorSystem();
      var libraryMirrors = mirrors.libraries.values;
      libraryMirrors.forEach((_) {
        _.declarations.values.forEach((DeclarationMirror declaration) {
          if (declaration is ClassMirror) {
            processClass(declaration);
          }
        });
      });
      if (!modelValidation.validate(factory.modelDescription)) {
        throw new KourimException(modelValidation.errors);
      }
    });
  });
}

/// Extracts metadata from given class mirror and save the result into [ModelDescription] if needed.
void processClass(ClassMirror classMirror) {
  if (isModel(classMirror)) {
    Model model = new Model();
    model.classMirror = classMirror;
    classMirror.metadata.forEach((metadata){
      processModelMetadata(metadata, model);
    });
    classMirror.declarations.values.forEach((declaration) {
      if (declaration is VariableMirror && isColumn(declaration)) {
        processColumn(declaration, model);
      }
    });
    factory.modelDescription.add(model);
  }
}

/// From an [metadata] on a classMirror, extracts data to populate the given [model].
void processModelMetadata(InstanceMirror metadata, Model model) {
  if (metadata.hasReflectee) {
    if (metadata.reflectee is annotation.model) {
      var modelReflectee = metadata.reflectee as annotation.model;
      model.name = modelReflectee.name;
      model.storage = new Option(modelReflectee.storage);
      model.strategy = new Option(modelReflectee.strategy);
      model.limit = new Option(modelReflectee.limit);
    } else if (metadata.reflectee is annotation.query) {
      var queryReflectee = metadata.reflectee as annotation.query;
      var query = new Query();
      query.name = queryReflectee.name;
      query.remote = new Option(queryReflectee.remote);
      query.then = new Option(queryReflectee.then);
      query.type = stringUtilities.nvl(queryReflectee.type, constants.get);
      query.authentication = booleanUtilities.nvl(queryReflectee.authentication, false);
      query.strategy = queryReflectee.strategy;
      query.limit = new Option(queryReflectee.limit);
      query.storage = new Option(queryReflectee.storage);
      model.addQuery(query);
    }
  }
}

/// Processes a field which was defined as a column to extract its description from annotations.
void processColumn(VariableMirror columnMirror, Model model) {
  Column column = new Column();
  // We need to know the column name as soon as possible
  column.name = getColumnName(columnMirror);
  column.key = false;
  column.unique = false;
  column.variableMirror = columnMirror;
  columnMirror.metadata.forEach((metadata){
    if (metadata.hasReflectee) {
      if (metadata.reflectee is annotation.column) {
        var columnReflectee = metadata.reflectee as annotation.column;
        // name: already done with getColumnName
        if (columnReflectee.type == null) {
          column.type = columnMirror.type.reflectedType.toString();
        } else {
          column.type = columnReflectee.type;
        }
      } else if (metadata.reflectee is annotation.key) {
        column.key = true;
      } else if (metadata.reflectee is annotation.unique) {
        column.unique = true;
      } else if (metadata.reflectee is annotation.onQuery) {
        var onQueryReflectee = metadata.reflectee as annotation.onQuery;
        // Could we throw an exception or log an error if the query does not exist ?
        model.getQuery(onQueryReflectee.queryName).forEach((Query query) => query.fields.add(column.name));
      }
    }
  });
  model.addColumn(column);
}

/// Is the [classMirror] a model?
bool isModel(ClassMirror classMirror) {
  for (var metadata in classMirror.metadata) {
    if (metadata.hasReflectee && metadata.reflectee is annotation.model) {
      return true;
    }
  }
  return false;
}

/// Is the [variableMirror] a column?
bool isColumn(VariableMirror variableMirror) {
  for (var metadata in variableMirror.metadata) {
    if (metadata.hasReflectee && metadata.reflectee is annotation.column) {
      return true;
    }
  }
  return false;
}

/// Extracts the column name from the [variableMirror] in terms of [column] annotation or variable name.
String getColumnName(VariableMirror variableMirror) {
  for (var metadata in variableMirror.metadata) {
    if (metadata.hasReflectee && metadata.reflectee is annotation.column) {
      var columnMetadata = metadata.reflectee as annotation.column;
      if (columnMetadata.name != null) {
        return columnMetadata.name;
      }
    }
  }
  return MirrorSystem.getName(variableMirror.simpleName);
}