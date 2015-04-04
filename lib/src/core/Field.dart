part of kourim.core;

/// This class describes a Field from an object
class Field {
  /// The owner table
  final Table table;

  /// The name of the field, used in queries
  final String name;

  /// Is the field is the key of the table?
  final bool isKey;

  /// Is the field is unique in the table?
  final bool isUnique;

  /// Creates the field - see attributes for more explanations.
  const Field(this.table, this.name, this.isKey, this.isUnique);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field.
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get value => new ValueConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field.
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get valueOpt => new ValueConstraint(this, false);

  /// Constraint checking if a row does not contain a value (given when calling [Query.execute] function) for this field.
  /// The difference with [different] is this function returns [true] when the field value does not exist.
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get notValue => new NotValueConstraint(this, true);

  /// Constraint checking if a row does not contain a value (given when calling [Query.execute] function) for this field.
  /// The difference with [differentOpt] is this function returns [true] when the field value does not exist.
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get notValueOpt => new NotValueConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value contains the given one (as `LIKE '%...%'` in SQL).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get like => new LikeConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value contains the given one (as `LIKE '%...%'` in SQL).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get likeOpt => new LikeConstraint(this, false);

  /// Constraint checking if a row does not contain a value (given when calling [Query.execute] function) for this field
  /// or this value does not contain the given one (as `NOT LIKE '%...%'` in SQL).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get unlike => new UnlikeConstraint(this, true);

  /// Constraint checking if a row does not contain a value (given when calling [Query.execute] function) for this field
  /// or this value does not contain the given one (as `NOT LIKE '%...%'` in SQL).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get unlikeOpt => new UnlikeConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is lower than the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get lower => new LowerConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is lower than the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get lowerOpt => new LowerConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is upper than the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get upper => new UpperConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is upper than the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get upperOpt => new UpperConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is equal to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get equal => new EqualConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is equal to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get equalOpt => new EqualConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is different to the given one (uses of [Comparable] interface).
  /// Unlike [notValue], the row *must* contains a value for given field.
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get different => new DifferentConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is different to the given one (uses of [Comparable] interface).
  /// Unlike [notValue], the row *must* contains a value for given field.
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get differentOpt => new DifferentConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is lower than or equals to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get lowerOrEqual => new LowerOrEqualConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is lower than or equals to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get lowerOrEqualOpt => new LowerOrEqualConstraint(this, false);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is upper than or equals to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will require the given field to be provided.
  Constraint get upperOrEqual => new UpperOrEqualConstraint(this, true);

  /// Constraint checking if a row contains a value (given when calling [Query.execute] function) for this field
  /// and this value is upper than or equals to the given one (uses of [Comparable] interface).
  /// The [LocalQuery.execute] will not require the given field to be provided.
  Constraint get upperOrEqualOpt => new UpperOrEqualConstraint(this, false);
}