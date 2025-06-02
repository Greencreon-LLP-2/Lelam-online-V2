import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/banner_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/category_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/product_section_widget.dart';
import 'package:lelamonline_flutter/feature/home/view/widgets/search_button_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              //!TOP section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    //!Location section
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        Text('Location'),
                      ],
                    ),
                    Spacer(),
                    //!Notification section
                    IconButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.notificationPage);
                      },
                      icon: Icon(Icons.notifications),
                    ),
                  ],
                ),
              ),
              //!Search section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchButtonWidget(),
              ),

              //!Banner section
              BannerWidget(),

              //!Category section
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: CategoryWidget(),
              ),

              //!Product section
              ProductSectionWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
