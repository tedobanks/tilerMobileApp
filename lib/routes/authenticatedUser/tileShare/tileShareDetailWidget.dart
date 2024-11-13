import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/newTileSheet.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/routes/authenticatedUser/contactListView.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileListWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/multiTiletteTileShareDetail.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/singleTiletteTileShareDetail.dart';
import 'package:tiler_app/services/api/tileShareClusterApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileShareDetailWidget extends StatefulWidget {
  late final String? tileShareId;
  late final TileShareClusterData? tileShareClusterData;
  TileShareDetailWidget.byId(String tileShareId) {
    this.tileShareId = tileShareId;
    this.tileShareClusterData = null;
  }
  TileShareDetailWidget.byTileShareData(
      {required final TileShareClusterData tileShareClusterData}) {
    this.tileShareClusterData = tileShareClusterData;
    this.tileShareId = null;
  }
  @override
  _TileShareDetailWidget createState() => _TileShareDetailWidget();
}

class _TileShareDetailWidget extends State<TileShareDetailWidget> {
  final TileShareClusterApi clusterApi = TileShareClusterApi();
  TileShareClusterData? tileShareCluster;
  late bool? isLoading;
  TilerError? tilerError;
  late bool? isTileListLoading;
  List<DesignatedTile>? designatedTileList = null;
  final rowSpacer = SizedBox.square(
    dimension: 8,
  );
  bool isAddingTiletteLoading = false;
  final verticalSpacer = SizedBox(height: 8);
  ScrollController _contactControllerfinal = ScrollController();

  @override
  void initState() {
    super.initState();
    isTileListLoading = false;
    if (this.widget.tileShareClusterData != null) {
      isLoading = false;
      tileShareCluster = this.widget.tileShareClusterData;
    } else {
      isLoading = true;
      getTileShareCluster();
    }
  }

  Future getTileShareCluster() async {
    bool tileLoadingState = false;
    if (this.widget.tileShareId.isNot_NullEmptyOrWhiteSpace()) {
      tileLoadingState = true;
      clusterApi
          .getTileShareClusters(clusterId: this.widget.tileShareId)
          .then((value) {
        Utility.debugPrint("Success getting tile cluster");
        setState(() {
          tilerError = null;
          tileShareCluster = value.firstOrNull;
          isLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Failed to get tile cluster");
        setState(() {
          tilerError = TilerError(
              message:
                  AppLocalizations.of(context)!.failedToLoadTileShareCluster);
          if (onError is TilerError) {
            tilerError = onError;
          }

          isLoading = false;
        });
      });

      clusterApi
          .getDesignatedTiles(clusterId: this.widget.tileShareId)
          .then((value) {
        setState(() {
          Utility.debugPrint("Success getting tileShare list ");
          tilerError = null;
          designatedTileList = value;
          isTileListLoading = false;
        });
      }).catchError((onError) {
        Utility.debugPrint("Error getting tileShare list ");
        setState(() {
          if (onError is TilerError) {
            tilerError = onError;
          }
          tilerError = TilerError(
              message: AppLocalizations.of(context)!.errorLoadingTilelist);
          isTileListLoading = false;
        });
      });
    }
    isTileListLoading = tileLoadingState;
    setState(() {
      isLoading = true;
      tilerError = null;
      isTileListLoading = tileLoadingState;
    });
  }

  Widget renderAuthorization() {
    throw UnimplementedError();
  }

  Widget renderError() {
    return Text(this.tilerError?.message ?? "Error loading tilelist");
  }

  Widget renderNotFound() {
    return Text("Resource not found");
  }

  Widget _buildContactPill(Contact contact) {
    return Chip(
      avatar: Icon(
        (contact.phoneNumber.isNot_NullEmptyOrWhiteSpace()
            ? Icons.messenger_outline
            : Icons.email_outlined),
        color: TileStyles.primaryContrastColor,
      ),
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: null,
      side: BorderSide.none,
      backgroundColor: TileStyles.primaryColor,
      labelStyle: TextStyle(color: Colors.white),
    );
  }

  Widget renderTileShareCluster() {
    if (this.tileShareCluster == null) {
      this.tilerError = TilerError(
          message: AppLocalizations.of(context)!.missingTileShareCluster);
      return renderError();
    }

    TileShareClusterData cluster = this.tileShareCluster!;
    String creatorInfo =
        cluster.creator?.username ?? cluster.creator?.email ?? "";
    return Padding(
        padding: EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cluster.endTimeInMs != null && cluster.endTimeInMs! > 0)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                  ),
                  rowSpacer,
                  Text(
                    MaterialLocalizations.of(context).formatFullDate(
                        DateTime.fromMillisecondsSinceEpoch(
                            cluster.endTimeInMs!)),
                    style: TileStyles.defaultTextStyle,
                  )
                ],
              )
            else
              SizedBox.shrink(),
            verticalSpacer,
            if (creatorInfo.isNot_NullEmptyOrWhiteSpace())
              Row(
                children: [
                  Icon(
                    Icons.person_2_outlined,
                    size: 16,
                  ),
                  rowSpacer,
                  Text(
                      (creatorInfo.contains('@') ? '' : '@') + '${creatorInfo}',
                      style: TileStyles.defaultTextStyle)
                ],
              ),
            verticalSpacer,
            Container(
              height: 50,
              child: ListView(
                controller: _contactControllerfinal,
                children: [
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      ...(cluster.contacts ?? [])
                          .map((contact) => _buildContactPill(contact))
                          .toList(),
                    ],
                  ),
                ],
              ),
            ),
            verticalSpacer,
          ],
        ));
  }

  Widget renderLoading() {
    return CircularProgressIndicator();
  }

  void renderModal(
      // {NewTile? currentTile}
      ) {
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        print("is pending " + isAddingTiletteLoading.toString());
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: Container(
            height: 515,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            child: Stack(
              children: <Widget>[
                NewTileSheetWidget(
                  onAddTile: (NewTile? newTile) {
                    if (newTile != null && tileShareCluster != null) {
                      setState(() {
                        isAddingTiletteLoading = true;
                      });
                      ClusterTemplateTileModel clusterTemplate =
                          newTile.toClusterTemplateTileModel();
                      clusterTemplate.ClusterId = tileShareCluster?.id;
                      clusterApi
                          .createTileTemplate(clusterTemplate)
                          .then((value) {
                        getTileShareCluster();
                        setState(() {
                          isAddingTiletteLoading = false;
                        });
                        Navigator.pop(context);
                      }).catchError((onError) {
                        setState(() {
                          isAddingTiletteLoading = false;
                        });
                      });
                      setState(() {
                        isAddingTiletteLoading = true;
                      });
                    }
                  },
                  onCancel: () => {Navigator.pop(context)},
                ),
                if (isAddingTiletteLoading)
                  PendingWidget(
                    backgroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10))),
                    imageAsset: TileStyles.evaluatingScheduleAsset,
                  )
                else
                  SizedBox.shrink()
              ],
            ),
          ),
        );
      },
    );
  }

  Widget addTileShare() {
    return ElevatedButton.icon(
        style: TileStyles.enabledButtonStyle,
        onPressed: () {
          renderModal();
        },
        icon: Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.addTilette));
  }

  @override
  Widget build(BuildContext context) {
    if (this.isLoading == true) {
      return Scaffold(
        body: Center(
          child: renderLoading(),
        ),
      );
    }
    if (this.tileShareCluster != null) {
      if (this.tileShareCluster!.isMultiTilette == true) {
        return MultiTiletteTileShareDetailWidget(
            tileShareClusterData: this.tileShareCluster!);
      } else {
        return SingleTiletteTileShareDetailWidget(
            tileShareClusterData: this.tileShareCluster!);
      }
    }

    return Scaffold(
      body: Center(
        child: renderError(),
      ),
    );
  }
}
