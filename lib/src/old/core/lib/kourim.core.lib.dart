/// This library provides functions which should not be used by an external user, but only by Kourim system.
library kourim.core.lib;

import 'dart:async';
import 'dart:mirrors';

import '../../../../../packages/klang/klang.dart';
import '../../../../../packages/klang/utilities/boolean.dart' as booleanUtilities;
import '../../../../../packages/klang/utilities/string.dart' as stringUtilities;
import '../../../../../packages/logging/logging.dart';

import '../../../../constants.dart' as constants;

import '../../factory.dart' as factory;
import '../../annotation' as annotation;
import '../interface/kourim.core.interface.dart';

part 'Converter.dart';
part 'KourimException.dart';
part 'Mapper.dart';
part 'ModelDescription.dart';
part 'ModelValidation.dart';
part 'prepare.dart';