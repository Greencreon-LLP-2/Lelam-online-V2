import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  Future<String?> fetchBannerUrl() async {
    const token = '5cb2c9b569416b5db1604e0e12478ded';
    final headers = {
      'token': token,
      'Cookie': 'PHPSESSID=koib3m1uifk1b4ucclf5dsegpe',
    };

    final uri = Uri.parse(
      'https://lelamonline.com/admin/api/v1/banner.php?token=$token',
    );

    final request = http.Request('GET', uri)..headers.addAll(headers);
    final response = await request.send();

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (json['status'] == "true" &&
          json['data'] is List &&
          json['data'].isNotEmpty) {
        return "https://lelamonline.com/admin/${json['data'][0]['image']}";
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: fetchBannerUrl(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildContainer(child: const CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildContainer(child: const Text("No banner available"));
        }

        return _buildContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: child,
    );
  }
}
