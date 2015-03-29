part of kourim.query.lib;

/// This class is the default implementation of [IEntityManager] and is used in production mode.
class EntityManager extends IEntityManager {
  static final Logger log = new Logger('kourim.query.EntityManager');

  @override
  Future<IQueryBuilder> createQuery(String modelName, String queryName) {
    log.info('createQuery(' + modelName + ',' + queryName + ')');
    var modelDescription = factory.modelDescription;
    Option<Model> model = modelDescription.findByName(modelName);
    if (model.isDefined) {
      Option<Query> query = model.get().getQuery(queryName);
      if (query.isDefined) {
        var queryBuilder = new QueryBuilder(query.get(), this);
        return new Future.value(queryBuilder);
      } else {
        log.severe('Query ' + modelName + '.' + queryName + ' is not defined');
        throw new Exception('Query ' + modelName + '.' + queryName + ' is not defined');
      }
    } else {
      log.severe('Model ' + modelName + ' is not defined');
      throw new Exception('Model ' + modelName + ' is not defined');
    }
  }
}