import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  String email;
  String name;
  int valor;
  String voucher;
  final DocumentReference reference;

  Map<String, dynamic> toJson() =>
      {
        'name': name,
        'email': email,
        'valor': valor,
        'voucher': voucher
      };

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['email'] != null),
        assert(map['name'] != null),
        email = map['email'],
        name = map['name'],
        valor = map['valor'],
        voucher = map['voucher'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);

}
