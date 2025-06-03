// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/feature/status/view/widgets/selling_status/tab_bar_widget.dart';

class MyAdsWidget extends StatelessWidget {
  const MyAdsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for demonstration
    final ads = [
      {
        'status': 'Rejected',
        'views': 5271,
        'comments': 0,
        'title': 'Ashok Leyland Stile 8 seater',
        'appId': 'LAD-367',
        'postedDate': '19-04-2025',
        'expDate': '19-05-2025',
        'price': '0.00',
        'category': 'Used Cars',
        'itemIn': 'Market Place',
        'auctionAttempt': '0/3',
        'auctionPrice': 'xxxx*',
        'meetingsDone': '0',
        'location': 'Idukki',
        'image': null, // Replace with AssetImage or NetworkImage if available
        'rejectionMsg': 'Admin Rejected your post',
      },
      {
        'status': 'Rejected',
        'views': 644,
        'comments': 0,
        'title': 'For Sale Lands & Plots',
        'appId': 'LAD-368',
        'postedDate': '15-04-2025',
        'expDate': '15-05-2025',
        'price': '0.00',
        'category': 'Real estate',
        'itemIn': 'Market Place',
        'auctionAttempt': '0/3',
        'auctionPrice': 'xxxx*',
        'meetingsDone': '0',
        'location': 'Thrissur',
        'image': null, // Replace with AssetImage or NetworkImage if available
        'rejectionMsg': 'Admin Rejected your post',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: ads.length,
      itemBuilder: (context, index) {
        final ad = ads[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.95),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ad['status'] as String,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.remove_red_eye,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ad['views']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.comment, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${ad['comments']}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder
                    Container(
                      width: 110,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.brown.shade100,
                        borderRadius: BorderRadius.circular(8),
                        image:
                            ad['image'] != null
                                ? DecorationImage(
                                  image: ad['image'] as ImageProvider<Object>,
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          ad['image'] == null
                              ? const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.brown,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ad['title'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _adDetail('App ID', ad['appId'] as String),
                          _adDetail('Posted Date', ad['postedDate'] as String),
                          _adDetail('Exp Date', ad['expDate'] as String),
                          _adDetail(
                            'Price',
                            ad['price'] as String,
                            highlight: true,
                          ),
                          _adDetail('Category', ad['category'] as String),
                          _adDetail('Item In', ad['itemIn'] as String),
                          _adDetail(
                            'Auction Attempt',
                            ad['auctionAttempt'] as String,
                          ),
                          _adDetail(
                            'Auction Price',
                            ad['auctionPrice'] as String,
                          ),
                          _adDetail(
                            'Meetings Done',
                            ad['meetingsDone'] as String,
                          ),
                          _adDetail('Location', ad['location'] as String),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(
                          Icons.phone,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: const Text(
                          'Call Support',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                if (ad['rejectionMsg'] != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      ad['rejectionMsg'] as String,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                TabBarWidget(),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _adDetail(String label, String value, {bool highlight = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: highlight ? Colors.green : Colors.black87,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
