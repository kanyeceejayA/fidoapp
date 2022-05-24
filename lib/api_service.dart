import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final _storage = const FlutterSecureStorage();
  // var baseUrl = 'http://10.0.2.2/server';
  var baseUrl = 'https://fido.silbaka.com';

  Future<String?> read({required String key}) async{
    try{
      baseUrl = (await _storage.read(key:'baseUrl'))?? 'https://fido.silbaka.com';
      if (baseUrl == 'http://fido.local') {return await _storage.read(key:key);}
      
      final response = await http.get(Uri.parse(baseUrl+'/read.php?key='+Uri.encodeComponent(key)));
      if(response.statusCode != 200) return null;
      var data = response.body;
      String? result = data;
      return result;
    }catch(e){
      return null;
    }
  }

  Future<String?> write({required String key,required String value}) async{
    try{
      baseUrl = (await _storage.read(key:'baseUrl'))?? 'https://fido.silbaka.com';
      if (baseUrl == 'http://fido.local') {await _storage.write(key:key, value: value); return 'ok';}
      print('url is '+Uri.parse(baseUrl+'/write.php?key='+Uri.encodeComponent(key)+'&d='+Uri.encodeComponent(value)).toString() );
      final response = await http.get(Uri.parse(baseUrl+'/write.php?key='+Uri.encodeComponent(key)+'&d='+Uri.encodeComponent(value)));
      if(response.statusCode != 200) return null;
      var data = response.body;
      String? result = data;
      return result;
    }catch(e){
      return null;
    }
  }

  Future<String?> delete({required String key}) async{
    try{
      baseUrl = (await _storage.read(key:'baseUrl'))?? 'https://fido.silbaka.com';
      if (baseUrl == 'http://fido.local') {await _storage.delete(key:key); return null;}
      final response = await http.get(Uri.parse(baseUrl+'/del.php?key='+Uri.encodeComponent(key)));
      if(response.statusCode != 200) return null;
      var data = response.body;
      String? result = data;
      return result;
    }catch(e){
      return null;
    }
  }
}