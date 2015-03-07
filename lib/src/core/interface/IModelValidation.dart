part of kourim.core.interface;

/// This interface describes classes which provide a mean to validate a system using kourim.
/// Validating initially the system could avoid further errors which could not be seen immediately.
abstract class IModelValidation {
  /// Validates if a model is conform with the specification.
  bool validate(IModelDescription modelDescription);
}