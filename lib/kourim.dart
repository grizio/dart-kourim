library kourim;

import 'package:di/di.dart';
import 'src/storage/interface/kourim.storage.interface.dart';
import 'src/storage/lib/kourim.storage.lib.dart';
import 'src/core/kourim.core.lib.dart';

export 'src/storage/interface/kourim.storage.interface.dart'
show IModelStorage, IDatabase;

export 'src/core/kourim.core.lib.dart'
show Table, FullCachedTable, PartialCachedTable, Field,
     Query, GetQuery, PostQuery, PutQuery, DeleteQuery, LocalQuery,
     ApplicationRemoteHost;

class _KourimModule extends Module {
  KourimModule() {
    // public
    bind(IModelStorage, toInstanceOf: ApplicationDatabase, withAnnotation: const IndexedDb());
    bind(IModelStorage, toInstanceOf: LocalStorage, withAnnotation: const Local());
    bind(IModelStorage, toInstanceOf: SessionStorage, withAnnotation: const Session());

    // private
    bind(InternalDatabase, toInstanceOf: InternalDatabase);
    bind(InternalLocalStorage, toInstanceOf: InternalLocalStorage);
    bind(InternalSessionStorage, toInstanceOf: InternalSessionStorage);
    bind(IRequestCreation, toValue: requestCreation);
  }
}

var kourimModule = new _KourimModule();
const Local localStorage = const Local();
const Session sessionStorage = const Session();
const IndexedDb indexedDb = const IndexedDb();
const Internal internal = const Internal();