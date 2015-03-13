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

  /// Return the list of all query names.
  Iterable<String> get queryNames;

  /// List of column names for the model.
  Iterable<String> get columnNames;

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

  /// Returns an optional query from this model in terms of its key.
  Option<IQuery> getQuery(String name);

  /// Returns an optional column from this model in terms of its name.
  Option<IColumn> getColumn(String name);

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
  Option<String> type;

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