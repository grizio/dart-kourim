library kourim;

import 'package:di/di.dart';
import 'src/storage/interface/kourim.storage.interface.dart';
import 'src/storage/lib/kourim.storage.lib.dart';
import 'src/description/kourim.description.lib.dart';
import 'dart:html';

void injectDependencies(Module module) {
  module.bind(IDatabase, toInstanceOf: DatabaseModelStorage, inject: [DatabaseApplicationName]);
  module.bind(IDatabase, toFactory: () => new DatabaseModelStorage('_kourim'), withAnnotation: const internal());
  module.bind(IModelStorage, toFactory: () => new MappedModelStorage(window.localStorage), withAnnotation: const local());
  module.bind(IModelStorage, toFactory: () => new MappedModelStorage(window.sessionStorage), withAnnotation: const session());
  module.bind(IRequestCreation, toValue: requestCreation);
}