part of kourim.query;

/// This interface describes classes which provide methods to manage entities.
abstract class IEntityManager {
  /// Creates a new [QueryBuilder] parametrized in terms of given [modelName] and [queryName].
  Future<IQueryBuilder> createQuery(String modelName, String queryName);
}

/// This class is the default implementation of [IEntityManager] and is used in production mode.
class EntityManager extends IEntityManager {
  @override
  Future<IQueryBuilder> createQuery(String modelName, String queryName) {
    var modelDescription = factory.modelDescription;
    Option<Model> model = modelDescription.findByName(modelName);
    if (model.isDefined) {
      Option<Query> query = model.get().getQuery(queryName);
      if (query.isDefined) {
        var queryBuilder = new QueryBuilder(query.get(), this);
        return new Future.value(queryBuilder);
      } else {
        throw new Exception('Query ' + modelName + '.' + queryName + ' is not defined');
      }
    } else {
      throw new Exception('Model ' + modelName + ' is not defined');
    }
  }
}