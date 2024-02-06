import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:yogtrackteacher/app/services/storage.dart';
import 'package:yogtrackteacher/app/widgets/utilwidgets.dart';

class SocialLogin {
  late GoogleSignIn _googleSign;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  GoogleSignInAccount? _currentUser;
  SocialLogin() {
    onInit();
  }
  void onInit() async {
    _googleSign = GoogleSignIn();

    _googleSign.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (_currentUser != null) {
        // handleGetContact(
        //     Id: _currentUser!.id.toString(),
        //     fullName: _currentUser!.displayName.toString(),
        //     email: _currentUser!.email.toString(),
        //     photoUrl: _currentUser!.photoUrl.toString(),
        //     phoneNumber: "");
      }
    });
    _googleSign.signInSilently();
  }

  Future<bool> googleLogin() async {
    bool isLoggedIn = false;
    UtilWidgets.showLoading();
    try {
      GoogleSignInAccount? googleSignInAccount = await _googleSign.signIn();
      if (googleSignInAccount == null) {
      } else {
        GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        OAuthCredential oAuthCredential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken);
        await _firebaseAuth
            .signInWithCredential(oAuthCredential)
            .then((value) async {
          Get.find<GetStorageService>().firebaseUid = value.user!.uid;
          isLoggedIn = true;
        });

        // handleGetContact(
        //     Id: googleSignInAccount.id.toString(),
        //     fullName: googleSignInAccount.displayName.toString(),
        //     email: googleSignInAccount.email.toString(),
        //     photoUrl: googleSignInAccount.photoUrl.toString(),
        //     phoneNumber: "");
      }
    } catch (e) {
      UtilWidgets.hideLoading();

      UtilWidgets.showToast(message: e.toString());
      isLoggedIn = false;
    } finally {
      UtilWidgets.hideLoading();
    }
    return isLoggedIn;
  }

  Future<void> loginWithPhone(
      {required String number,
      required void Function(String verificationId, int? forceResendingToken)
          codeSent}) async {
    // String verifyId = "";
    UtilWidgets.showLoading();
    try {
      await _firebaseAuth.verifyPhoneNumber(
          phoneNumber: number,
          // PHONE NUMBER TO SEND OTP
          codeAutoRetrievalTimeout: (String verId) {
            //Starts the phone number verification process for the given phone number.
            //Either sends an SMS with a 6 digit code to the phone number specified, or sign's the user in and [verificationCompleted] is called.
          },
          codeSent: (verificationId, forceResendingToken) {
            UtilWidgets.hideLoading();
            codeSent(verificationId, forceResendingToken);
          },
          // WHEN CODE SENT THEN WE OPEN DIALOG TO ENTER OTP.
          timeout: const Duration(seconds: 120),
          verificationCompleted: (AuthCredential phoneAuthCredential) {
            UtilWidgets.hideLoading();
          },
          verificationFailed: (error) {
            UtilWidgets.hideLoading();
            UtilWidgets.showToast(
                message: error.message.toString(), isError: true);
          });
    } catch (e) {
      UtilWidgets.hideLoading();
      UtilWidgets.showToast(message: e.toString(), isError: true);
    }
  }

  Future<bool> verifyOTP(
      {required String smsCode,
      required String verificationId,
      required String phoneNumber}) async {
    UtilWidgets.showLoading();
    bool verified = false;
    try {
      var firebaseAuth1 = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      await _firebaseAuth
          .signInWithCredential(firebaseAuth1)
          .then((value) async {
        if (value.user != null) {
          Get.find<GetStorageService>().firebaseUid = value.user!.uid;

          verified = true;
        } else {
          UtilWidgets.showToast(message: "Entered Otp is wrong", isError: true);
        }
      });
    } catch (e) {
      UtilWidgets.hideLoading();
      UtilWidgets.showToast(message: e.toString(), isError: true);
    } finally {
      UtilWidgets.hideLoading();
    }
    return verified;
  }

  Future signInWithFacebook(
      {required Function(UserCredential? userCredential) onSuccess,
      required Function() onFailed,
      required Function(Object error) onError}) async {
    try {
      UtilWidgets.showLoading();
      final LoginResult result =
          await FacebookAuth.instance.login(permissions: ['email']);

      if (result.status == LoginStatus.success) {
        final AuthCredential facebookCredential =
            FacebookAuthProvider.credential(result.accessToken!.token);
        await FirebaseAuth.instance
            .signInWithCredential(facebookCredential)
            .then((userCredential) => onSuccess(userCredential));
      } else {
        onFailed();
      }
    } catch (e) {
      onError(e);
    } finally {
      UtilWidgets.hideLoading();
    }
  }

  // Future signInWithApple(
  //     {required Function(UserCredential? userCredential) onSuccess,
  //     required Function(Object error) onError}) async {
  //   // To prevent replay attacks with the credential returned from Apple, we
  //   // include a nonce in the credential request. When signing in with
  //   // Firebase, the nonce in the id token returned by Apple, is expected to
  //   // match the sha256 hash of `rawNonce`.

  //   try {
  //     final rawNonce = generateNonce();
  //     final nonce = sha256ofString(rawNonce);

  //     // Request credential for the currently signed in Apple account.
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //       nonce: nonce,
  //     );

  //     // Create an `OAuthCredential` from the credential returned by Apple.
  //     final oauthCredential = OAuthProvider("apple.com").credential(
  //       idToken: appleCredential.identityToken,
  //       rawNonce: rawNonce,
  //     );

  //     // Sign in the user with Firebase. If the nonce we generated earlier does
  //     // not match the nonce in `appleCredential.identityToken`, sign in will fail.
  //     onSuccess(
  //         await FirebaseAuth.instance.signInWithCredential(oauthCredential));
  //     // userCreds =
  //     //     await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  //   } catch (e) {
  //     onError(e);
  //   }
  // }

  // String sha256ofString(String input) {
  //   final bytes = utf8.encode(input);
  //   final digest = sha256.convert(bytes);
  //   return digest.toString();
  // }
}
