import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'dart:convert';

import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class CalendarEventApi extends AppApi {
  Future<CalendarEvent> setAsNow(String eventId) async {
    TilerError error = new TilerError();
    error.message = "Did not send request";
    print('setAsNow ' + eventId);
    return sendPostRequest('api/CalendarEvent/Now', {
      'ID': eventId,
    }).then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        var calendarEventAsNowJson = jsonResult['Content'];
        return CalendarEvent.fromJson(calendarEventAsNowJson);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.message!);
      } else {
        error.message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> delete(String eventId, String thirdPartyId) async {
    TilerError error = new TilerError();
    print('deleting ' + eventId);
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      error.message = "Did not send request";
      String url = Constants.tilerDomain;

      Uri uri = Uri.https(url, 'api/CalendarEvent');
      var header = this.getHeaders();

      if (header != null) {
        var deleteCalendarEventParameters = {
          'ID': eventId,
          'EventID': eventId,
          'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
          'ThirdPartyEventID': thirdPartyId,
          'MobileApp': true.toString()
        };
        var response = await http.delete(uri,
            headers: header, body: json.encode(deleteCalendarEventParameters));
        var jsonResult = jsonDecode(response.body);
        error.message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            var deleteCalendarEventJson = jsonResult['Content'];
            return CalendarEvent.fromJson(deleteCalendarEventJson);
          } else {
            if (isTilerRequestError(jsonResult)) {
              var errorJson = jsonResult['Error'];
              error = TilerError.fromJson(errorJson);
            } else {
              error.message = "Issues with reaching TIler servers";
            }
          }
        }
      }
    }
    throw error;
  }

  Future<CalendarEvent> complete(String eventId) async {
    TilerError error = new TilerError();
    print('completing ' + eventId);
    error.message = "Did not send request";
    var completeParameters = {
      'ID': eventId,
      'EventID': eventId,
      'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
      'MobileApp': true.toString()
    };

    return sendPostRequest('api/CalendarEvent/Complete', completeParameters)
        .then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return CalendarEvent.fromJson(jsonResult['Content']);
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.message!);
      } else {
        error.message = "Issues with reaching Tiler servers";
      }
      throw error;
    });
  }

  Future<CalendarEvent> getCalEvent(String id) async {
    String tilerDomain = Constants.tilerDomain;
    // String url = tilerDomain + 'api/SubCalendarEvent';
    // return getAdHocSubEventId(id);
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      final queryParameters = {
        'EventID': id,
      };
      Map<String, String?> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/CalendarEvent', updatedParams);
      var header = this.getHeaders();
      if (header != null) {
        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            return CalendarEvent.fromJson(jsonResult['Content']);
          }
        }
      }
      throw TilerError();
    }
    throw TilerError();
  }
}
