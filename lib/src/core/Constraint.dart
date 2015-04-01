part of kourim.core;

/// Describes a constraint to apply on a line
abstract class Constraint {
  /// The name of the field.
  String get key;

  /// Is this constraint is required?
  /// If `true`, then the developer must provide a value for this parameter, otherwise it will throw an exception.
  bool get isRequired;

  /// The validation function.
  /// [data] is a line from local storage describing a line.
  /// [value] is the value given to the query execution to use for application of the current constraint.
  bool validate(Map<String, Object> data, Object value);
}

/// Default class for Kourim constraint
abstract class DefaultConstraint implements Constraint {
  @override
  final String key;

  @override
  final bool isRequired;

  const DefaultConstraint(this.key, this.isRequired);
}

/// Constraint verifying if the given line possesses the exact value for the given key.
class ValueConstraint extends DefaultConstraint {
  const ValueConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    return data[key] == value;
  }
}

/// Constraint verifying if the given line does not possess the value for given key or it is different.
class NotValueConstraint extends ValueConstraint {
  const NotValueConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    return !super.validate(data, value);
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value contains the given value.
class LikeConstraint extends DefaultConstraint {
  const LikeConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    return data[key] != null && data[key].toString().contains(value.toString());
  }
}

/// Constraint verifying if the given line does not possess a value associated with the [key]
/// or this value does not contain the given value.
class UnlikeConstraint extends LikeConstraint {
  const UnlikeConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    return !super.validate(data, value);
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is lower than the given one.
class LowerConstraint extends DefaultConstraint {
  const LowerConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) < 0;
    } else {
      new Logger('LowerConstraint').warning('The given value is not a Comparable object, LowerConstraint.validate returns false by default');
      return false;
    }
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is upper than the given one.
class UpperConstraint extends DefaultConstraint {
  const UpperConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) > 0;
    } else {
      new Logger('UpperConstraint').warning('The given value is not a Comparable object, UpperConstraint.validate returns false by default');
      return false;
    }
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is equal than the given one.
/// Should be the same as [ValueConstraint], but this one use [Comparable] interface instead of [==] operator.
class EqualConstraint extends DefaultConstraint {
  const EqualConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) == 0;
    } else {
      new Logger('EqualConstraint').warning('The given value is not a Comparable object, EqualConstraint.validate returns false by default');
      return false;
    }
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is difference of the given one.
class DifferentConstraint extends DefaultConstraint {
  const DifferentConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) != 0;
    } else {
      new Logger('DifferentConstraint').warning('The given value is not a Comparable object, DifferentConstraint.validate returns false by default');
      return false;
    }
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is lower than or equals to the given one.
class LowerOrEqualConstraint extends DefaultConstraint {
  const LowerOrEqualConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) <= 0;
    } else {
      new Logger('LowerOrEqualConstraint').warning('The given value is not a Comparable object, LowerOrEqualConstraint.validate returns false by default');
      return false;
    }
  }
}

/// Constraint verifying if the given line possesses a value associated with the [key]
/// and this value is upper than or equals to the given one.
class UpperOrEqualConstraint extends DefaultConstraint {
  const UpperOrEqualConstraint(String key, bool isRequired): super(key, isRequired);

  @override
  bool validate(Map<String, Object> data, Object value) {
    if (data[key] == null) {
      return false;
    } else if (data[key] is Comparable) {
      return (data[key] as Comparable).compareTo(value) >= 0;
    } else {
      new Logger('UpperOrEqualConstraint').warning('The given value is not a Comparable object, UpperOrEqualConstraint.validate returns false by default');
      return false;
    }
  }
}