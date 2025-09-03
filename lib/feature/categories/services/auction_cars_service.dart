import 'dart:convert';
import 'package:http/http.dart' as http;

class AuctionService {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

  // Fetch bid history
  Future<List<Map<String, dynamic>>> fetchBidHistory(String postId) async {
    final url = '$baseUrl/auction-bid-history.php?token=$token&post_id=$postId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] is List) {
          return List<Map<String, dynamic>>.from(jsonResponse['data']);
        } else if (jsonResponse['data'] == 'No one yet placed a bid !') {
          return [];
        } else {
          throw Exception('Invalid bid history response');
        }
      } else {
        throw Exception('Failed to load bid history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bid history: $e');
      throw Exception('Error fetching bid history: $e');
    }
  }

  // Fetch minimum bid increment
  Future<int> fetchMinBidIncrement(String postId) async {
    final url = '$baseUrl/auction-increase-min-bid-value.php?token=$token&post_id=$postId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is int) {
          return jsonResponse['data'];
        } else {
          throw Exception('Invalid minimum bid increment response');
        }
      } else {
        throw Exception('Failed to load min bid increment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching min bid increment: $e');
      throw Exception('Error fetching min bid increment: $e');
    }
  }

  // Place a bid
  Future<bool> placeBid(String postId, String userId, int bidAmount) async {
    final url = '$baseUrl/auction-increase-min-bid.php?token=$token&post_id=$postId&user_id=$userId&bidamt=$bidAmount';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is List) {
          return jsonResponse['data'][0]['message'] == 'Your Bid Amount Successfully Placed.';
        } else {
          throw Exception('Invalid bid response');
        }
      } else {
        throw Exception('Failed to place bid: ${response.statusCode}');
      }
    } catch (e) {
      print('Error placing bid: $e');
      throw Exception('Error placing bid: $e');
    }
  }

  // Agree to bidding
  Future<bool> agreeToBidding(String postId, String userId) async {
    final url = '$baseUrl/auction-agree-bidding.php?token=$token&post_id=$postId&user_id=$userId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'true' && jsonResponse['data'] is List) {
          return jsonResponse['data'][0]['message'] == 'You Agree Bid and Procced Meeting also Product moved to Market place';
        } else {
          throw Exception('Invalid agree bidding response');
        }
      } else {
        throw Exception('Failed to agree to bidding: ${response.statusCode}');
      }
    } catch (e) {
      print('Error agreeing to bidding: $e');
      throw Exception('Error agreeing to bidding: $e');
    }
  }
}