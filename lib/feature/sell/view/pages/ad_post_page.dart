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
        developer.log('Districts API response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
        developer.log('No districts found');
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
      developer.log('Failed to fetch districts: ${response.statusCode} $responseBody');
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
      developer.log('Error fetching districts: $e');
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
        developer.log('Brands API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final brands =
              (data['data'] as List)
                  .map((e) => Brand.fromJson(e))
                  .where((brand) => brand.categoryId == categoryId)
                  .toList();
          developer.log(
            'Filtered brands for category_id $categoryId: ${brands.map((b) => b.name).toList()}',
          );
          return brands;
        }
        developer.log('No brands found for category_id: $categoryId');
        return [];
      }
      developer.log('Failed to fetch brands: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      developer.log('Error fetching brands: $e');
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
        developer.log(
          'Brand models API response for brand_id $brandId, category_id $categoryId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          final models =
              (data['data'] as List)
                  .map((e) => BrandModel.fromJson(e))
                  .toList();
          developer.log('Fetched brand models: ${models.map((m) => m.name).toList()}');
          return models;
        }
        developer.log(
          'No brand models found for brand_id: $brandId, category_id: $categoryId',
        );
        return [];
      }
      developer.log(
        'Failed to fetch brand models: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      developer.log('Error fetching brand models: $e');
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
        developer.log(
          'Model variations API response for brands_model_id $brandModelId, category_id $categoryId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          final variations =
              (data['data'] as List)
                  .map((e) => ModelVariation.fromJson(e))
                  .toList();
          developer.log('Model variations IDs: ${variations.map((v) => v.id).toSet()}');
          developer.log(
            'Model variations names: ${variations.map((v) => v.name).toSet()}',
          );
          return variations;
        }
        developer.log(
          'No model variations found for brands_model_id: $brandModelId, category_id: $categoryId',
        );
        return [];
      }
      developer.log(
        'Failed to fetch model variations: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      developer.log('Error fetching model variations: $e');
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
        developer.log('Attributes API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => Attribute.fromJson(e))
              .toList();
        }
        developer.log('No attributes found for category_id: $categoryId');
        return [];
      }
      developer.log(
        'Failed to fetch attributes: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      developer.log('Error fetching attributes: $e');
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
        developer.log(
          'Attribute variations API response for attribute_id $attributeId: $data',
        );
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => AttributeVariation.fromJson(e))
              .toList();
        }
        developer.log('No variations found for attribute_id: $attributeId');
        return [];
      }
      developer.log(
        'Failed to fetch attribute variations: ${response.statusCode} ${response.body}',
      );
      return [];
    } catch (e) {
      developer.log(
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
  String? _categoryId;
  Map<String, dynamic>? _adData;
  late final LoggedUserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<LoggedUserProvider>(context, listen: false);
    if (widget.extra != null) {
      _categoryId = widget.extra!['categoryId']?.toString();
      _adData = widget.extra!['adData'] as Map<String, dynamic>?;
      if (_categoryId == null) {
        showToast('Invalid category ID', Colors.red);
      }
    } else {
      showToast('No category or user ID provided', Colors.red);
    }
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
    if (_formKey.currentState!.validate()) _formKey.currentState!.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          _adData != null ? 'Edit Ad' : 'Post your Ad',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: AdPostForm(
        formKey: _formKey,
        categoryId: _categoryId ?? '',
        userId: _userProvider.userId!,
        adData: _adData,
        onSubmit: _submitForm,
      ),
    );
  }
}

class AdPostForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String categoryId, userId;
  final Map<String, dynamic>? adData;
  final VoidCallback onSubmit;

  const AdPostForm({
    super.key,
    required this.formKey,
    required this.categoryId,
    required this.userId,
    this.adData,
    required this.onSubmit,
  });

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
    '2' => ['Plot Area', 'Facing',  'Listed By'],
    // '3' => ['Vehicle Type', 'Year', 'Fuel Type'],
    // '4' => ['Item Type', 'Condition'],
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
      _showToast('Error: No category selected', Colors.red);
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
    });

    // Pre-fill form
    if (widget.adData != null) {
      final ad = widget.adData!;
      _controllers['listPrice']!.text = ad['price'] ?? '';
      _controllers['description']!.text = ad['description'] ?? '';
      _controllers['landMark']!.text = ad['land_mark'] ?? '';
      _controllers['registration']!.text = ad['registration_valid_till'] ?? '';
      _controllers['insurance']!.text = ad['insurance_upto'] ?? '';
      _selectedDistrict =
          ad['district'] ??
          (_districts.isNotEmpty ? _districts[0]['name'] : null);
      _coverImageIndex = ad['coverImageIndex']?.toInt() ?? 0;
      await _loadImages(ad);
    }

    // Fetch districts and brands
    _districts = [
  {
    'id': '0', // Use a unique ID for "All Kerala"
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
  ...await AttributeValueService.fetchDistricts()
];
    _brands = await AttributeValueService.fetchBrands(widget.categoryId);
    setState(() {
      _selectedDistrict ??= 'All Kerala'; 
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

    // Fetch brand models
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

      // Fetch model variations
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
            if (_selectedModelVariation!.id.isEmpty) {
              _selectedModelVariation = null;
            }
          }
        });
      }
    }

    // Fetch attributes
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
            developer.log(e.toString());

        }
      }
    });

    // Fetch attribute variations
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
    if (ad['imagePathList']?.isNotEmpty ?? false) {
      _selectedImages.addAll(
        (ad['imagePathList'] as List).map((path) => XFile(path)),
      );
    } else if (ad['imageBase64List']?.isNotEmpty ?? false) {
      final tempDir = await getTemporaryDirectory();
      for (var img in ad['imageBase64List']) {
        final bytes = base64Decode(img);
        final file = File(
          '${tempDir.path}/ad_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await file.writeAsBytes(bytes);
        _selectedImages.add(XFile(file.path));
      }
    } else if (ad['imagePath']?.isNotEmpty ?? false) {
      _selectedImages.add(XFile(ad['imagePath']));
    } else if (ad['imageBase64']?.isNotEmpty ?? false) {
      final tempDir = await getTemporaryDirectory();
      final bytes = base64Decode(ad['imageBase64']);
      final file = File(
        '${tempDir.path}/ad_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);
      _selectedImages.add(XFile(file.path));
    }
    setState(() {
      if (_coverImageIndex >= _selectedImages.length) _coverImageIndex = 0;
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
              attributeId: '',
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

    // Brand/model validations
    if (widget.categoryId == '1' || widget.categoryId == '2') {
      if (_selectedBrand == null || _selectedBrandModel == null) {
        _showSnackBar('Category/Brand', Colors.red);
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

    // Validate attributes
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

    // Build filters properly (attributeId -> variationId/value)
    final filters = <String, List<String>>{};
    _selectedAttributes.forEach((attrName, value) {
      if (value != null && value.isNotEmpty) {
        final attrId = _attributeIdMap[attrName];
        if (attrId != null && attrId.isNotEmpty) {
          final variations = _attributeVariations[attrName] ?? [];
          final variation = variations.firstWhere(
            (v) => v.name == value,
            orElse:
                () => AttributeVariation(
                  id: '',
                  attributeId: attrId,
                  name: value,
                  status: '',
                  createdOn: '',
                  updatedOn: '',
                ),
          );
          filters[attrId] = [variation.id.isNotEmpty ? variation.id : value];
        }
      }
    });

    // Special cases for category 1
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

    final formData = {
      'user_id': widget.userId,
      'title': _generateTitle(),
      'category_id': widget.categoryId,
      'brand': _selectedBrand?.id,
      'brand_name': _selectedBrand?.name,
      'model': _selectedBrandModel?.id,
      'model_name': _selectedBrandModel?.name,
      'model_variation': _selectedModelVariation?.id ?? '',
      'description': _controllers['description']?.text,
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
    };

    try {
      setState(() {
        isSaving = true;
      });
      final apiService = ApiService();
      final response = await apiService.postInfinityMultipart(
        url: "$baseUrl/flutter-add-post.php",
        fields: formData,
        mainImagePath: _selectedImages[_coverImageIndex].path,
        galleryImagePaths:
            _selectedImages
                .asMap()
                .entries
                .where((e) => e.key != _coverImageIndex)
                .map((e) => e.value.path)
                .toList(),
      );

      if (response['status'] == 'true') {
        final postId =
            response['data']?[0]['id']?.toString() ??
            'new_${DateTime.now().millisecondsSinceEpoch}';

        _showSnackBar(
          widget.adData != null
              ? 'Ad updated successfully'
              : 'Ad posted successfully',
          Colors.green,
        );
        context.pushNamed(
          RouteNames.sellingstatuspage,
          extra: {
            'userId': widget.userId,
            'adData': {
              'id': postId,
            },
          },
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to save ad');
      }
    } catch (e, stack) {
      print(stack);
      _showSnackBar('Error saving ad: $e', Colors.red);
    } finally {
      setState(() {
        isSaving = false;
      });
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
                                icon: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                onPressed:
                                    () => setState(() {
                                      _selectedImages.removeAt(index);
                                      if (_selectedImages.isNotEmpty) {
                                        if (index < _coverImageIndex) {
                                          _coverImageIndex--;
                                        } else if (index == _coverImageIndex) {
                                          _coverImageIndex = 0;
                                        }
                                      } else {
                                        _coverImageIndex = 0;
                                      }
                                    }),
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
      const Text(
        'Add Photos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
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
              setState(
                () async =>
                    _modelVariations =
                        (await AttributeValueService.fetchModelVariations(
                          newValue.id,
                          widget.categoryId,
                        )).toSet().toList(),
              );
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
          final offerPrice = double.tryParse(
            _controllers['offerPrice']?.text ?? '',
          );
          if (offerPrice != null && offerPrice > listPrice) {
            return 'List price must be greater than or equal to offer price';
          }
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
      // if (widget.categoryId == '1') ...[
      //   const SizedBox(height: 12),
      //   CustomFormField(
      //     controller: _controllers['registration']!,
      //     label: 'Registration Valid Till',
      //   ),
      //   const SizedBox(height: 12),
      //   CustomFormField(
      //     controller: _controllers['insurance']!,
      //     label: 'Insurance Upto',
      //   ),
      // ],
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

  Widget _buildSubmitButton() => Column(
    children: [
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: isSaving ? null : _submitForm, // disable while saving
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(),
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
                    widget.adData != null ? 'Update Ad' : 'Post Ad',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
        ),
      ),
      const SizedBox(height: 24),
    ],
  );

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fadeAnimation,
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildImageSection(),
              _buildKeyInfoSection(),
              _buildMoreInfoSection(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
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
