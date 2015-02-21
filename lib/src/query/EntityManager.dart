part of kourim.query;

class EntityManager {
  Future<QueryBuilder> createQuery(String modelName, String queryName) {
    var modelDescription = getModelDescription();
    Option<Model> model = modelDescription.findByName(modelName);
    if (model.isDefined()) {
      Option<Query> query = model.get().getQuery(queryName);
      if (query.isDefined()) {
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