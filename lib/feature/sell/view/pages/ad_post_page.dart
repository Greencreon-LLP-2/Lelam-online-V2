import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lelamonline_flutter/core/api/api_constant.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/service/api_service.dart';
import 'package:lelamonline_flutter/core/service/logged_user_provider.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/custom_dropdown_widget.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/image_source_bottom_sheet.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/text_field_widget.dart';
import 'package:lelamonline_flutter/utils/palette.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;

class Brand {
  final String id;
  final String slug;
  final String categoryId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  Brand({
    required this.id,
    required this.slug,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

class BrandModel {
  final String id;
  final String brandId;
  final String slug;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  BrandModel({
    required this.id,
    required this.brandId,
    required this.slug,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: json['id']?.toString() ?? '',
      brandId: json['brand_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

class ModelVariation {
  final String id;
  final String slug;
  final String brandId;
  final String brandModelId;
  final String name;
  final String image;
  final String status;
  final String createdOn;
  final String updatedOn;

  ModelVariation({
    required this.id,
    required this.slug,
    required this.brandId,
    required this.brandModelId,
    required this.name,
    required this.image,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory ModelVariation.fromJson(Map<String, dynamic> json) {
    return ModelVariation(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      brandId: json['brand_id']?.toString() ?? '',
      brandModelId: json['brands_model_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

class Attribute {
  final String id;
  final String slug;
  final String name;
  final String listOrder;
  final String categoryId;
  final String formValidation;
  final String showFilter;
  final String status;
  final String createdOn;
  final String updatedOn;

  Attribute({
    required this.id,
    required this.slug,
    required this.name,
    required this.listOrder,
    required this.categoryId,
    required this.formValidation,
    required this.showFilter,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory Attribute.fromJson(Map<String, dynamic> json) {
    return Attribute(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      listOrder: json['list_order']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      formValidation: json['form_validation']?.toString() ?? '',
      showFilter: json['show_filter']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

class AttributeVariation {
  final String id;
  final String attributeId;
  final String name;
  final String status;
  final String createdOn;
  final String updatedOn;

  AttributeVariation({
    required this.id,
    required this.attributeId,
    required this.name,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  });

  factory AttributeVariation.fromJson(Map<String, dynamic> json) {
    return AttributeVariation(
      id: json['id']?.toString() ?? '',
      attributeId: json['attribute_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdOn: json['created_on']?.toString() ?? '',
      updatedOn: json['updated_on']?.toString() ?? '',
    );
  }
}

class AttributeValueService {
  static const String baseUrl = 'https://lelamonline.com/admin/api/v1';
  static const String token = '5cb2c9b569416b5db1604e0e12478ded';

  static Future<List<Map<String, dynamic>>> fetchDistricts() async {
    try {
      final headers = {
        'token': token,
        'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
      };
      final request = http.Request(
        'GET',
        Uri.parse('$baseUrl/list-district.php?token=$token'),
      );
      request.headers.addAll(headers);
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        print('Districts API response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        print('No districts found');
        return [
          {
            "id": "1",
            "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
            "parent_id": "0",
            "name": "Thiruvananthapuram",
            "image": "",
            "description": "",
            "latitude": "",
            "longitude": "",
            "popular": "0",
            "status": "1",
            "allstore_onoff": "1",
            "created_on": "2024-12-04 10:58:13",
            "updated_on": "2024-12-04 11:06:32",
          },
        ];
      }
      print('Failed to fetch districts: ${response.statusCode} $responseBody');
      return [
        {
          "id": "1",
          "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
          "parent_id": "0",
          "name": "Thiruvananthapuram",
          "image": "",
          "description": "",
          "latitude": "",
          "longitude": "",
          "popular": "0",
          "status": "1",
          "allstore_onoff": "1",
          "created_on": "2024-12-04 10:58:13",
          "updated_on": "2024-12-04 11:06:32",
        },
      ];
    } catch (e) {
      print('Error fetching districts: $e');
      return [
        {
          "id": "1",
          "slug": "thiruvananthapuram-bwmuosmfkfdc2g2",
          "parent_id": "0",
          "name": "Thiruvananthapuram",
          "image": "",
          "description": "",
          "latitude": "",
          "longitude": "",
          "popular": "0",
          "status": "1",
          "allstore_onoff": "1",
          "created_on": "2024-12-04 10:58:13",
          "updated_on": "2024-12-04 11:06:32",
        },
      ];
    }
  }

  static Future<List<Brand>> fetchBrands(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/list-brand.php?token=$token&category_id=$categoryId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Brands API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final brands =
              (data['data'] as List)
                  .map((e) => Brand.fromJson(e))
                  .where((brand) => brand.categoryId == categoryId)
                  .toList();
          print(
            'Filtered brands for category_id $categoryId: ${brands.map((b) => b.name).toList()}',
          );
          return brands;
        }
        print('No brands found for category_id: $categoryId');
        return [];
      }
      print('Failed to fetch brands: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching brands: $e');
      return [];
    }
  }

  static Future<List<BrandModel>> fetchBrandModels(
    String brandId,
    String categoryId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/list-model.php?token=$token&brand_id=$brandId&category_id=$categoryId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          'Brand models API response for brand_id $brandId, category_id $categoryId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          final models =
              (data['data'] as List)
                  .map((e) => BrandModel.fromJson(e))
                  .toList();
          print('Fetched brand models: ${models.map((m) => m.name).toList()}');
          return models;
        }
        print(
          'No brand models found for brand_id: $brandId, category_id: $categoryId',
        );
        return [];
      }
      print(
        'Failed to fetch brand models: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      print('Error fetching brand models: $e');
      return [];
    }
  }

  static Future<List<ModelVariation>> fetchModelVariations(
    String brandModelId,
    String categoryId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/list-model-variations.php?token=$token&brands_model_id=$brandModelId&category_id=$categoryId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          'Model variations API response for brands_model_id $brandModelId, category_id $categoryId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          final variations =
              (data['data'] as List)
                  .map((e) => ModelVariation.fromJson(e))
                  .toList();
          print('Model variations IDs: ${variations.map((v) => v.id).toSet()}');
          print(
            'Model variations names: ${variations.map((v) => v.name).toSet()}',
          );
          return variations;
        }
        print(
          'No model variations found for brands_model_id: $brandModelId, category_id: $categoryId',
        );
        return [];
      }
      print(
        'Failed to fetch model variations: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      print('Error fetching model variations: $e');
      return [];
    }
  }

  static Future<List<Attribute>> fetchAttributes(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/filter-attribute.php?token=$token&category_id=$categoryId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Attributes API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => Attribute.fromJson(e))
              .toList();
        }
        print('No attributes found for category_id: $categoryId');
        return [];
      }
      print(
        'Failed to fetch attributes: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      print('Error fetching attributes: $e');
      return [];
    }
  }

  static Future<List<AttributeVariation>> fetchAttributeVariations(
    String attributeId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/filter-attribute-variations.php?token=$token&attribute_id=$attributeId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(
          'Attribute variations API response for attribute_id $attributeId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => AttributeVariation.fromJson(e))
              .toList();
        }
        print('No variations found for attribute_id: $attributeId');
        return [];
      }
      print(
        'Failed to fetch attribute variations: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      print(
        'Error fetching attribute variations for attribute_id $attributeId: $e',
      );
      return [];
    }
  }
}

class AdPostPage extends StatefulWidget {
  final Map<String, dynamic>? extra;
  const AdPostPage({super.key, this.extra});

  @override
  State<AdPostPage> createState() => _AdPostPageState();
}

class _AdPostPageState extends State<AdPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _adPostFormKey = GlobalKey<_AdPostFormState>();
  String? _categoryId;
  String? _postId;
  Map<String, dynamic>? _adData;
  late final LoggedUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    if (widget.extra != null) {
      _categoryId = widget.extra!['categoryId']?.toString();
      _postId = widget.extra!['postId']?.toString();
      _adData = widget.extra!['adData'] as Map<String, dynamic>?;
      if (_categoryId == null) {
        showToast('Invalid category ID', Colors.red);
      }
      if (_postId != null && _adData == null) {
        showToast('Ad data is missing for editing', Colors.red);
      }
    }
    if (_postId != null) {
      _fetchGalleryImages(_postId!);
    } else {}
  }

  void showToast(String msg, Color color) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  void _submitForm() {
    print('AdPostPage _submitForm called');
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _adPostFormKey.currentState?._submitForm();
    }
  }

  Future<void> _fetchGalleryImages(String postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/post-gallery.php?token=$token&post_id=$postId'),
        headers: {'token': token},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Gallery API response: $responseData');
        if (responseData['status'] == 'true' && responseData['data'] is List) {
          setState(() {
            if (_adData == null) _adData = {};
            _adData!['gallery_images'] = List<Map<String, dynamic>>.from(
              responseData['data'],
            );
          });
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to fetch gallery images',
          );
        }
      } else {
        throw Exception(
          'Failed to fetch gallery images: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error fetching gallery images: $e');
      // showToast('Failed to load gallery images', Colors.red);
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[50],
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: Text(
        _adData != null ? 'Update Post' : 'Add Post',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Palette.primaryblue,
              ),
            ),
          ),
        ),
      ],
    ),
    body: AdPostForm(
      key: _adPostFormKey,
      formKey: _formKey,
      categoryId: _categoryId ?? '',
      userId: _userProvider.userId!,
      postId: _postId,
      adData: _adData,
      onSubmit: _submitForm,
      isSaving: _adPostFormKey.currentState?.isSaving ?? false,
    ),
  );
}
}

class AdPostForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String categoryId, userId;
  final String? postId;
  final Map<String, dynamic>? adData;
  final VoidCallback onSubmit;
  final bool isSaving;

  const AdPostForm({
    Key? key,
    required this.formKey,
    required this.categoryId,
    required this.userId,
    this.postId,
    this.adData,
    required this.onSubmit,
    required this.isSaving,
  }) : super(key: key);

  @override
  State<AdPostForm> createState() => _AdPostFormState();
}

class _AdPostFormState extends State<AdPostForm>
    with SingleTickerProviderStateMixin {
  bool isSaving = false;
  List<Brand> _brands = [];
  List<BrandModel> _brandModels = [];
  List<ModelVariation> _modelVariations = [];
  List<Map<String, dynamic>> _districts = [];
  Brand? _selectedBrand;
  BrandModel? _selectedBrandModel;
  ModelVariation? _selectedModelVariation;
  Map<String, String?> _selectedAttributes = {};
  final _controllers = {
    'description': TextEditingController(),
    'listPrice': TextEditingController(),
    'district': TextEditingController(),
    'landMark': TextEditingController(),
    'registration': TextEditingController(),
    'insurance': TextEditingController(),
  };
  final Map<String, List<AttributeVariation>> _attributeVariations = {};
  Map<String, String> _attributeIdMap = {};
  List<Attribute> _attributes = [];
  final List<XFile> _selectedImages = [];
  final List<Map<String, dynamic>> _existingImages = []; // Store id and path
  final List<String> _deleteGalleryIds = [];
  final _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _imageError = false;
  final int _maxImages = 10;
  int _coverImageIndex = 0;
  final Map<String, TextEditingController> _attributeControllers = {};
  String? _selectedDistrict;

  List<String> _getRequiredAttributes() => switch (widget.categoryId) {
    '1' => [
      'Year',
      'No of owners',
      'Fuel Type',
      'Transmission',
      'KM Range',
      'Sold by',
    ],
    '2' => ['Plot Area', 'Facing', 'Listed By'],
    _ => [],
  };

  void _showToast(String msg, Color color) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color.withOpacity(0.8),
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  String _generateTitle() =>
      '${_selectedBrand?.name ?? 'Unknown Brand'} ${_selectedBrandModel?.name ?? 'Unknown Model'}'
          .trim();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
    _animationController.forward();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    if (widget.categoryId.isEmpty) {
      _showToast("post your ad", const Color.fromARGB(255, 82, 244, 54));
      return;
    }

    setState(() {
      _brands = [];
      _brandModels = [];
      _modelVariations = [];
      _districts = [];
      _selectedBrand = _selectedBrandModel = _selectedModelVariation = null;
      _attributes = [];
      _attributeVariations.clear();
      _attributeIdMap = {};
      _selectedAttributes = {};
      _attributeControllers.clear();
      _existingImages.clear();
      _deleteGalleryIds.clear();
    });

    if (widget.adData != null) {
      final ad = widget.adData!;
      _controllers['listPrice']!.text = ad['price']?.toString() ?? '';
      _controllers['description']!.text = ad['description']?.toString() ?? '';
      _controllers['landMark']!.text = ad['land_mark']?.toString() ?? '';
      _controllers['registration']!.text =
          ad['registration_valid_till']?.toString() ?? '';
      _controllers['insurance']!.text = ad['insurance_upto']?.toString() ?? '';
      _selectedDistrict =
          ad['district']?.toString() ??
          (_districts.isNotEmpty ? _districts[0]['name'] : null);
      _coverImageIndex = ad['coverImageIndex']?.toInt() ?? 0;
      await _loadImages(ad);
    }

    _districts = [
      {
        'id': '0',
        'name': 'All Kerala',
        'slug': 'all-kerala',
        'parent_id': '0',
        'image': '',
        'description': '',
        'latitude': '',
        'longitude': '',
        'popular': '0',
        'status': '1',
        'allstore_onoff': '1',
        'created_on': '',
        'updated_on': '',
      },
      ...await AttributeValueService.fetchDistricts(),
    ];
    _brands = await AttributeValueService.fetchBrands(widget.categoryId);
    setState(() {
      _selectedDistrict ??= 'District';
      _districts.isNotEmpty ? _districts[0]['name'] : null;
      if (widget.adData?['brand'] != null) {
        _selectedBrand = _brands.firstWhere(
          (b) => b.id == widget.adData!['brand'],
          orElse:
              () => Brand(
                id: '',
                slug: '',
                categoryId: '',
                name: '',
                image: '',
                status: '',
                createdOn: '',
                updatedOn: '',
              ),
        );
        if (_selectedBrand!.id.isEmpty) _selectedBrand = null;
      }
    });

    if (_selectedBrand != null) {
      _brandModels = await AttributeValueService.fetchBrandModels(
        _selectedBrand!.id,
        widget.categoryId,
      );
      setState(() {
        if (widget.adData?['model'] != null) {
          _selectedBrandModel = _brandModels.firstWhere(
            (m) => m.id == widget.adData!['model'],
            orElse:
                () => BrandModel(
                  id: '',
                  brandId: '',
                  slug: '',
                  name: '',
                  image: '',
                  status: '',
                  createdOn: '',
                  updatedOn: '',
                ),
          );
          if (_selectedBrandModel!.id.isEmpty) _selectedBrandModel = null;
        }
      });

      if (_selectedBrandModel != null) {
        final variations = await AttributeValueService.fetchModelVariations(
          _selectedBrandModel!.id,
          widget.categoryId,
        );
        _modelVariations = variations.toSet().toList();
        setState(() {
          if (widget.adData?['model_variation'] != null) {
            _selectedModelVariation = _modelVariations.firstWhere(
              (v) => v.id == widget.adData!['model_variation'],
              orElse:
                  () => ModelVariation(
                    id: '',
                    slug: '',
                    brandId: '',
                    brandModelId: '',
                    name: '',
                    image: '',
                    status: '',
                    createdOn: '',
                    updatedOn: '',
                  ),
            );
            if (_selectedModelVariation!.id.isEmpty)
              _selectedModelVariation = null;
          }
        });
      }
    }

    _attributes = await AttributeValueService.fetchAttributes(
      widget.categoryId,
    );
    setState(() {
      _attributeIdMap = {for (var attr in _attributes) attr.name: attr.id};
      _selectedAttributes = {for (var attr in _attributes) attr.name: null};
      _attributeControllers.addAll({
        for (var attr in _attributes) attr.name: TextEditingController(),
      });
      if (widget.adData?['filters'] != null) {
        try {
          final filters =
              jsonDecode(widget.adData!['filters'] as String)
                  as Map<String, dynamic>;
          for (var attr in _attributes) {
            if (filters[attr.id]?.isNotEmpty ?? false) {
              _selectedAttributes[attr.name] = filters[attr.id][0].toString();
            }
          }
        } catch (e) {
          print('Error parsing filters: $e');
        }
      }
    });

    for (var attr in _attributes) {
      final variations = await AttributeValueService.fetchAttributeVariations(
        attr.id,
      );
      setState(() {
        _attributeVariations[attr.name] = variations;
        if (_selectedAttributes[attr.name] != null) {
          final variation = variations.firstWhere(
            (v) => v.id == _selectedAttributes[attr.name],
            orElse:
                () => AttributeVariation(
                  id: '',
                  attributeId: attr.id,
                  name: _selectedAttributes[attr.name] ?? '',
                  status: '',
                  createdOn: '',
                  updatedOn: '',
                ),
          );
          _selectedAttributes[attr.name] =
              variation.name.isNotEmpty
                  ? variation.name
                  : _selectedAttributes[attr.name];
          _attributeControllers[attr.name]?.text =
              _selectedAttributes[attr.name] ?? '';
        }
      });
    }
  }

  Future<void> _loadImages(Map<String, dynamic> ad) async {
    setState(() {
      _existingImages.clear();
      _selectedImages.clear();
      _deleteGalleryIds.clear(); // Clear to avoid stale IDs
    });

    // Handle main image
    if (ad['image']?.isNotEmpty ?? false) {
      String imageUrl = ad['image'];
      if (!imageUrl.startsWith('http')) {
        imageUrl =
            '$getImagePostImageUrl${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
      }
      _existingImages.add({'id': null, 'path': imageUrl, 'isMain': true});
      print('Loaded main image: $imageUrl');
    }

    // Handle gallery images
    if (ad['gallery_images']?.isNotEmpty ?? false) {
      _existingImages.addAll(
        (ad['gallery_images'] as List).map(
          (img) => {
            'id': img['id']?.toString(),
            'path':
                img['image'].startsWith('http')
                    ? img['image']
                    : '$getImagePostImageUrl${img['image'].startsWith('/') ? img['image'].substring(1) : img['image']}',
            'isMain': false,
          },
        ),
      );
      print(
        'Loaded gallery images: ${_existingImages.where((img) => !img['isMain']).map((e) => 'ID: ${e['id']}, Path: ${e['path']}').toList()}',
      );
    } else {
      print('No gallery images found in adData');
    }

    for (var img in _existingImages) {
      try {
        final response = await http.get(
          Uri.parse(img['path']),
          headers: {'token': AttributeValueService.token},
        );
        if (response.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          final file = File(
            '${tempDir.path}/ad_${img['id'] ?? 'main'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          await file.writeAsBytes(response.bodyBytes);
          _selectedImages.add(XFile(file.path));
          print('Downloaded image: ${img['path']}');
        } else {
          print(
            'Failed to download image: ${img['path']}, status: ${response.statusCode}',
          );
        }
      } catch (e) {
        print('Error downloading image ${img['path']}: $e');
      }
    }

    setState(() {
      if (_coverImageIndex >= _selectedImages.length) _coverImageIndex = 0;
      if (_selectedImages.isEmpty && _existingImages.isNotEmpty) {
        _showSnackBar('Failed to load some images', Colors.orange);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      _showSnackBar('Maximum $_maxImages images allowed', Colors.red);
      return;
    }
    try {
      if (source == ImageSource.camera) {
        final image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
            _imageError = false;
            if (_selectedImages.length == 1) _coverImageIndex = 0;
          });
        }
      } else {
        final images = await _imagePicker.pickMultiImage(imageQuality: 80);
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(
              images.take(_maxImages - _selectedImages.length),
            );
            _imageError = false;
            if (_selectedImages.length == images.length) _coverImageIndex = 0;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ImageSourceBottomSheetWidget(
            onCameraTap: () => _pickImage(ImageSource.camera),
            onGalleryTap: () => _pickImage(ImageSource.gallery),
          ),
    );
  }

  Map<String, List<String>> getFilters() {
    final filters = <String, List<String>>{};
    _selectedAttributes.forEach((attrName, value) {
      if (value != null && value.isNotEmpty) {
        final variations = _attributeVariations[attrName];
        final variation =
            variations?.firstWhere(
              (v) => v.name == value,
              orElse:
                  () => AttributeVariation(
                    id: '',
                    attributeId: _attributeIdMap[attrName] ?? '',
                    name: value,
                    status: '',
                    createdOn: '',
                    updatedOn: '',
                  ),
            ) ??
            AttributeVariation(
              id: '',
              attributeId: _attributeIdMap[attrName] ?? '',
              name: value,
              status: '',
              createdOn: '',
              updatedOn: '',
            );
        filters[_attributeIdMap[attrName] ?? ''] = [
          variation.id.isNotEmpty ? variation.id : value,
        ];
      }
    });
    if (widget.categoryId == '1') {
      if (_controllers['registration']!.text.isNotEmpty) {
        filters[_attributeIdMap['Registration valid till'] ?? '27'] = [
          _controllers['registration']!.text,
        ];
      }
      if (_controllers['insurance']!.text.isNotEmpty) {
        filters[_attributeIdMap['Insurance Upto'] ?? '28'] = [
          _controllers['insurance']!.text,
        ];
      }
    }
    return filters;
  }

  Future<void> _submitForm() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select at least 1 image', Colors.red);
      return;
    }

    if (widget.categoryId == '1' || widget.categoryId == '2') {
      if (_selectedBrand == null || _selectedBrandModel == null) {
        _showSnackBar('Please select Category/Brand', Colors.red);
        return;
      }
    }
    if (widget.categoryId == '3') {
      if (_controllers['listPrice']!.text.isEmpty) {
        _showSnackBar('Please provide listing price', Colors.red);
        return;
      }
      if (_brandModels.isNotEmpty && _selectedBrand == null) {
        _showSnackBar('Please select a Brand Type', Colors.red);
        return;
      }
      if (_selectedBrandModel == null) {
        _showSnackBar('Please select Sale/rent type from Brand', Colors.red);
        return;
      }
    }
    if (widget.categoryId == '4' && _selectedBrand == null) {
      if (_controllers['listPrice']!.text.isEmpty) {
        _showSnackBar('Please provide listing price', Colors.red);
        return;
      }
      _showSnackBar('Please select Sale/rent type from Model', Colors.red);
      return;
    }

    final requiredAttributes = _getRequiredAttributes();
    final missingAttributes =
        requiredAttributes
            .where((attr) => _selectedAttributes[attr]?.isEmpty ?? true)
            .toList();

    if (missingAttributes.isNotEmpty) {
      _showSnackBar(
        'Please provide values for: ${missingAttributes.join(", ")}',
        Colors.red,
      );
      return;
    }

    final filters = getFilters();
    final formData = {
      'user_id': widget.userId,
      'title': _generateTitle(),
      'category_id': widget.categoryId,
      'brand': _selectedBrand?.id ?? '',
      'model': _selectedBrandModel?.id ?? '',
      'model_variation': _selectedModelVariation?.id ?? '',
      'description': _controllers['description']?.text ?? '',
      'price': _controllers['listPrice']!.text,
      'filters': jsonEncode(filters),
      'parent_zone_id':
          _districts
              .firstWhere(
                (d) => d['name'] == _selectedDistrict,
                orElse: () => {'id': ''},
              )['id']
              ?.toString() ??
          '',
      'land_mark': _controllers['landMark']!.text,
      if (widget.categoryId == '1') ...{
        'registration_valid_till': _controllers['registration']!.text,
        'insurance_upto': _controllers['insurance']!.text,
      },
    };

    try {
      setState(() => isSaving = true);
      final apiService = ApiService();
      Map<String, dynamic> response;

      if (widget.postId != null && widget.adData != null) {
        // Edit existing post
        print(
          'Calling edit API: ${AttributeValueService.baseUrl}/flutter-edit-post.php',
        );
        formData['post_id'] = widget.postId!;
        formData['token'] = AttributeValueService.token;
        if (_deleteGalleryIds.isNotEmpty) {
          formData['delete_gallery'] = jsonEncode(_deleteGalleryIds);
          print('Sending delete_gallery: $_deleteGalleryIds');
        }
        final newImages =
            _selectedImages
                .asMap()
                .entries
                .where(
                  (e) =>
                      !_existingImages.any(
                        (img) => img['path'] == e.value.path,
                      ),
                )
                .map((e) => e.value.path)
                .toList();
        final mainImage = _selectedImages[_coverImageIndex].path;
        response = await apiService.postInfinityMultipart(
          url: "${AttributeValueService.baseUrl}/flutter-edit-post.php",
          fields: formData,
          mainImagePath: mainImage,
          galleryImagePaths:
              newImages.where((path) => path != mainImage).toList(),
        );
      } else {
        // Create new post
        response = await apiService.postInfinityMultipart(
          url: "${AttributeValueService.baseUrl}/flutter-add-post.php",
          fields: {
            ...formData,
            'if_offer_price': '0',
            'offer_price': '0.00',
            'auction_price_intervel': '0.00',
            'auction_starting_price': '0.00',
            'latitude': '',
            'longitude': '',
            'user_zone_id': '0',
            'zone_id': '0',
            'if_auction': '0',
            'auction_status': '0',
            'auction_startin': '0000-00-00 00:00:00',
            'auction_endin': '0000-00-00 00:00:00',
            'auction_attempt': '0',
            'if_finance': '0',
            'if_exchange': '0',
            'feature': '0',
            'status': '1',
            'visiter_count': '0',
            'if_sold': '0',
            'if_expired': '0',
            'if_verifyed': '0',
            'by_dealer': '0',
          },
          mainImagePath: _selectedImages[_coverImageIndex].path,
          galleryImagePaths:
              _selectedImages
                  .asMap()
                  .entries
                  .where((e) => e.key != _coverImageIndex)
                  .map((e) => e.value.path)
                  .toList(),
        );
      }

      if (response['status'] == 'true') {
        // Construct complete adData to pass to MyAdsWidget
        final newAdData = {
          'id':
              widget.postId ??
              response['post_id'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'title': _generateTitle(),
          'category_id': widget.categoryId,
          'price': _controllers['listPrice']!.text,
          'description': _controllers['description']!.text,
          'image':
              response['image'] ??
              '', // Use server-provided image URL if available
          'district': _selectedDistrict,
          'status': '0', // Assume pending until approved
          'created_on': DateTime.now().toIso8601String(),
          'admin_approval': '0',
          'if_auction': '0',
          'auction_status': '0',
          'auction_attempt': '0',
          'visiter_count': '0',
          'if_sold': '0',
          'land_mark': _controllers['landMark']!.text,
          'filters': jsonEncode(getFilters()),
          'brand': _selectedBrand?.id ?? '',
          'model': _selectedBrandModel?.id ?? '',
          'model_variation': _selectedModelVariation?.id ?? '',
          // Add any other fields expected by MyAdsWidget
        };

        _showSnackBar(
          'Ad ${widget.postId != null ? 'updated' : 'posted'} successfully',
          Colors.green,
        );
        context.pushReplacement(
          RouteNames.sellingstatuspage,
          extra: {
            'userId': widget.userId,
            'adData': newAdData, 
          },
        );
      } else {
        throw Exception(
          response['message'] ??
              'Failed to ${widget.postId != null ? 'update' : 'post'} ad',
        );
      }
    } catch (e) {
      print('Error saving ad: $e');
      _showSnackBar('Error saving ad: $e', Colors.red);
    } finally {
      setState(() => isSaving = false);
    }
  }

  Widget _buildImagePicker() => Column(
    children: [
      Container(
        width: 120,
        height: 150,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showImageSourceBottomSheet,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Photo (${_selectedImages.length}/$_maxImages)',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (_selectedImages.isNotEmpty)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _selectedImages.length,
          itemBuilder:
              (context, index) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_selectedImages[index].path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      if (index == _coverImageIndex)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Cover Photo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.star,
                                  size: 20,
                                  color:
                                      index == _coverImageIndex
                                          ? Colors.yellow
                                          : Colors.white,
                                ),
                                onPressed:
                                    () => setState(
                                      () => _coverImageIndex = index,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    final removedImage = _selectedImages[index];
                                    _selectedImages.removeAt(index);
                                    final existingImage = _existingImages
                                        .firstWhere(
                                          (img) =>
                                              img['path'] == removedImage.path,
                                          orElse: () => {},
                                        );
                                    if (existingImage.isNotEmpty &&
                                        existingImage['id'] != null) {
                                      _deleteGalleryIds.add(
                                        existingImage['id'],
                                      );
                                      _showSnackBar(
                                        'Image ID ${existingImage['id']} marked for deletion',
                                        Colors.orange,
                                      );
                                      print(
                                        'Marked image ID ${existingImage['id']} for deletion from post ${widget.postId}',
                                      );
                                    } else {
                                      print(
                                        'No gallery ID for removed image: ${removedImage.path}',
                                      );
                                    }
                                    _existingImages.removeWhere(
                                      (img) => img['path'] == removedImage.path,
                                    );
                                    if (_selectedImages.isNotEmpty) {
                                      if (index < _coverImageIndex) {
                                        _coverImageIndex--;
                                      } else if (index == _coverImageIndex) {
                                        _coverImageIndex = 0;
                                      }
                                    } else {
                                      _coverImageIndex = 0;
                                    }
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      if (_imageError)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Please add at least one photo',
            style: TextStyle(color: Colors.red[700], fontSize: 12),
          ),
        ),
    ],
  );

  Widget _buildImageSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Add Photos',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _selectedImages.isEmpty
          ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildImagePicker()],
          )
          : _buildImagePicker(),
      const SizedBox(height: 24),
    ],
  );

  Widget _buildKeyInfoSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Key Information',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 16),
      CustomDropdownWidget<Brand>(
        label: widget.categoryId == '2' ? 'Property Developer' : 'Brand',
        value: _selectedBrand,
        items: _brands,
        onChanged: (newValue) async {
          setState(() {
            _selectedBrand = newValue;
            _selectedBrandModel = _selectedModelVariation = null;
            _brandModels = [];
          });
          if (newValue != null) {
            final List<BrandModel> result =
                await AttributeValueService.fetchBrandModels(
                  newValue.id,
                  widget.categoryId,
                );
            setState(() => _brandModels = result);
          }
        },
        isRequired: true,
        itemToString: (item) => item.name,
        validator:
            (value) =>
                value == null
                    ? 'Please select a ${widget.categoryId == '2' ? 'property developer' : 'brand'}'
                    : null,
        hintText: '',
      ),
      if (_brandModels.isNotEmpty) ...[
        const SizedBox(height: 12),
        CustomDropdownWidget<BrandModel>(
          label: widget.categoryId == '2' ? 'Project' : 'Model',
          value: _selectedBrandModel,
          items: _brandModels,
          onChanged: (newValue) async {
            setState(() {
              _selectedBrandModel = newValue;
              _selectedModelVariation = null;
              _modelVariations = [];
            });
            if (newValue != null) {
              final variations =
                  await AttributeValueService.fetchModelVariations(
                    newValue.id,
                    widget.categoryId,
                  );
              setState(() => _modelVariations = variations.toSet().toList());
            }
          },
          isRequired: true,
          itemToString: (item) => item.name,
          validator:
              (value) =>
                  value == null
                      ? 'Please select a ${widget.categoryId == '2' ? 'project' : 'model'}'
                      : null,
          hintText: '',
        ),
      ],
      if (_modelVariations.isNotEmpty) ...[
        const SizedBox(height: 12),
        CustomDropdownWidget<ModelVariation>(
          label: 'Model Variation',
          value: _selectedModelVariation,
          items: _modelVariations,
          onChanged:
              (newValue) => setState(() => _selectedModelVariation = newValue),
          isRequired: false,
          itemToString: (item) => item.name,
          hintText: 'Select a variation',
        ),
      ],
      const SizedBox(height: 12),
      CustomFormField(
        controller: _controllers['listPrice']!,
        label: 'List Price',
        isNumberInput: true,
        isRequired: true,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Please enter the list price';
          final listPrice = double.tryParse(value!);
          if (listPrice == null) return 'Please enter a valid number';
          return null;
        },
      ),
      const SizedBox(height: 12),
      CustomDropdownWidget<String>(
        label: 'District',
        value: _selectedDistrict,
        items:
            _districts.isNotEmpty
                ? _districts.map((d) => d['name'] as String).toList()
                : ['No districts available'],
        onChanged: (newValue) {
          if (newValue != null && newValue != 'No districts available') {
            setState(() => _selectedDistrict = newValue);
          }
        },
        isRequired: true,
        itemToString: (item) => item,
        validator:
            (value) =>
                value == null || value == 'No districts available'
                    ? 'Please select a district'
                    : null,
        hintText: '',
      ),
      const SizedBox(height: 12),
      CustomFormField(
        controller: _controllers['landMark']!,
        label: 'Landmark',
        alignLabelWithHint: true,
      ),
      const SizedBox(height: 12),
      CustomFormField(
        controller: _controllers['description']!,
        label: 'Description',
        alignLabelWithHint: true,
        maxLines: 5,
      ),
    ],
  );

  Widget _buildMoreInfoSection() =>
      _attributes.isEmpty
          ? const SizedBox.shrink()
          : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'More Info',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ..._attributes.map((attr) {
                final isRequired = _getRequiredAttributes().contains(attr.name);
                final hasVariations =
                    _attributeVariations[attr.name]?.isNotEmpty ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      hasVariations
                          ? CustomDropdownWidget<String>(
                            label: attr.name,
                            value: _selectedAttributes[attr.name],
                            items:
                                _attributeVariations[attr.name]
                                    ?.map((v) => v.name)
                                    .toList() ??
                                ['No options available'],
                            onChanged: (newValue) {
                              if (newValue != null &&
                                  newValue != 'No options available') {
                                setState(
                                  () =>
                                      _selectedAttributes[attr.name] = newValue,
                                );
                              }
                            },
                            isRequired: isRequired,
                            itemToString: (item) => item,
                            validator:
                                isRequired
                                    ? (value) =>
                                        value == null ||
                                                value.isEmpty ||
                                                value == 'No options available'
                                            ? 'Please select ${attr.name}'
                                            : null
                                    : null,
                            hintText: '',
                          )
                          : CustomFormField(
                            controller: _attributeControllers[attr.name]!,
                            label: attr.name,
                            isRequired: isRequired,
                            validator:
                                isRequired
                                    ? (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Please enter ${attr.name}'
                                            : null
                                    : null,
                            onChanged:
                                (value) => setState(
                                  () => _selectedAttributes[attr.name] = value,
                                ),
                          ),
                );
              }),
            ],
          );

  Widget _buildSubmitButton() => SafeArea(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSaving ? null : widget.onSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Palette.primaryblue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 0),
          ),
          child:
              isSaving
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                  : Text(
                    widget.postId != null ? 'Update Ad' : 'Post Ad',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fadeAnimation,
    child: Stack(
      children: [
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: Form(
              key: widget.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildImageSection(),
                  _buildKeyInfoSection(),
                  _buildMoreInfoSection(),
                ],
              ),
            ),
          ),
        ),
        _buildSubmitButton(),
      ],
    ),
  );

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var c in _attributeControllers.values) {
      c.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }
}
