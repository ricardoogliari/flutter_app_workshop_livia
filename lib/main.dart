import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:intl/intl.dart';
import 'package:workshop/receipt.dart';
import 'package:workshop/record.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Workshop',
      initialRoute: '/',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> emails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workshop Lívia'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.email),
            onPressed: () {
              _asyncSendEmailDialog(context);
            },
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('alunos').orderBy("name").snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildListAndTotal(context, snapshot.data.documents);
      },
    );
  }
  
  Widget _buildListAndTotal(BuildContext context, List<DocumentSnapshot> snapshot){
    int total = 0;
    emails = List();
    snapshot.forEach((element){
      Record record = Record.fromSnapshot(element);

      print(record.name);
      print(record.email);
      emails.add(record.email);
      total += record.valor ?? 0;
    });

    var f = new NumberFormat.currency(locale: "pt-BR", symbol: "R\$");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: Text("Total de alunos: ${snapshot.length}"),
            subtitle: Text("Total arrecados: ${f.format(total)}"),
          ),
          Expanded(
            child: _buildList(context, snapshot)
          )
        ],
      );
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(record.name),
          subtitle: Text(
            record.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: InkWell(
            child: Icon(
              Icons.attach_file,
              size: 24,
            ),
            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptWidget(data.documentID, record),
                ),
              );
            },
          ),
          trailing: Text("${record.valor ?? 0}"),

          onLongPress: () {
            if (record.valor == null)
              _asyncInputDialog(context, data.documentID, record);
          },
        ),
      ),
    );
  }

  Future<String> _asyncInputDialog(BuildContext context, String ID, Record record) async {
    String value = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Insira o valor:'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Valor'),
                  onChanged: (vl) {
                    value = vl;
                  },
                ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                record.valor = int.parse(value);
                CollectionReference collection = Firestore.instance.collection('alunos');
                DocumentReference reference = collection.document(ID);
                reference.setData(record.toJson());

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> _asyncSendEmailDialog(BuildContext context) async {
    String value = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Insira o conteúdo do e-mail:'),
          content: Row(
            children: <Widget>[
              Expanded(
                  child: TextField(
                    maxLines: 8,
                    keyboardType: TextInputType.multiline,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: 'Valor'),
                    onChanged: (vl) {
                      value = vl;
                    },
                  ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () async {
                final Email email = Email(
                  body: value,
                  subject: 'Aviso Workshop Lívia',
                  recipients: emails,
                  isHTML: false,
                );

                await FlutterEmailSender.send(email);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}