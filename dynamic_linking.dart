import 'package:flutter/cupertino.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:yogtrackteacher/app/data/constants/app_constants.dart';
import 'package:yogtrackteacher/app/services/app_services.dart';

class DynamicLink {
  static Future<void> initDynamicLinks() async {
    try {
      await Future.delayed(const Duration(seconds: 3));
      debugPrint("DynamicLink Service Started");

      var data = await FirebaseDynamicLinks.instance.getInitialLink();
      Uri? deepLink = data?.link;
      if (deepLink != null) {
        AppServices.onLinkingAction(deepLink: deepLink);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    FirebaseDynamicLinks.instance.onLink.listen((dynamicLinkData) {
      // ignore: unnecessary_nullable_for_final_variable_declarations
      final Uri? deepLink = dynamicLinkData.link;
      if (deepLink != null) {
        AppServices.onLinkingAction(deepLink: deepLink);
      }
    }).onError((error) {
      debugPrint('onLink error');
      debugPrint(error.message.toString());
    });
  }

  static Future<void> createDynamicLink(
      {bool shortUrl = true,
      String path = AppConstant.REFERRAL,
      String queryParam = AppConstant.REFERRALQUERY,
      required String value,
      required Function(String url) onSucess,
      Function(Object e)? onError}) async {
    try {
      FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;
      final DynamicLinkParameters parameters = DynamicLinkParameters(
        uriPrefix: AppConstant.DYNAMICLINK,
        link: Uri.parse('${AppConstant.DYNAMICLINK}$path?$queryParam=$value'),
        androidParameters: const AndroidParameters(
          packageName: AppConstant.PKGNAME,
          minimumVersion: 0,
        ),
        iosParameters: const IOSParameters(
          bundleId: AppConstant.PKGNAME,
          minimumVersion: '1',
          appStoreId: AppConstant.APPSTOREID,
        ),
      );

      Uri url;
      if (shortUrl) {
        final ShortDynamicLink shortLink =
            await dynamicLinks.buildShortLink(parameters);
        url = shortLink.shortUrl;
      } else {
        url = await dynamicLinks.buildLink(parameters);
      }
      onSucess(url.toString());
    } catch (e) {
      onError!(e.toString());
    }
  }
}
