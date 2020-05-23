import 'dart:ffi';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workshop/record.dart';


class ReceiptWidget extends StatefulWidget {

  final Record record;
  final String docId;

  ReceiptWidget(this.docId, this.record);

  @override
  State<StatefulWidget> createState() {
    return ReceiptWidgetState();
  }

}


class ReceiptWidgetState extends State<ReceiptWidget> {

  Image imageWidget;
  File myFile;
  List<Rect> boundBoxes;
  List<String> values;

  @override
  void initState(){
    super.initState();

    downloadImage();
  }

  Future<File> file(String filename) async {
    Directory dir = await getApplicationDocumentsDirectory();
    String pathName = "${dir.path}/${filename}";
    return File(pathName);
  }

  void downloadImage() async{
    myFile = await file("comprovante.png");
    if (myFile.existsSync()){
      myFile.delete();
    }

    setState(() {
      imageWidget = Image(
        fit: BoxFit.fill,
          image: NetworkToFileImage(
            url: widget.record.voucher,
            file: myFile)
        );
    });
  }

  void readPrice() async{
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(myFile);

    TextRecognizer textRecognizer = FirebaseVision.instance.textRecognizer();
    VisionText visionText = await textRecognizer.processImage(visionImage);
    boundBoxes = List();
    values = List();
    for (TextBlock block in visionText.blocks) {

      for (TextLine line in block.lines) {
        for (TextElement word in line.elements) {
          boundBoxes.add(word.boundingBox);
          if (word.text.length > 3 && word.text[word.text.length - 3] == ',') {
            values.add(word.text);
          }
        }
      }
    }
    textRecognizer.close();

    showAlertDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment(0, 1),
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            imageWidget == null ?
                Container() : imageWidget
          ],
        ),
        /*boundBoxes == null ? Container() : Container(
          width: double.maxFinite,
          height: double.maxFinite,
          child: CustomPaint(
            painter: CurvePainter(boundBoxes),
          ),
        ),*/
        RaisedButton(
          onPressed: () {
            readPrice();
          },
          child: const Text('Procurar Preço', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  showAlertDialog(BuildContext context) {

    // set up the list options
    List<Widget> options = List();
    for (String value in values){
      options.add(SimpleDialogOption(
        child: Text(value),
        onPressed: () {
          while (!value[0].startsWith(RegExp(r'[0-9]'))){
            value = value.substring(1);
          }
          value = value.replaceAll(".", "");
          value = value.substring(0, value.indexOf(","));

          widget.record.valor = int.parse(value);
          CollectionReference collection = Firestore.instance.collection('alunos');
          DocumentReference reference = collection.document(widget.docId);
          reference.setData(widget.record.toJson());

          Navigator.of(context).pop();
        },
      ));
    }

    // set up the SimpleDialog
    SimpleDialog dialog = SimpleDialog(
      title: const Text('Escolha o valor:'),
      children: options
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return dialog;
      },
    );
  }
}

class CurvePainter extends CustomPainter {

  final List<Rect> boundBoxes;

  CurvePainter(this.boundBoxes);

  @override
  void paint(Canvas canvas, Size size) {
    print(size.width);
    print(size.height);
    var paint = Paint();
    paint.color = Colors.amber;
    paint.style = PaintingStyle.stroke;

    var path = Path();

    for (Rect rect in boundBoxes){
      canvas.drawRect(rect, paint);
    }


    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}