library kourim.core;

import 'dart:async';
import 'dart:mirrors';
import 'package:klang/klang.dart';
import 'package:klang/utilities/boolean.dart' as booleanUtilities;
import 'package:klang/utilities/string.dart' as stringUtilities;
import '../annotation/kourim.annotation.lib.dart' as annotation;
import '../kourim.root.lib.dart' as root;
import '../storage/kourim.storage.lib.dart';

part 'Mapper.dart';
part 'ModelDescription.dart';
part 'ModelValidation.dart';
part 'prepare.dart';

ModelDescription _modelDescription;
ModelDescription getModelDescription() {
  if (_modelDescription == null) {
    _modelDescription = new ModelDescription();
  }
  return _modelDescription;
}

Mapper _mapper;
Mapper getMapper() {
  if (_mapper == null) {
    _mapper = new Mapper();
  }
  return _mapper;
}