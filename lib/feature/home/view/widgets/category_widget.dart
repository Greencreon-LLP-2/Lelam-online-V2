import 'package:flutter/material.dart';
import 'package:lelamonline_flutter/feature/categories/pages/commercial/commercial_categories.dart';
import 'package:lelamonline_flutter/feature/categories/models/categories_model.dart';
import 'package:lelamonline_flutter/feature/categories/pages/other_category/other_categoty.dart';
import 'package:lelamonline_flutter/feature/categories/pages/real%20estate/real_estate_categories.dart';
import 'package:lelamonline_flutter/feature/categories/services/categories_service.dart';
import 'package:lelamonline_flutter/feature/categories/pages/user%20cars/used_cars_categorie.dart';

class CategoryWidget extends StatefulWidget {
  final String? userId;
  const CategoryWidget({super.key,this.userId});

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  late Future<List<CategoryModel>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = CategoryService().fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: FutureBuilder<List<CategoryModel>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found'));
          }

          final categories = snapshot.data!;

          return ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(width: 35),
            itemCount: categories.length,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final category = categories[index];
              return InkWell(
                onTap: () {
                  switch (category.id) {
                    case "1":
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UsedCarsPage(userId: widget.userId)),
                      );
                      break;
                    case "2":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RealEstatePage(userId: widget.userId),
                        ),
                      );
                      break;
                    case "3":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommercialVehiclesPage(userId: widget.userId),
                        ),
                      );
                      break;
                    case '4':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OthersPage(userId: widget.userId)),
                      );
                      break;
                    // case "4":
                    //   Navigator.push(context,
                    //       MaterialPageRoute(builder: (context) => ()));
                    //   break;
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(50),
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://lelamonline.com/admin/${category.image}',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 70,
                      child: Text(
                        category.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
