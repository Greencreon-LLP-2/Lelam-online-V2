import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:shimmer/shimmer.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({super.key});

  Future<String?> fetchBannerUrl() async {
    final uri = Uri.parse(banner);

    final request = http.Request('GET', uri);
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
          return _buildShimmerBanner();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildContainer(child: const Text("No banner available"));
        }

        return _buildContainer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => _buildShimmerBanner(),
              errorWidget:
                  (context, url, error) => const Text("Failed to load banner"),
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

  Widget _buildShimmerBanner() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
