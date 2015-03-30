library kourim.description;

import 'dart:async';
import 'package:klang/klang.dart';
import '../storage/interface/kourim.storage.interface.dart';
import 'package:di/di.dart';

part 'Field.dart';
part 'Query.dart';
part 'Request.dart';
part 'Table.dart';

/// Method to create a request.
typedef IRequest IRequestCreation();

IRequest requestCreation() {
  return new Request();
}