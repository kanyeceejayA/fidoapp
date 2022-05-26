
 //gnore_for_file: public_member_api_docs

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fido2/flutter_fido2.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final FlutterFido2 fido2 = FlutterFido2(); //instatiate the class
  final authServer = AuthServer();  //Used to illustrate Communications to your Server

  String rpDomain = 'fido.silbaka.com'; //This should be set by you. it can be local or come from your server.
  final String rpname = 'Silbaka';
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  String _regResult = '';
  bool _isAuthenticating = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final _storage = FlutterSecureStorage();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>(); 


  @override
  void initState() {
    super.initState();
    _setUrl();
  }

  _updateUrl() async {
    _storage.write(key: 'baseUrl', value: _urlController.text);
    _messengerKey.currentState!.showSnackBar(SnackBar(content: Text('successfully changed url to ${_urlController.text}')));
    rpDomain = _urlController.text;
  }

  Future<void> _setUrl() async {
    _urlController.text = await _storage.read(key: 'baseUrl')?? 'https://fido.silbaka.com';
  }


  Future<void> _getAvailableBiometrics() async {
    late List<BiometricType> availableBiometrics;
    
    availableBiometrics = await fido2.getAvailableBiometrics();
    
    if (!mounted) {
      return;
    }

    setState(() {
      _availableBiometrics = availableBiometrics;
    });
  }

  Future<dynamic> _register() async {
    RegistrationResult result;
    String finalMessage = '';
    String message = '';
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
    try {
        //Contact Your Server and receive the challenge and a list of credentials to exclude.
        Map request = await authServer.registrationRequest(userId: _usernameController.text);

       //Send information from server to plugin to authenticate.
       result = await fido2.register(
        challenge: request['challenge'],
        excludeCredentials: request['credentials'],
        userId: _usernameController.text,
        rpDomain: rpDomain,
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      //Store Credential
      finalMessage = await authServer.storeCredential(userId:_usernameController.text , credentialId:result.credentialId ,signedChallenge:result.signedChallenge , publicKey:result.publicKey );
      
      if (finalMessage.contains('Successful') ) message = "\n $finalMessage \n\n \ncredid: \t ${result.credentialId} \n\n pubkey: \t ${result.publicKey} \n\n signedChallenge: \t ${result.signedChallenge}";
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticated';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
        message = '';
        _regResult = e.toString();
      });
      return;
    }
    if (!mounted) {
      return;
    }

    
    setState(() {
      _authorized = "authorized";
      _regResult = message;
    });
  }

  Future<dynamic> _signChallenge() async {
    SigningResult result;
    String finalMessage = '';
    String message = '';
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Authenticating';
      });
    // bool authenticated = false;
    try {

      //Contact Your Server and receive the challenge and a list of credentials to exclude.
      Map request = await authServer.signingRequest(userId: _usernameController.text);
      print('AKBR credentials:'+request['credentials'].toString());
      if(request['credentials'].toString() == '[]'){
          message = 'Error - User Not found.';
         }else{

            result = await fido2.signChallenge(
              challenge: request['challenge'],
              allowCredentials: request['credentials'] as List<String>,
              userId: _usernameController.text,
              rpDomain: rpDomain,
              options: const AuthenticationOptions(
                useErrorDialogs: true,
                stickyAuth: true,
                biometricOnly: true,
              ),

            );
            finalMessage = await authServer.confirmSignIn(userId: _usernameController.text, credentialId: result.credentialId, signedChallenge: result.signedChallenge);
            message = "\n $finalMessage\n credentialID: \t ${result.credentialId} \n\n userId: \t ${result.userId} \n\n No. of Saved Credentials for User: \t ${(request['credentials'] as List<String>).length} \n\n signedChallenge: \t ${result.signedChallenge}";
          
         }
      
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Authenticated';
      });
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
        _regResult = e.toString();
      });
      return;
    }
    if (!mounted) {
      return;
    }

    
    setState(() {
      _authorized = "authorized";
      _regResult = message;
    });
  }

 
  Future<void> _cancelAuthentication() async {
    await fido2.stopAuthentication();
    setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fido2 Auth Example Flutter'),
        ),
        body: ListView(
          padding: const EdgeInsets.only(top: 30),
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(': $_availableBiometrics\n'),
                ElevatedButton(
                  onPressed: _getAvailableBiometrics,
                  child: const Text('Check for Auth Support'),
                ),
                const Divider(height: 20),
                Text('Current State: $_authorized\n'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal:16.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Username:'),
                      TextField(
                        controller: _usernameController,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          // style: TextStyle(fontSize: 16,),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder() ,
                            hintStyle:  TextStyle(color: Colors.black54,fontSize: 15),
                          )
                        ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                if (_isAuthenticating)
                  Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 5,),
                      ElevatedButton(
                        onPressed: _cancelAuthentication,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const <Widget>[
                            Text('Cancel'),
                            Icon(Icons.cancel),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: _register,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(_isAuthenticating
                                ? 'Cancel'
                                : 'Register'),
                            const Icon(Icons.fingerprint),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _signChallenge,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const <Widget>[
                            Text('Sign'),
                            Icon(Icons.login),
                          ],
                        ),
                      ),
                      
                    ],
                  ),
              const SizedBox(height: 10,),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('$_regResult \n'),
              ),
              const Divider(height: 50,),Padding(
                  padding: const EdgeInsets.symmetric(horizontal:16.0),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remote Server Address:'),
                      TextField(
                        controller: _urlController,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          // style: TextStyle(fontSize: 16,),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder() ,
                            hintStyle:  TextStyle(color: Colors.black54,fontSize: 15),
                          )
                        ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                ElevatedButton(
                        onPressed: _updateUrl,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('updateUrl'),
                            Icon(Icons.link),
                          ],
                        ),
                      ),
                      

              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}