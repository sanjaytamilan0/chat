import 'dart:convert';

import 'package:http/http.dart' as http;

class Service{
  Future<void> sendNotification(String title,String discription) async {
    const String restapiKey = 'os_v2_app_cizjsc4gtzd6fcby34nsaa4mdjnq72cbs7fedru6jxl4gmjvgkso4ahy6itm32s5egipoym5wlxlb5ew2n4i3thvmbnqmmvo52x6a5a';
    const String url = 'https://api.onesignal.com/notifications';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Basic $restapiKey"
        },
        body: jsonEncode({
          "app_id": '1232990b-869e-47e2-8838-df1b20038c1a',
          "contents": {
            "en": discription,
            "es": "Spanish Message"
          },
          "buttons": [
            {
              "id": "reply_button",
              "text": "Reply",
              "icon": "icon_url_here"
            }
          ],
          // "url": "https://yourwebsite.com/reply",
          // "include_player_ids": ["PLAYER_ID_1", "PLAYER_ID_2"],


          "included_segments": [
            'Total Subscriptions',
            "Active Users",
            // "Inactive Users"
          ],

          "headings": {
            "en": "next Task is: $title",
            "es": "Este es el encabezado en español"
          }
        }),
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        print('Notification sent successfully!');
      } else {
        print('Error sending notification. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // This will catch network-related issues, or any other exception
      print('Exception occurred: $e');
    }
  }
}
