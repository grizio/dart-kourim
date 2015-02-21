part of kourim.annotation;

class model {
  final String name;
  final String storage;
  final String strategy;
  final int limit;

  const model({this.name, this.storage, this.strategy, this.limit});
}

class query {
  final String name;
  final String remote;
  final String then;
  final String strategy;
  final String storage;
  final int limit;
  final String type;
  final bool authentication;
  final dynamic criteria;

  const query({this.name, this.remote:null, this.strategy, this.then:null, this.storage:null, this.type:'get', this.authentication:false, this.criteria:null});
}

class column {
  final String name;

  const column({this.name:null});
}

class key {
  const key();
}

class unique {
  const unique();
}

class onQuery {
  final String queryName;

  const onQuery(this.queryName);
}