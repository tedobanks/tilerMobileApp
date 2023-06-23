import 'package:json_annotation/json_annotation.dart';
part 'TilerError.g.dart';

@JsonSerializable()
class TilerError {
  static const String unexpectedCharacter = 'Unexpected character';
  String? message;
  String? Code;
  TilerError({this.message});

  factory TilerError.fromJson(Map<String, dynamic> json) =>
      _$TilerErrorFromJson(json);

  Map<String, dynamic> toJson() => _$TilerErrorToJson(this);
  static bool isUnexpectedCharacter(e) {
    return e != null &&
        (e is FormatException) &&
        (e).message == TilerError.unexpectedCharacter;
  }
}
