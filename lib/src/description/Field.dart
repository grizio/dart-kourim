part of kourim.description;

class Field {
  final Table table;
  final String name;
  final String type;
  final bool isKey;
  final bool isUnique;

  Field(this.table, this.name, this.type, this.isKey, this.isUnique);
}