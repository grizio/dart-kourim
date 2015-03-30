part of kourim.description;

class Field {
  final Table table;
  final String name;
  final bool isKey;
  final bool isUnique;

  Field(this.table, this.name, this.isKey, this.isUnique);
}