library kourim;

import 'package:di/di.dart';
import 'src/storage/interface/kourim.storage.interface.dart';
import 'src/storage/lib/kourim.storage.lib.dart';
import 'src/core/kourim.core.lib.dart';

export 'src/storage/interface/kourim.storage.interface.dart'
show IModelStorage, IDatabase, DatabaseApplicationName, DatabaseChangeManager;

export 'src/core/kourim.core.lib.dart'
show Table, FullCachedTable, PartialCachedTable, Field,
     Query, GetQuery, PostQuery, PutQuery, DeleteQuery, LocalQuery,
     ApplicationRemoteHost, Constraint;

class KourimModule extends Module {
  KourimModule() {
    // prepare
    bind(ApplicationDatabase);
    bind(SessionStorage);
    bind(LocalStorage);
    bind(InternalDatabaseChangeManager);

    // public
    bind(IModelStorage, toInstanceOf: ApplicationDatabase, withAnnotation: indexedDb);
    bind(IModelStorage, toInstanceOf: LocalStorage, withAnnotation: localStorage);
    bind(IModelStorage, toInstanceOf: SessionStorage, withAnnotation: sessionStorage);

    // private
    bind(IRequestCreation, toValue: requestCreation);
    bind(DatabaseChangeManager, toInstanceOf: InternalDatabaseChangeManager, withAnnotation: internal);
  }
}

const Local localStorage = const Local();
const Session sessionStorage = const Session();
const IndexedDb indexedDb = const IndexedDb();
const Internal internal = const Internal();