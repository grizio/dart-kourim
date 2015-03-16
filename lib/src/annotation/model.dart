part of kourim.annotation;

/// The annotated class will be defined as a model usable by [kourim] system.
class model {
  /// The name of the model.
  /// By default, the name is the class name.
  final String name;

  /// If the class can be cached into a local storage, this variable is required and will indicates which storage will be used.
  /// See [kourim.constants.indexedDB], [kourim.constants.localstorage] and [kourim.constants.sessionstorage]
  final String storage;

  /// If the class can be cached into a local storage, this variable will indicates what is the strategy.
  ///
  /// When [kourim.constants.table], before a non-cached query (see [query] for more information),
  /// all data will be fetched by calling the query [kourim.constants.findAll].
  ///
  /// When [kourim.constants.row], if a query fetched a row with its key or a unique column, the row will be cached.
  final String strategy;

  /// If the class can be cached into a local storage, this variable will indicates how long (in seconds) the cache will last before refreshing data (if not done manually).
  ///
  /// If the limit is set to 0, then the system will not refreshed the data.
  /// A use case for this is data saved in session storage and not designed to be updated by another user.
  final int limit;

  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const model({this.name, this.storage, this.strategy, this.limit});
}

/// This annotation defines a query which can be performed on a model.
/// A query can be cached itself (see [storage] and [limit] for more information),
/// can use model cache (if set) or have no cache (if no query cache, nor model cache).
class query {
  /// Name of the query.
  /// This attribute is required.
  final String name;

  /// The URI pattern to fetch data on a distant server using HTTP protocol (AJAX).
  ///
  /// If this parameter is not provided, then the system will fetch data from model cache.
  /// If the model has no cache, the system will generate an error.
  ///
  /// Variable can be defined with ":parameter".
  ///
  ///     Example: "/user/:idd/:username"
  final String remote;

  /// This attribute permit the developer to execute another query depending on result of current query and returns the result of [then] query.
  ///
  /// For instance, This the query returns a list of integers representing the id of entities to get and then a query to get an entity in terms of its id.
  /// The query will get the id list, then for each id, it will get the entity by calling the [then] query.
  /// So, the returned data of this query will be the list of entities.
  final String then;

  /// The strategy explain to the system what should be the format of returned result.
  ///
  /// * If [kourim.constants.row], then the returned data must be a single object
  /// * If [kourim.constants.rows], then the returned data must be a list of objects
  /// * If [kourim.constants.column], then the returned data must be a single value or a list of values
  ///
  /// The last case is useful with [then] attribute.
  final String strategy;

  /// If the query hass to be cached, then this variable must be set to defined where to save data.
  /// See [kourim.constants.indexedDB], [kourim.constants.localstorage] and [kourim.constants.sessionstorage]
  final String storage;

  /// If the query is cached, then this attribute indicates the duration (in seconds) the query must be cached before it must be refreshed.
  ///
  /// If the limit is set to 0, then the system will not refreshed the data.
  /// A use case for this is data saved in session storage and not designed to be updated by another user.
  final int limit;

  /// This attribute indicates the type of remote query (if any).
  /// By default, it will be set to [kourim.constants.get].
  ///
  /// See [kourim.constants.get], [kourim.constants.post], [kourim.constants.put] and [kourim.constants.delete]
  final String type;

  /// **Not implemented yet**
  ///
  /// If true, then the system will set the HTTP authentication to the remote request.
  final bool authentication;

  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const query({this.name, this.remote:null, this.strategy, this.then:null, this.storage:null, this.type:'get', this.authentication:false, this.limit:0});
}

/// Describes a column in the model.
/// Only class variables with this annotation will be recognized in the current model.
class column {
  /// The name of the column.
  /// If not set, then the system will use the attribute name as column name.
  final String name;

  /// The type to convert the value of the column.
  /// The key must be defined in [IConverterStore]
  final String type;

  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const column({this.name:null, this.type:null});
}

/// If a column has this annotation, then it will be considered as a part of the key.
/// It is possible having several keys in a model but it is not advisable (particularly when using [kourim.constants.column] in queries).
class key {
  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const key();
}

/// Indicates that a column will be unique in the model.
/// It could optimize queries on local storages.
/// Currently not used.
class unique {
  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const unique();
}

/// When sending data to remote server with HTTP methods `POST` and `PUT`, the system can include some parameters in body content.
/// This annotation indicates a query which need to include related column.
/// A column can have several [onQuery].
class onQuery {
  /// The name of the query which include the column.
  final String queryName;

  /// Creates the annotation.
  /// See class variables for more information fo each parameter.
  const onQuery(this.queryName);
}