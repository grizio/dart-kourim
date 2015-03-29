part of kourim.query.interface;

/// This interface describes classes which provide methods to manage entities.
abstract class IEntityManager {
  /// Creates a new [QueryBuilder] parametrized in terms of given [modelName] and [queryName].
  Future<IQueryBuilder> createQuery(String modelName, String queryName);
}