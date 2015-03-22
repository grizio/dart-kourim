part of kourim.query.interface;

/// Defines a query builder which can be parametrized and be executed to fetch data from remote server or local storage.
abstract class IQueryBuilder {
  /// Adds a parameter to the query
  void addParameter(String name, Object value);

  /// Adds a parameter if the remote query has one and only one parameter.
  /// In the other case throws an exception.
  void addKeyParameter(Object value);

  /// Adds a list of parameters to the query.
  void addParameters(Map<String, Object> values);

  /// Adds parameters from an entity for current query.
  /// This method will add only fields defined in model configuration by [onQuery].
  void addInputEntity(Object object);

  /// Joins entities with the query.
  /// The developer must use the name of [join] annotation.
  /// To chain several joins (from entity A to entity B then C),
  /// the given [name] should be the composite of join names separated by "`.`" (example: `"b.c"`).
  void join(String name);

  /// Gets the constraint that all results in the query must conform to be returned to the user.
  Option<Constraint> get constraint;

  /// Sets the constraint that all results in the query must conform to be returned to the user.
  void setConstraint(Constraint constraint);

  /// Executes the query and return its result.
  /// The resulting data depends on query and model strategies defined with [kourim.annotations].
  Future<dynamic> execute();

  /// Removes local data in terms of given configured query.
  /// It is useful when there is a need to refresh manually a query.
  ///
  /// This method do not make any request to server.
  Future clean();
}