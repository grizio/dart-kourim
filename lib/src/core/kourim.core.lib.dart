library kourim.core;

import 'dart:async';
import 'package:klang/klang.dart';
import '../storage/interface/kourim.storage.interface.dart';
import '../storage/lib/kourim.storage.lib.dart';
import 'package:di/di.dart';
import 'dart:convert';
import 'package:klang/utilities/map.dart' as mapUtilities;
import 'dart:math';
import 'package:logging/logging.dart';
import 'dart:html';

part 'Constraint.dart';
part 'Field.dart';
part 'Query.dart';
part 'Request.dart';
part 'Table.dart';

/// Method to create a request.
typedef IRequest IRequestCreation();

IRequest requestCreation() {
  return new Request();
}

@Injectable()
class ApplicationRemoteHost {
  final String host;
  ApplicationRemoteHost(this.host);
}