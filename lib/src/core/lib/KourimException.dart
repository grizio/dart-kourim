part of kourim.core.lib;

///
class KourimException implements Exception {
  Iterable<String> errors;

  KourimException(this.errors);

  @override
  String toString() {
    return errors.fold('', (val, elt) => val + elt + '\n');
  }
}