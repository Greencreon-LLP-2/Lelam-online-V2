import 'package:flutter/material.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      width: double.infinity,
      child: ListView.separated(
        separatorBuilder: (context, index) {
          return SizedBox(width: 10);
        },
        itemCount: 10,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(child: Icon(Icons.castle_sharp)),
              ),
              SizedBox(height: 4),
              Text(
                'Cars',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          );
        },
      ),
    );
  }
}
