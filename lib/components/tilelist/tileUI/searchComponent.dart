import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  Function onChanged;
  Function onInputCompletion;
  TextField textField;
  bool renderBelowTextfield;

  SearchWidget(
      {this.onChanged,
      this.textField,
      this.onInputCompletion,
      this.renderBelowTextfield = true,
      Key key})
      : super(key: key);

  @override
  SearchWidgetState createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  List<TextEditingController> createdControllers = [];
  Widget listView;
  final Container blankResult = Container();
  Future<void> onInputChangeDefault() async {
    Function onInputChangedAsync = this.widget.onChanged;
    if (onInputChangedAsync != null) {
      List<Widget> retrievedWidgets =
          await onInputChangedAsync(this.widget.textField.controller.text);
      if (retrievedWidgets.length > 0) {
        setState(() {
          listView = ListView(
            children: retrievedWidgets,
          );
        });
      } else {
        setState(() {
          listView = blankResult;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextField textField = this.widget.textField;

    double heightOfTextContainer = 40;
    double topMarginOfListContainer = heightOfTextContainer;
    double bottomMarginOfListContainer = 0;
    if (!this.widget.renderBelowTextfield) {
      topMarginOfListContainer = 0;
      bottomMarginOfListContainer = heightOfTextContainer * 4;
    }
    Container listContainer = Container(
      margin: EdgeInsets.fromLTRB(
          0, topMarginOfListContainer, 0, bottomMarginOfListContainer),
      width: 200,
      child: listView,
    );
    Function onInputChanged = this.onInputChangeDefault;
    TextEditingController textEditingController;

    if (textField == null) {
      textEditingController = TextEditingController();
      textField = TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.arrow_back),
          hintText: 'Search',
        ),
      );
      this.widget.textField = textField;
      createdControllers.add(textEditingController);
    } else {
      textEditingController = textField.controller;
    }

    textEditingController.addListener(onInputChanged);
    Container textFieldContainer = Container(
      margin: EdgeInsets.fromLTRB(0, 13, 0, 0),
      height: heightOfTextContainer,
      width: 400,
      child: textField,
    );

    var backButton = Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: BackButton(
          onPressed: this.widget.onInputCompletion,
        ));

    List<Widget> allWidgets = [textFieldContainer, backButton, listContainer];
    return Container(
      margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: Stack(
        children: allWidgets,
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in createdControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
