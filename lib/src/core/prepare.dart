part of kourim.core;

Future prepare() {
  return getAppDatabase().open().then((_){
    return getDatabase(root.InternalConstants.database).open().then((_){
      var mirrors = currentMirrorSystem();
      var libraryMirrors = mirrors.libraries.values;
      libraryMirrors.forEach((_) {
        _.declarations.values.forEach((DeclarationMirror declaration) {
          if (declaration is ClassMirror) {
            processClass(declaration);
          }
        });
      });
    });
  });
}

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
    getModelDescription().add(model);
  }
}

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
      query.type = stringUtilities.nvl(queryReflectee.type, root.Constants.get);
      query.authentication = booleanUtilities.nvl(queryReflectee.authentication, false);
      query.criteria = new Option(queryReflectee.criteria);
      query.strategy = queryReflectee.strategy;
      query.limit = new Option(queryReflectee.limit);
      query.storage = new Option(queryReflectee.storage);
      model.addQuery(query);
    }
  }
}

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
        // Already done with getColumnName
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

bool isModel(ClassMirror classMirror) {
  for (var metadata in classMirror.metadata) {
    if (metadata.hasReflectee && metadata.reflectee is annotation.model) {
      return true;
    }
  }
  return false;
}

bool isColumn(VariableMirror variableMirror) {
  for (var metadata in variableMirror.metadata) {
    if (metadata.hasReflectee && metadata.reflectee is annotation.column) {
      return true;
    }
  }
  return false;
}

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