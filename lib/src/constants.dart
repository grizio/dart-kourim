part of kourim.root;

class Constants {
  static const indexedDB = 'indexeddb';
  static const localStorage = 'localstorage';
  static const sessionStorage = 'sessionstorage';

  static const findAll = 'findall';
  static const find = 'find';

  static const row = 'row';
  static const rows = 'rows';
  static const column = 'column';
  static const table = 'table';
  static const none = 'none';

  static const get = 'get';
  static const post = 'post';
  static const put = 'put';
  static const delete = 'delete';

  static const custom = 'custom';
}

class InternalConstants {
  static const database = '_kourim';
  static const queryCacheTable = 'queryCache';
  static const prefixStorage = '_kourim_';
  static const readonly = 'readonly';
  static const readwrite = 'readwrite';
}