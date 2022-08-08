import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  Function? onChanged;
  Function? onInputCompletion;
  Function? onBackButtonPressed;
  TextField? textField;
  bool renderBelowTextfield;
  BoxDecoration? resultBoxDecoration;

  SearchWidget(
      {this.onChanged,
      this.textField,
      this.onInputCompletion,
      this.renderBelowTextfield = true,
      this.onBackButtonPressed,
      this.resultBoxDecoration,
      Key? key})
      : super(key: key);

  @override
  SearchWidgetState createState() => SearchWidgetState();
}

class SearchWidgetState extends State<SearchWidget> {
  List<TextEditingController> createdControllers = [];
  Widget? listView;
  String searchedText = '';
  bool showResponseContainer = true;
  final Container blankResult = Container();
  Future<void> onInputChangeDefault() async {
    Function collapseResultContainer = (seletedObject) {
      setState(() {
        showResponseContainer = false;
      });
    };
    Function? onInputChangedAsync = this.widget.onChanged;
    if (this.widget.textField?.controller?.text != searchedText) {
      if (onInputChangedAsync != null &&
          this.widget.textField != null &&
          this.widget.textField!.controller != null) {
        if (this.widget.textField != null &&
            this.widget.textField!.controller != null) {
          setState(() {
            searchedText = this.widget.textField!.controller!.text;
            showResponseContainer = true;
          });
        }

        List<Widget> retrievedWidgets = await onInputChangedAsync(
            this.widget.textField!.controller!.text, collapseResultContainer);
        if (retrievedWidgets.length > 0) {
          setState(() {
            listView = Container(
                decoration: this.widget.resultBoxDecoration,
                child: ListView(
                  children: retrievedWidgets,
                ));
          });
        } else {
          setState(() {
            listView = blankResult;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextField? textField = this.widget.textField;
    List<Widget> allWidgets = [];

    double heightOfTextContainer = 40;
    double topMarginOfListContainer = heightOfTextContainer;
    double bottomMarginOfListContainer = 0;
    if (!this.widget.renderBelowTextfield) {
      topMarginOfListContainer = 0;
      bottomMarginOfListContainer = heightOfTextContainer * 4;
    }
    TextEditingController? textEditingController;

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
      if (textField.controller != null) {
        textEditingController = textField.controller!;
      }
    }

    textEditingController?.addListener(this.onInputChangeDefault);
    Container textFieldContainer = Container(
      margin: EdgeInsets.fromLTRB(0, 13, 0, 0),
      height: heightOfTextContainer,
      child: textField,
    );

    // allWidgets.add(textFieldContainer);

    var backButton = Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: BackButton(
          onPressed: () {
            if (this.widget.onInputCompletion != null) {
              this.widget.onInputCompletion!();
            }

            if (this.widget.onBackButtonPressed != null) {
              this.widget.onBackButtonPressed!();
            }
          },
        ));
    // allWidgets.add(backButton);

    allWidgets = [textFieldContainer, backButton];

    if (showResponseContainer) {
      Container listContainer = Container(
        margin: EdgeInsets.fromLTRB(
            0, topMarginOfListContainer, 0, bottomMarginOfListContainer),
        padding: EdgeInsets.fromLTRB(5, 5, 5, 5),
        child: listView,
      );
      allWidgets.add(listContainer);
    }

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
