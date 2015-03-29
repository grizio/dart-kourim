part of kourim.description;

class Field {
  final String name;
  final String type;
  final bool isKey;
  final bool isUnique;
  final Table table;

  Field(this.name, this.type, this.isKey, this.isUnique, this.table);
}