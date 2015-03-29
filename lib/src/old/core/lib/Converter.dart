part of kourim.core.lib;

class ConverterStore implements IConverterStore {
  static final Logger log = new Logger('kourim.core.ConverterStore');

  Map<String, IConverter> converterMap = {
      // Default converters
      constants.boolType: new BoolConverter(),
      constants.datetimeType: new DateTimeConverter(),
      constants.doubleType: new DoubleConverter(),
      constants.intType: new IntConverter(),
      constants.optionType: new OptionConverter(),
      constants.stringType: new StringConverter()
  };

  @override
  void add(String name, IConverter converter) {
    log.warning('The converter ' + name + ' already exist. The previous one was removed.');
    converterMap[name] = converter;
  }

  @override
  IConverter operator [](String name) {
    return converterMap[name];
  }
}

/// Converter for `string`
class StringConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    return value;
  }

  @override
  dynamic typeToJson(dynamic value) {
    return value;
  }
}

/// Converter for `number`
class DoubleConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    if (value is num) {
      return (value as num).toDouble();
    } else {
      return double.parse(value);
    }
  }

  @override
  dynamic typeToJson(dynamic value) {
    // Double values are already accepted JSON type
    return value;
  }
}

/// Converter for `number`
class IntConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    if (value is int) {
      return value;
    } else {
      return double.parse(value);
    }
  }

  @override
  dynamic typeToJson(dynamic value) {
    // Int values are already accepted JSON type
    return value;
  }
}

/// Converter for [Datetime]
class DateTimeConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    if (value != null) {
      return DateTime.parse(value);
    } else {
      return null;
    }
  }

  @override
  dynamic typeToJson(dynamic value) {
    if (value != null && value is DateTime) {
      return value.toIso8601String();
    } else {
      return null;
    }
  }
}

/// Converter for `bool`
class BoolConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    if (value != null && value is bool) {
      return ['1', 't', 'true'].contains(value);
    } else {
      return null;
    }
  }

  @override
  dynamic typeToJson(dynamic value) {
    if (value != null) {
      return value ? 'true' : 'false';
    } else {
      return null;
    }
  }
}

/// Converter for [Option]
class OptionConverter implements IConverter {
  @override
  dynamic jsonToType(dynamic value) {
    return new Option(value);
  }

  @override
  dynamic typeToJson(dynamic value) {
    if (value != null && value is Option) {
      return (value as Option).get();
    } else {
      return null;
    }
  }
}