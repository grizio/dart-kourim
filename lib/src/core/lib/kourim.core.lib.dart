/// This library provides functions which should not be used by an external user, but only by Kourim system.
library kourim.core.lib;

import 'dart:async';
import 'dart:mirrors';

import 'package:klang/klang.dart';
import 'package:klang/utilities/boolean.dart' as booleanUtilities;
import 'package:klang/utilities/string.dart' as stringUtilities;

import 'package:kourim/constants.dart' as constants;

import '../../factory.dart' as factory;
import '../../annotation/kourim.annotation.lib.dart' as annotation;
import '../interface/kourim.core.interface.dart';

part 'KourimException.dart';
part 'Mapper.dart';
part 'ModelDescription.dart';
part 'ModelValidation.dart';
part 'prepare.dart';