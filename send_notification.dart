import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/instance_manager.dart';

import '../data/constants/app_constants.dart';
import '../widgets/utilwidgets.dart';
import 'dio/endpoints.dart';
import 'storage.dart';

class SendNotification {
  // static Future<bool> sendFcmMessage(String title, String message) async {
  //   try {
  //     var url = 'https://fcm.googleapis.com/fcm/send';
  //     var header = {
  //       "Content-Type": "application/json",
  //       "Authorization": "key=${AppConstant.FCMSERVERKEY}",
  //     };
  //     /*  var request = {
  //       "notification": {
  //         "title": title,
  //         "text": message,
  //         "sound": "default",
  //         "color": "#990000",
  //       },
  //       "priority": "high",
  //       "to": "/topics/all",
  //     };*/
  //     var request = {
  //       'notification': {'title': title, 'body': message},
  //       'data': {
  //         'click_action': 'FLUTTER_NOTIFICATION_CLICK',
  //         'type': 'COMMENT'
  //       },
  //       "priority": "high",
  //       'to':
  //           'fHqcGfdXRUKQNHph5rBLcD:APA91bFMlW9p5YJi5vk1F30SaAVH2bqr34oHU44jIZcDeQhdaFgZhL1t6MstcCN5AzyOgWaOd_LetDbqwHXAtMK5ogo5AH_dL5cdv9v3MZRFcE0aDhFI5HbcNobk_B2onapTDKundZhG'
  //     };

  //     var client = new Client();
  //     var response = await client.post(Uri.parse(url),
  //         headers: header, body: json.encode(request));
  //     return true;
  //   } catch (e, s) {
  //     print(e);
  //     return false;
  //   }
  // }

  static Future<bool> sendTopicNotification(
      String title, String message, String topic,
      {String type = 'videocall'}) async {
    var request = {
      'notification': {
        'title': title,
        'body': message,
        "sound": "default",
        "color": "#990000",
      },
      'data': {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'notification_type': type,
        'senderId': Get.find<GetStorageService>().userId,
        "name": Get.find<GetStorageService>().userName,
        'receiverId': topic,
      },
      "priority": "high",
      'to': '/topics/$topic'
    };
    UtilWidgets.showLoading();
    Dio temp = Dio();
    temp
      ..options.headers = {
        "Content-Type": "application/json",
        "Authorization": AppConstant.FCMSERVERKEY,
      }
      ..options.connectTimeout =
          const Duration(seconds: Endpoints.CONNECTIONTIMEOUT)
      ..options.receiveTimeout =
          const Duration(seconds: Endpoints.CONNECTIONTIMEOUT)
      ..options.responseType = ResponseType.json;

    try {
      final Response response = await temp.post(
        "https://fcm.googleapis.com/fcm/send",
        data: jsonEncode(request),
      );
      UtilWidgets.hideLoading();

      return response.statusCode == 200 || response.statusCode == 201
          ? true
          : false;
    } catch (e) {
      debugPrint(e.toString());
      UtilWidgets.hideLoading();
      return false;
    }
  }
}
