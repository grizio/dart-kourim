part of kourim.storage.interface;

/// This interface describes classes from which we can get or remove data.
/// All functions will return [Future] to permit asynchronous operations.
abstract class ITableStorage {
  /// The name of the table storage.
  String get name;

  /// Finds on element in terms of given [key].
  /// If the element does not exist, returns [None]
  Future<Option<Map<String, Object>>> find(Object key);

  /// Returns the whole list of elements existing in this table storage.
  Future<Iterable<Map<String, Object>>> findAll();

  /// Returns the first element corresponding of given [parameters].
  /// It is useful when using a unique key as parameter.
  Future<Option<Map<String, Object>>> findOneBy(Map<String, Object> parameters);

  /// Returns all elements corresponding of given [parameters].
  Future<Iterable<Map<String, Object>>> findManyBy(Map<String, Object> parameters);

  /// Returns the first element matching the given [constraint].
  Future<Option<Map<String, Object>>> findOneWhen(Constraint constraint);

  /// Returns all elements matching the given [constraint].
  Future<Iterable<Map<String, Object>>> findManyWhen(Constraint constraint);

  /// Returns the first element corresponding of both [parameters] and [constraint].
  Future<Option<Map<String, Object>>> findOneFor(Map<String, Object> parameters, Constraint constraint);

  /// Return all elements corresponding of both [parameters] and [constraint].
  Future<Iterable<Map<String, Object>>> findManyFor(Map<String, Object> parameters, Constraint constraint);

  /// Puts the given [value] with the given [key].
  Future putOne(Object key, Map<String, Object> value);

  /// Puts all [values] by associating each value with its key.
  Future putMany(Map<Object, Map<String, Object>> values);

  /// Executes a process for each element in this table storage.
  Future foreach(ForeachValues process);

  /// Executes a process for each element in this table storage and returns the list of results produced.
  Future<Iterable<Object>> map(MapValues process);

  /// Removes the element with given [key].
  Future remove(Object key);

  /// Removes all elements matching given [parameters].
  Future removeBy(Map<String, Object> parameters);

  /// Removes all elements matching the given [constraint].
  Future removeWhen(Constraint constraint);

  /// Removes all elements in this table storage.
  Future clean();
}