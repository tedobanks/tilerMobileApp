import 'dart:collection';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/tileUI/chillNow.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

class TileBatch extends StatefulWidget {
  List<TilerEvent>? tiles;
  Timeline? sleepTimeline;
  String? header;
  String? footer;
  int? dayIndex;
  TileBatchState? _state;

  TileBatch(
      {this.header,
      this.footer,
      this.dayIndex,
      this.tiles,
      this.sleepTimeline,
      Key? key})
      : super(key: key);

  @override
  TileBatchState createState() {
    _state = TileBatchState();
    return _state!;
  }
}

class TileBatchState extends State<TileBatch> {
  String uniqueKey = Utility.getUuid;
  bool isInitialized = false;
  Map<String, TilerEvent> tiles = new Map<String, TilerEvent>();
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();
  List<Widget> childrenColumnWidgets = [];

  Timeline? sleepTimeline;

  void updateSubEvents(List<TilerEvent> updatedTiles) {
    Map<String, TilerEvent> currentTiles = new Map.from(tiles);
    Map<String, Tuple2<TilerEvent, RemovalType>> currentRemovedTiles =
        new Map.from(removedTiles);
    Map<String, TilerEvent> allTilesRefreshed = new Map<String, TilerEvent>();
    Map<String, TilerEvent> newlyAddedTiles = new Map<String, TilerEvent>();
    Map<String, Tuple2<TilerEvent, RemovalType>> newlyRemovedTiles =
        new Map<String, Tuple2<TilerEvent, RemovalType>>();
    updatedTiles.forEach((eachTile) {
      if (!currentTiles.containsKey(eachTile.id)) {
        newlyAddedTiles[eachTile.id!] = eachTile;
      } else {
        newlyRemovedTiles[eachTile.id!] =
            new Tuple2<TilerEvent, RemovalType>(eachTile, RemovalType.none);
      }
      allTilesRefreshed[eachTile.id!] = eachTile;
    });

    Map<String, Tuple2<TilerEvent, RemovalType>> refreshRemovedTiles =
        new Map.from(currentRemovedTiles);

    newlyRemovedTiles.forEach((tileId, tileRemovalTuple) {
      if (!refreshRemovedTiles.containsKey(tileId)) {
        refreshRemovedTiles[tileId] = tileRemovalTuple;
      }
    });

    this.setState(() {
      tiles = allTilesRefreshed;
      removedTiles = refreshRemovedTiles;
      uniqueKey = uniqueKey + " || " + this.widget.dayIndex.toString();
    });
  }

  void updateSleepTimelines(Timeline timeline) {
    this.setState(() {
      sleepTimeline = timeline;
      uniqueKey = uniqueKey + " || " + this.widget.dayIndex.toString();
    });
    print('---sleep TL 0 -- ' +
        sleepTimeline!.startTime.toString() +
        ' - ' +
        uniqueKey);
  }

  @override
  Widget build(BuildContext context) {
    List<Timeline> chillTimeLines = [];
    print('' + this.widget.dayIndex.toString() + " " + uniqueKey);
    if (!isInitialized) {
      if (widget.tiles != null) {
        var conflicts = Utility.getConflictingEvents(widget.tiles!);
        List<TilerEvent> allTiles = [];
        HashSet<TilerEvent> postSleepTiles = new HashSet();
        allTiles.addAll(conflicts.item1);
        allTiles.addAll(conflicts.item2);
        allTiles.sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));
        // sleepTimeline = this.widget.sleepTimeline;
        Timeline sleepTileEvent;
        DateTime? startOfSleep;
        DateTime? endOfSleep;
        if (sleepTimeline != null) {
          print('---sleep TL 1 -- ' + sleepTimeline!.startTime.toString() + '');
          postSleepTiles = new HashSet();
          sleepTileEvent = new Timeline(
              widget.sleepTimeline!.startInMs!, widget.sleepTimeline!.endInMs!);

          List<TimeRange> contiguousSleep = allTiles.where((tile) {
            bool isInterfering = sleepTileEvent.isInterfering(tile);
            if (!isInterfering) {
              postSleepTiles.add(tile);
            }
            if (startOfSleep == null ||
                startOfSleep!.millisecondsSinceEpoch >
                    tile.startTime!.millisecondsSinceEpoch) {
              startOfSleep = tile.startTime;
            }

            if (endOfSleep == null ||
                endOfSleep!.millisecondsSinceEpoch <
                    tile.endTime!.millisecondsSinceEpoch) {
              endOfSleep = tile.endTime;
            }

            startOfSleep = startOfSleep!.millisecondsSinceEpoch >
                    sleepTileEvent.startTime!.millisecondsSinceEpoch
                ? sleepTileEvent.startTime!
                : startOfSleep!;
            endOfSleep = endOfSleep!.millisecondsSinceEpoch <
                    sleepTileEvent.endTime!.millisecondsSinceEpoch
                ? sleepTileEvent.endTime!
                : endOfSleep!;

            return isInterfering;
          }).toList();
        } else {
          postSleepTiles = HashSet.from(allTiles);
        }
        var sortedPostSleepTiles = postSleepTiles.toList();
        sortedPostSleepTiles
            .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

        DateTime? refTimeEndTime;
        int beginIndex = 0;
        if (endOfSleep != null) {
          refTimeEndTime = endOfSleep;
        } else {
          if (sortedPostSleepTiles.length > 0) {
            refTimeEndTime = sortedPostSleepTiles[0].endTime;
            beginIndex = 1;
          }
        }

        for (int subEventIndex = beginIndex;
            subEventIndex < sortedPostSleepTiles.length;
            subEventIndex++) {
          TilerEvent eachTilerEvent = sortedPostSleepTiles[subEventIndex];
          if (refTimeEndTime!.millisecondsSinceEpoch <
              eachTilerEvent.startTime!.millisecondsSinceEpoch) {
            Timeline chillTimeline = new Timeline.fromDateTime(
                refTimeEndTime, eachTilerEvent.startTime!);
            chillTimeLines.add(chillTimeline);
          }

          refTimeEndTime = eachTilerEvent.endTime;
        }

        widget.tiles!.forEach((eachTile) {
          if (eachTile.id != null) {
            tiles[eachTile.id!] = eachTile;
          }
        });
      }
      isInitialized = true;
    }
    childrenColumnWidgets = [];
    if (widget.header != null) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
      SizedBox topHeaderMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(topHeaderMargin);
      childrenColumnWidgets.add(headerContainer);
      SizedBox bottomHeaderMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(bottomHeaderMargin);
    }

    Widget? sleepWidget;
    if (sleepTimeline != null) {
      Timeline sleepTimeline = this.sleepTimeline!;
      sleepWidget = SleepTileWidget(sleepTimeline);
      // print('---sleep TL 2 -- ' + sleepTimeline.startTime.toString() + '');
      childrenColumnWidgets.add(sleepWidget);
    }

    List<Tuple3<bool, TimeRange, Widget>> allWidgets = [];
    if (tiles.length > 0) {
      tiles.values.forEach((eachTile) {
        Widget eachTileWidget = TileWidget(eachTile);
        var tuple = new Tuple3(true, eachTile, eachTileWidget);
        allWidgets.add(tuple);
      });

      chillTimeLines.forEach((chillTimeline) {
        Widget eachTileWidget = ChillTimeWidget(chillTimeline);
        var tuple = new Tuple3(false, chillTimeline, eachTileWidget);
        allWidgets.add(tuple);
      });

      allWidgets.sort(
          (tileA, tileB) => tileA.item2.start!.compareTo(tileB.item2.start!));

      childrenColumnWidgets
          .addAll(allWidgets.map((widgetTuple) => widgetTuple.item3));
    }

    if (widget.footer != null) {
      Container footerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 40, 0, 20),
        alignment: Alignment.centerLeft,
        child: Text(widget.footer!,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
      SizedBox topFooterMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(topFooterMargin);
      childrenColumnWidgets.add(footerContainer);
      SizedBox bottomFooterMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(bottomFooterMargin);
    }

    if (sleepWidget != null && sleepTimeline != null) {
      if (childrenColumnWidgets.contains(sleepWidget)) {
        print('---sleep TL 4 -- ' +
            sleepTimeline!.startTime.toString() +
            '\t\t' +
            childrenColumnWidgets.length.toString() +
            "Child widgets " +
            uniqueKey);
      }
    }
    return Container(
      child: Column(
        children: childrenColumnWidgets,
      ),
    );
  }
}