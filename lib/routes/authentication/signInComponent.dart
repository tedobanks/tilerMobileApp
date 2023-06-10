import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/services/api/googleSignInApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/util.dart';
import '../../services/api/authorization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import '../../constants.dart' as Constants;
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tuple/tuple.dart';

import 'AuthorizedRoute.dart';

class SignInComponent extends StatefulWidget {
  @override
  SignInComponentState createState() => SignInComponentState();
}

// Define a corresponding State class.
// This class holds data related to the Form.
class SignInComponentState extends State<SignInComponent> {
  // Create a text controller. Later, use it to retrieve the
  // current value of the TextField.
  final _formKey = GlobalKey<FormState>();
  final userNameEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final confirmPasswordEditingController = TextEditingController();
  bool isRegistrationScreen = false;
  double credentialManagerHeight = 350;
  double credentialButtonHeight = 150;

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  void adHocSignin() async {
    if (_formKey.currentState!.validate()) {
      showMessage(AppLocalizations.of(context)!.signingIn);
      Authorization authorization = new Authorization();
      AuthenticationData authenticationData =
          await authorization.getAuthenticationInfo(
              userNameEditingController.text, passwordEditingController.text);

      String isValidSignIn = "Authentication data is valid:" +
          authenticationData.isValid.toString();
      if (!authenticationData.isValid) {
        if (authenticationData.errorMessage != null) {
          showErrorMessage(authenticationData.errorMessage!);
          return;
        }
      }

      TextInput.finishAutofillContext();
      Authentication localAuthentication = new Authentication();
      await localAuthentication.saveCredentials(authenticationData);
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      context.read<ScheduleBloc>().add(LogInScheduleEvent());
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthorizedRoute()),
      );
      print(isValidSignIn);
    }
  }

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  void registerUser() async {
    if (_formKey.currentState!.validate()) {
      showMessage(AppLocalizations.of(context)!.registeringUser);
      Authorization authorization = new Authorization();
      AuthenticationData authenticationData = await authorization.registerUser(
          emailEditingController.text,
          passwordEditingController.text,
          userNameEditingController.text,
          confirmPasswordEditingController.text,
          null);

      String isValidSignIn = "Authentication data is valid:" +
          authenticationData.isValid.toString();
      if (!authenticationData.isValid) {
        if (authenticationData.errorMessage != null) {
          showErrorMessage(authenticationData.errorMessage!);
          return;
        }
      }
      Authentication localAuthentication = new Authentication();
      await localAuthentication.saveCredentials(authenticationData);
      while (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AuthorizedRoute()),
      );

      print(isValidSignIn);
    }
  }

  void setAsRegistrationScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() => {
          isRegistrationScreen = true,
          credentialManagerHeight = 450,
          credentialButtonHeight = 320
        });
  }

  void setAsSignInScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() => {
          isRegistrationScreen = false,
          credentialManagerHeight = 350,
          credentialButtonHeight = 150
        });
  }

  Future<Map<String, dynamic>> getRefreshToken(String clientId,
      String clientSecret, String serverAuthCode, List<String> scopes) async {
    final String refreshTokenEndpoint = 'https://oauth2.googleapis.com/token';

    final Map<String, dynamic> requestBody = {
      'client_id': clientId,
      'client_secret': clientSecret,
      'grant_type': 'authorization_code',
      'code': serverAuthCode,
      'redirect_uri':
          'https://localhost-44388-x-if7.conveyor.cloud/signin-google',
      'scope': scopes.join(' '),
    };

    final http.Response response = await http.post(
      Uri.parse(refreshTokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData;
      // final String refreshToken = responseData['refresh_token'];
      // return refreshToken;
    } else {
      throw Exception('Failed to get refresh token');
    }
  }

  Future signInToGoogle() async {
    ScheduleApi scheduleApi = new ScheduleApi();
    scheduleApi.getSubEvents(Utility.todayTimeline()).then((values) {
      print(values);
    });

    return;

    var googleUser = await GoogleSignInApi.login();
    if (googleUser != null) {
      var googleAuthentication = await googleUser!.authentication;
      var authHeaders = await googleUser.authHeaders;
      print(authHeaders);

      String clientId =
          '518133740160-i5ie6s4h802048gujtmui1do8h2lqlfj.apps.googleusercontent.com';
      String clientSecret = 'NKRal5rA8NM5qHnmiigU6kWh';

      String? refreshToken;
      String? accessToken = googleAuthentication.accessToken;
      if (googleUser.serverAuthCode != null) {
        refreshToken = googleAuthentication.idToken!;
        final List<String> requestedScopes = [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events.readonly',
          "https://www.googleapis.com/auth/calendar.readonly",
          "https://www.googleapis.com/auth/calendar.events",
          'https://www.googleapis.com/auth/userinfo.email'
        ];
        Map serverResponse = await getRefreshToken(clientId, clientSecret,
            googleUser.serverAuthCode!, requestedScopes);

        refreshToken = serverResponse['refresh_token'];
        accessToken = serverResponse['access_token'];
      }
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      Uri uri = Uri.https(url, 'account/MobileExternalLogin');

      //       [Required]
      // public string AccessToken { get; set; }
      // public string RefreshToken { get; set; }
      // public string ThirdPartyType { get;set; }

      Map<String, dynamic> injectedParameters = {
        'Email': googleUser.email,
        'AccessToken': accessToken,
        'DisplayName': googleUser.displayName,
        'ProviderKey': googleUser.id,
        'ThirdPartyType': 'Google',
        'RefreshToken': refreshToken
      };

      // var response = await http.post(uri, body: jsonEncode(injectedParameters));

      var response = await http.post(uri,
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: injectedParameters,
          encoding: Encoding.getByName("utf-8"));
      // var response = await http.post(uri, body: jsonEncode(injectedParameters));

      var jsonResult = jsonDecode(response.body);

      // token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1bmlxdWVfbmFtZSI6Ikplcm9tZSAiLCJlbWFpbCI6ImozcjBtMzVwYW1AZ21haWwuY29tIiwibmJmIjoxNjg2MTIwNDA3LCJleHAiOjE2ODYxMjQwMDcsImlhdCI6MTY4NjEyMDQwN30.iYGMYCKURbLcP4VdfhB2J2aI_kocCaRLYCUwgr-TEIM'

      String token = jsonResult['access_token'];
      Constants.adhocToken = token;

      // if (jsonResult != null) {
      //   showMessage(AppLocalizations.of(context)!.signingIn);
      //   Authorization authorization = new Authorization();
      //   AuthenticationData authenticationData =
      //       await authorization.getAuthenticationInfo(
      //           userNameEditingController.text, passwordEditingController.text);

      //   String isValidSignIn = "Authentication data is valid:" +
      //       authenticationData.isValid.toString();
      //   if (!authenticationData.isValid) {
      //     if (authenticationData.errorMessage != null) {
      //       showErrorMessage(authenticationData.errorMessage!);
      //       return;
      //     }
      //   }

      //   TextInput.finishAutofillContext();
      //   Authentication localAuthentication = new Authentication();
      //   await localAuthentication.saveCredentials(authenticationData);
      //   while (Navigator.canPop(context)) {
      //     Navigator.pop(context);
      //   }
      //   context.read<ScheduleBloc>().add(LogInScheduleEvent());
      //   Navigator.pop(context);
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (context) => AuthorizedRoute()),
      //   );
      //   print(isValidSignIn);
      // }

      // final oauth2.AuthorizationCodeGrant authClient =
      //     oauth2.AuthorizationCodeGrant(
      //   'your_client_id',
      //   'your_client_secret',
      //   Uri.parse('your_redirect_uri'),
      // );

      // final oauth2.Credentials credentials =
      //     await authClient.handleAuthorizationCode(
      //   googleAuth.serverAuthCode,
      // );

      // // Get the refresh token
      // final String refreshToken = credentials.refreshToken;
      // print('Refresh Token: $refreshToken');
    }
  }

  @override
  void dispose() {
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    emailEditingController.dispose();
    confirmPasswordEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var usernameTextField = TextFormField(
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (!isRegistrationScreen) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.fieldIsRequired;
          }
        }
        return null;
      },
      controller: userNameEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newUsername
            : AutofillHints.username
      ],
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.username,
        labelText: AppLocalizations.of(context)!.username,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.person),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    var emailTextField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.emailIsRequired;
        }
        return null;
      },
      controller: emailEditingController,
      autofillHints: [AutofillHints.email],
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.email,
        hintText: AppLocalizations.of(context)!.email,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.email),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    var passwordTextField = TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.passwordIsRequired;
        }

        if (isRegistrationScreen) {
          var minPasswordLength = 6;
          if (value != confirmPasswordEditingController.text) {
            return AppLocalizations.of(context)!.passwordsDontMatch;
          }
          if (value.length < minPasswordLength) {
            return AppLocalizations.of(context)!
                .passwordNeedToBeAtLeastSevenCharacters;
          }

          if (!value.contains(RegExp(r'[A-Z]+'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveUpperCaseChracters;
          }
          if (!value.contains(RegExp(r'[a-z]+'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveLowerCaseChracters;
          }
          if (!value.contains(RegExp(r'[0-9]+'))) {
            return AppLocalizations.of(context)!.passwordNeedsToHaveNumber;
          }
          if (!value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
            return AppLocalizations.of(context)!
                .passwordNeedsToHaveASpecialCharacter;
          }
        }

        return null;
      },
      controller: passwordEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newPassword
            : AutofillHints.password
      ],
      onEditingComplete: () => TextInput.finishAutofillContext(),
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.password,
        labelText: AppLocalizations.of(context)!.password,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.lock),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: Color.fromRGBO(255, 255, 255, .75),
      ),
    );
    List<Widget> textFields = [usernameTextField, passwordTextField];
    var signUpButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: Colors.transparent, // background
          onPrimary: Colors.white,
          shadowColor: Colors.transparent // foreground
          ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.person_add),
          ),
          Text('Sign Up')
        ],
      ),
      onPressed: setAsRegistrationScreen,
    );
    var signInButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: Colors.transparent, // background
          onPrimary: Colors.white,
          shadowColor: Colors.transparent // foreground
          ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_forward),
          ),
          Text(AppLocalizations.of(context)!.signIn)
        ],
      ),
      onPressed: adHocSignin,
    );

    var googleSignInButton = ElevatedButton.icon(
        onPressed: signInToGoogle,
        icon: FaIcon(
          FontAwesomeIcons.google,
          color: Colors.white,
        ),
        label: Text(AppLocalizations.of(context)!.signUpWithGoogle));

    var backToSignInButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: Colors.transparent, // background
          onPrimary: Colors.white,
          shadowColor: Colors.transparent // foreground
          ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_back),
          ),
          Text('Sign In')
        ],
      ),
      onPressed: setAsSignInScreen,
    );

    var registerUserButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
          primary: Colors.transparent, // background
          onPrimary: Colors.white,
          shadowColor: Colors.transparent // foreground
          ),
      child: Column(
        children: [
          Container(
            height: 50,
            width: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              border: Border.all(width: 4.0, color: const Color(0xFFFFFFFF)),
              borderRadius: BorderRadius.all(Radius.circular(40)),
              color: Colors.transparent,
            ),
            child: Icon(Icons.arrow_forward),
          ),
          Text('Register')
        ],
      ),
      onPressed: registerUser,
    );

    var buttons = [signUpButton, googleSignInButton, signInButton];

    if (isRegistrationScreen) {
      var confirmPasswordTextField = TextFormField(
        keyboardType: TextInputType.visiblePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.confirmPasswordRequired;
          }
          return null;
        },
        controller: confirmPasswordEditingController,
        obscureText: true,
        autofillHints: [AutofillHints.newPassword],
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.confirmPassword,
          labelText: AppLocalizations.of(context)!.confirmPassword,
          filled: true,
          isDense: true,
          prefixIcon: Icon(Icons.lock),
          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          fillColor: Color.fromRGBO(255, 255, 255, .75),
        ),
      );
      textFields = [
        emailTextField,
        passwordTextField,
        confirmPasswordTextField,
        usernameTextField
      ];
      buttons = [backToSignInButton, googleSignInButton, registerUserButton];
    }
    return Form(
        key: _formKey,
        child: Container(
            alignment: Alignment.topCenter,
            height: credentialManagerHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0)),
              color: Color.fromRGBO(245, 245, 245, 0.2),
              boxShadow: [
                BoxShadow(
                    color: Color.fromRGBO(245, 245, 245, 0.25),
                    spreadRadius: 5),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 10),
            child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: credentialButtonHeight,
                      padding: const EdgeInsets.symmetric(
                          vertical: 5.0, horizontal: 20),
                      child: AutofillGroup(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: textFields,
                        ),
                      ),
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: buttons,
                      ),
                    ),
                  ],
                ))));
  }
}
