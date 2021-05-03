import 'dart:convert';
import 'dart:io';

import 'package:aktiv_app_flutter/Models/role_permissions.dart';
import 'package:aktiv_app_flutter/Views/profile/components/profile_persoenlich.dart';
import 'package:aktiv_app_flutter/util/rest_api_service.dart';
import 'package:aktiv_app_flutter/util/secure_storage_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart';

class UserProvider extends ChangeNotifier {
  static ROLE _role = ROLE.NOT_REGISTERED;
  final SecureStorage storage = SecureStorage();
  bool _signInWithToken = false;
  bool get isSignInWithToken => _signInWithToken;
  static int userId = -1;
  static int bald = 30, naehe = 100;
  String mail,
      vorname,
      nachname,
      tel,
      strasse,
      ort,
      accessToken,
      refreshToken,
      institutionen,
      rolle,
      profilBild,
      hausnummer,
      plz,
      institutionBild;
  static bool istEingeloggt = false;
  bool datenVollstaendig = false;
  bool get getDatenVollstaendig => datenVollstaendig;
  List<String> genehmigerPLZs;

  // TODO: Evtl die Rolle über den

  //  userRole => _role;
  static ROLE getUserRole() {
    return _role;
  }

  void setUserRole(ROLE role) {
    _role = role;
  }

  login<Response>(String mail, password) async {
    var jwt = await attemptLogIn(mail, password);

    if (jwt.statusCode == 200) {
      var parsedJson = json.decode(jwt.body);
      istEingeloggt = true;

      var userId = parsedJson['id'];
      var accessToken = parsedJson['accessToken'];
      var refreshToken = parsedJson['refreshToken'];

      if (jwt != null) {
        storage.deleteAll();
        storage.write("userId", userId.toString());
        storage.write("accessToken", accessToken);
        storage.write("refreshToken", refreshToken);
        storage.write("accessTokenTs", DateTime.now().toString());
      }
      collectUserInfo(parsedJson['id'], accessToken);
    }

    return jwt;
  }

  collectUserInfo(var id, var accessToken) async {
    var detailedUserInfo = await attemptGetUserInfo(id.toString(), accessToken);
    print("detailed User Info: " + detailedUserInfo.body);

    var parsedUser = json.decode(detailedUserInfo.body);

    userId = parsedUser['id'];
    plz = parsedUser['plz'];
    hausnummer = parsedUser['hausnummer'];
    tel = parsedUser['tel'];
    bald = parsedUser['baldEinstellung'];
    naehe = parsedUser['umkreisEinstellung'];

    mail = parsedUser['mail'];
    vorname = parsedUser['vorname'];
    nachname = parsedUser['nachname'];
    strasse = parsedUser['strasse'];
    ort = parsedUser['ort'];
    rolle = parsedUser['rolle'];
    profilBild = parsedUser['profilbild'];
    datenVollstaendig = checkDataCompletion();
    //genehmigerPLZs = getGenehmigerPLZs(userId);
  }

  getAccessToken() async {
    var _accessToken = await storage.read('accessToken');
    if (_accessToken != null) {
      DateTime accessTokenTs =
          DateTime.parse(await storage.read('accessTokenTs'));
      if (DateTime.now().difference(accessTokenTs).inMinutes >= 30) {
        var _jwt = await storage.read('refreshToken');
        if (_jwt != null) {
          var jwt =
              await attemptNewAccessToken(await storage.read('refreshToken'));
          if (jwt.statusCode == 502) {
            errorToast("Keine Verbindung zum Server");
            return null;
          } else {
            var parsedToken = json.decode(jwt.body);
            accessToken = parsedToken['accessToken'];
            refreshToken = parsedToken['refreshTokenNeu'];

            storage.write("accessToken", accessToken);
            storage.write("refreshToken", refreshToken);
            storage.write("accessTokenTs", DateTime.now().toString());

            return accessToken;
          }
        }
        return null;
      }
    }
    return await storage.read('accessToken');
  }

  getUserIdFromStorage() async {
    var _userId = await storage.read('userId');
    if (_userId != null) {
      getAccessToken();
      istEingeloggt = true;
      return _userId;
    }
    return null;
  }

  signInWithToken() async {
    var userId = await storage.read("userId");
    var accessToken = await getAccessToken();

    if (accessToken != null) {
      await collectUserInfo(int.parse(userId), accessToken);
      _signInWithToken = true;
    } else {
      return null;
    }
  }

  signOff() async {
    istEingeloggt = false;
    await storage.deleteAll();
  }

  updateUserInfo<Response>(String vorname, String nachname, String plz,
      String tel, String strasse, String hausnummer) async {
    var jwt = await attemptUpdateUserInfo(
        mail.toString(),
        vorname.toString(),
        nachname.toString(),
        plz.toString(),
        tel.toString(),
        strasse.toString(),
        hausnummer.toString(),
        userId.toString(),
        await getAccessToken());
    var accessToken = await storage.read('accessToken');
    await collectUserInfo(userId, accessToken);

    notifyListeners();
    return jwt;
  }

  updateUserSettings(String naehe, String bald) async {
    var jwt = await attemptUpdateSettings(
        userId.toString(), await getAccessToken(), naehe, bald);
    collectUserInfo(userId.toString(), await getAccessToken());
    notifyListeners();
    return jwt;
  }

  changeProfileImage(File file) async {
    var jwt = await attemptNewProfilImage(file.path, file, userId.toString());
    var parsedProfilBild = json.decode(jwt.body);
    profilBild = parsedProfilBild['pfad'];
    notifyListeners();
    return jwt;
  }

  loadProfileImage() async {
    var jwt = await attemptGetFile(profilBild);
    notifyListeners();
    return jwt;
  }

  setRole(String mail, String rolle) async {
    switch (rolle.toLowerCase()) {
      case "user":
        rolle = "1";
        break;
      case "genehmiger":
        rolle = "2";
        break;
      case "betreiber":
        rolle = "3";
        break;
      default:
        rolle = "1";
    }
    var user = await attemptGetUser(mail);
    var parsedUser = json.decode(user.body);
    var _map = parsedUser.values.toList();
    if (_map[0] != false) {
      var _userId = _map[1]['id'].toString();

      var jwt = await attemptUpdateRole(_userId, rolle, await getAccessToken());
      notifyListeners();
      return jwt;
    }
    return null;
  }

  verwalterHinzufuegen(String mail, String institutionsId) async {
    var verwalter = await attemptGetUser(mail);
    var parsedVerwalter = json.decode(verwalter.body);
    var _map = parsedVerwalter.values.toList();
    if (_map[0] != false) {
      var _userId = _map[1]['id'].toString();

      var jwt = await attemptSetVerwalter(
          _userId, institutionsId, await getAccessToken());
      return jwt;
    }
    return null;
  }

  verwalterLoeschen(String mail, String institutionsId) async {
    var verwalter = await attemptGetUser(mail);
    var parsedVerwalter = json.decode(verwalter.body);
    var _map = parsedVerwalter.values.toList();
    if (_map[0] != false) {
      var _userId = _map[1]['id'].toString();

      var jwt = await attemptDeleteVerwalter(
          _userId, institutionsId, await getAccessToken());
      return jwt;
    }
    return null;
  }

  Future getVerwalteteInstitutionen() async {
    List _institutionen = [];
    var _accessToken = await getAccessToken();
    Response institutionen = await attemptGetVerwalteteInstitutionen(
        userId.toString(), _accessToken);

    if (institutionen.statusCode == 200) {
      _institutionen = json.decode(institutionen.body);
      return _institutionen;
    }
    return _institutionen;
  }

  Future getUngenehmigteInstitutionen() async {
    List _institutionen = [];
    var _accessToken = await getAccessToken();
    Response institutionen =
        await attemptGetUngenehmigteInstitutionen(_accessToken);

    if (institutionen.statusCode == 200) {
      _institutionen = json.decode(institutionen.body);
      return _institutionen;
    }
    return _institutionen;
  }

  institutionGenehmigen(String id) async {
    var institutionGenehmigen =
        await attemptApproveInstitution(id, await getAccessToken());
    if (institutionGenehmigen != null) {
      return institutionGenehmigen;
    } else {
      return null;
    }
  }

  institutionLoeschen(String id) async {
    var institutionLoeschen =
        await attemptDeleteInstitution(id, await getAccessToken());
    if (institutionLoeschen != null) {
      return institutionLoeschen;
    } else {
      return null;
    }
  }

  attemptImageForInstitution(File file, String institutionId) async {
    var jwt = await attemptNewImageForInstitution(
        file, institutionId, await getAccessToken());
    var parsedInstitutionsBild = json.decode(jwt.body);
    institutionBild = parsedInstitutionsBild['pfad'];
    notifyListeners();
    return jwt;
  }

  loadInstitutionImage() async {
    var jwt = await attemptGetFile(institutionBild);
    notifyListeners();
    return jwt;
  }

  setGenehmiger(String mail, List<String> plz) async {
    if (await setRole(mail, "genehmiger") != null) {
      var genehmiger = await attemptGetUser(mail);
      var parsedgenehmiger = json.decode(genehmiger.body);
      var _map = parsedgenehmiger.values.toList();
      if (_map[0] != false) {
        var _userId = _map[1]['id'].toString();

        var _accessToken = await getAccessToken();

        var jwt = await attemptSetGenehmiger(_userId, plz, _accessToken);
        notifyListeners();
        return jwt;
      }
    }
    return null;
  }

  removeGenehmiger(String mail, List<String> plz) async {
    if (await setRole(mail, "genehmiger") != null) {
      var genehmiger = await attemptGetUser(mail);
      var parsedgenehmiger = json.decode(genehmiger.body);
      var _map = parsedgenehmiger.values.toList();
      if (_map[0] != false) {
        var _userId = _map[1]['id'].toString();

        var _accessToken = await getAccessToken();

        var jwt = await attemptRemoveGenehmiger(_userId, plz, _accessToken);
        notifyListeners();
        return jwt;
      }
    }
    return null;
  }

  getGenehmigerPLZs(String userId) async {
    var jwt = await attemptGetPLZs(userId);
    if (jwt != null) {
      var _gene = await getGenehmigerPLZs(userId);
      genehmigerPLZs = _gene.join(",");
      print(genehmigerPLZs);
    } else {
      return null;
    }
  }

  deleteUser(String mail) async {
    var userToDelete = await attemptGetUser(mail);
    var parsedUser = json.decode(userToDelete.body);
    var _map = parsedUser.values.toList();
    if (_map[0] != false) {
      var _userId = _map[1]['id'].toString();
      var jwt = await attemptDeleteUser(_userId, await getAccessToken());
      return jwt;
    }
    return null;
  }

  checkDataCompletion() {
    if (vorname != null &&
        vorname != "null" &&
        nachname != null &&
        nachname != "null" &&
        tel != null &&
        tel != "null" &&
        strasse != null &&
        strasse != "null" &&
        hausnummer != null &&
        hausnummer != "null" &&
        plz != null &&
        plz != "null") {
      datenVollstaendig = true;
      return true;
    } else {
      datenVollstaendig = false;
      return false;
    }
  }
}
