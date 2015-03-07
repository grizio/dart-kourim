part of kourim.query.interface;

/// This interface describes classes which implement methods about queries.
abstract class IQueryHelper {
  String getUri(Query query, Map<String, Object> parameters);

  /// Checks if the cache for the query is expired.
  ///
  /// If the query has no cache configuration nor any cached value, return `true`.
  Future<bool> isQueryCacheExpired(Query query, Map<String, Object> parameters);

  /// Checks if the cache for the model is expired.
  ///
  /// If the model has no cache configuration nor any cached value, return `true`.
  Future<bool> isModelCacheExpired(Model model, [Object key]);

  /// The the key used for the current query in terms of parameters.
  String getQueryCacheKey(Query query, Map<String, Object> parameters);

  /// The the key used for the current model in terms of parameters.
  String getModelCacheKey(Model model, Map<String, Object> parameters);

  /// Removes data in terms of given [query] and [parameters].
  Future clean(Query query, Map<String, Object> parameters);

  /// Returns parameters which should be inserted into a body [HttpRequest].
  /// It actually remove parameters which were already set in query url.
  Map<String, Object> getBodyParameters(Query query, Map<String, Object> parameters);

  /// Pulls data in terms of given query.
  Future<dynamic> pull(Query query, Map<String, Object> parameters, storage.ITableStorage tableStorage, [storage.ITableStorage otherTableStorage]);

  /// Checks if the query ends with the query named [constants.find].
  bool endByFindQuery(Query query);

  /// Returns the storage in terms of its [storage] constant.
  storage.IModelStorage getStorage(Option<String> storage);

  /// Prepares a [query] with its [parameters] by pulling data if not already done.
  Future prepare(Query query, Map<String, Object> parameters);
}