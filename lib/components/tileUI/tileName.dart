import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

class TileName extends StatefulWidget {
  SubCalendarEvent subEvent;
  TileName(this.subEvent) {
    assert(this.subEvent != null);
  }
  @override
  TileNameState createState() => TileNameState();
}

class TileNameState extends State<TileName> {
  @override
  Widget build(BuildContext context) {
    var subEvent = widget.subEvent;
    int redColor = subEvent.colorRed == null ? 125 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 125 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 125 : subEvent.colorGreen!;
    String name = subEvent.name == null ? "" : subEvent.name!;
    double opacity = subEvent.colorOpacity == null ? 1 : subEvent.colorOpacity!;
    Text emojiField = Text('');
    if (subEvent.emojis != null && subEvent.emojis!.isNotEmpty) {
      double fontSize = 16;
      String emojiString = subEvent.emojis!.trim();
      if (emojiString.length > 0) {
        fontSize = fontSize / (emojiString.length / 2) + 2;
      }
      emojiField = Text(emojiString,
          style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(31, 31, 31, 1)));
      print("Emoji length " + emojiString.length.toString());
      print("" + emojiString);
    }

    var nameColor = Color.fromRGBO(redColor, greenColor, blueColor, opacity);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 32,
            height: 32,
            margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            decoration: BoxDecoration(
              color: nameColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(children: <Widget>[
              Center(
                child: emojiField,
              )
            ]),
          ),
          Flexible(
              child: new Container(
                  child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 20,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(31, 31, 31, 1)),
          )))
        ],
      ),
    );
  }
}
