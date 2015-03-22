part of kourim.core.interface;

/// This interface describes classes which can register and provide a list of model descriptions.
abstract class IModelDescription {
  /// Finds a [Model] in terms of its [name].
  Option<IModel> findByName(String name);

  /// Adds a model.
  void add(IModel model);

  /// Returns the list of all names of registered models.
  Iterable<String> get modelNames;
}

/// Describes a model according to [kourim.annotation] system.
abstract class IModel {
  /// Name of the model
  String name;

  /// The destination of the cache
  Option<String> storage;

  /// The strategy that should be apply
  Option<String> strategy;

  /// The limit of the cache
  Option<int> limit;

  /// The associated class mirror
  ClassMirror classMirror;

  /// Indicates if the model can be used only for nested types.
  bool isNestedOnly;

  /// Return the list of all query names.
  Iterable<String> get queryNames;

  /// List of column names for the model.
  Iterable<String> get columnNames;

  /// List of join names for the model.
  Iterable<String> get joinNames;

  /// Indicates if the model has a cache.
  bool get hasCache;

  /// Indicates if the model has mot a cache.
  bool get hasNotCache;

  /// Returns the column of the model key.
  IColumn get keyColumn;

  /// Adds a query into the model.
  void addQuery(IQuery query);

  /// Adds a column into the model.
  void addColumn(IColumn column);

  /// Adds a join into the model.
  void addJoin(IJoin join);

  /// Returns an optional query from this model in terms of its key.
  Option<IQuery> getQuery(String name);

  /// Returns an optional column from this model in terms of its name.
  Option<IColumn> getColumn(String name);

  /// Returns an optional join from this model in terms of its name.
  Option<IJoin> getJoin(String name);

  /// Creates a copy of this model.
  /// It will also create a copy of associated elements.
  IModel copy();
}

/// Describes a column according to [kourim.annotation] system.
abstract class IColumn {
  /// Associated model
  IModel model;

  /// Column name
  String name;

  /// Indicates if this column is a key
  bool key;

  /// Indicates if each value from this column is unique in given model.
  bool unique;

  /// The associated variable mirror
  VariableMirror variableMirror;

  /// The type of the column
  /// If [modelDescription] = `true`, it will refer to the model name to use, otherwise the simple converter.
  String type;

  /// Indicates if the [type] refers to a model description or a simple converter.
  bool isModelDescription;

  /// Returns the full name of the column (prefixed with the model name).
  String get fullName;

  /// Returns the value of the column from given source.
  Object getValue(Object source);

  /// Set the value of the column from given source.
  void setValue(Object source, Object value);

  /// Creates a copy of this column.
  /// The associated model will not be copied and this last will not contain the column.
  IColumn copy();
}

/// Describes a query according to [kourim.annotation] system.
abstract class IQuery {
  /// The associated model
  IModel model;

  /// The query name
  String name;

  /// The remote url.
  Option<String> remote;

  /// The next query name to call after executing this one.
  Option<String> then;

  /// The next query to call after executing this one.
  Option<IQuery> get thenQuery;

  /// The type of the remote call (HTTP method).
  String type;

  /// Indicates if the remote request needs an authentication to fetch data.
  bool authentication;

  /// The field list to include in remote request (when POST or PUT).
  List<String> fields;

  /// Indicates in which storage should wa save the result of the query.
  Option<String> storage;

  /// Indicates the time limit before the data is considered outdated.
  Option<int> limit;

  /// Indicates the strategy to apply on this query.
  String strategy;

  /// Returns the full name of the query (prefixed with the model name).
  String get fullName;

  /// Indicates if the model has a cache.
  bool get hasCache;

  /// Indicates if the model has not a cache.
  bool get hasNotCache;

  /// Creates a copy of this query.
  /// The associated model will not be copied and this last will not contain the query.
  IQuery copy();
}

abstract class IJoin {
  /// The associated model
  IModel model;

  /// The name of the join.
  String name;

  /// The attribute from current model used to create the join.
  String from;

  /// The targeted model to use when querying.
  String to;

  /// The query name to execute to fetch data of join.
  String by;

  /// The associated variable mirror
  VariableMirror variableMirror;

  /// Returns the value of the column join from given source.
  Object getValue(Object source);

  /// Set the value of the column join from given source.
  void setValue(Object source, Object value);

  /// Creates a copy of this join.
  /// The associated model will not be copied and this last will not contain the join.
  IJoin copy();
}