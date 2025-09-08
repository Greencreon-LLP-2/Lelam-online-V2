import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lelamonline_flutter/core/router/route_names.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/core/utils/districts.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/custom_dropdown_widget.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/image_source_bottom_sheet.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/text_field_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
            "updated_on": "2024-12-04 11:06:32"
          }
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
          "updated_on": "2024-12-04 11:06:32"
        }
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
          "updated_on": "2024-12-04 11:06:32"
        }
      ];
    }
  }

  static Future<List<Brand>> fetchBrands(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-brand.php?token=$token&category_id=$categoryId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Brands API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final brands = (data['data'] as List)
              .map((e) => Brand.fromJson(e))
              .where((brand) => brand.categoryId == categoryId)
              .toList();
          print('Filtered brands for category_id $categoryId: ${brands.map((b) => b.name).toList()}');
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

  static Future<List<BrandModel>> fetchBrandModels(String brandId, String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-model.php?token=$token&brand_id=$brandId&category_id=$categoryId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Brand models API response for brand_id $brandId, category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final models = (data['data'] as List).map((e) => BrandModel.fromJson(e)).toList();
          print('Fetched brand models: ${models.map((m) => m.name).toList()}');
          return models;
        }
        print('No brand models found for brand_id: $brandId, category_id: $categoryId');
        return [];
      }
      print('Failed to fetch brand models: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching brand models: $e');
      return [];
    }
  }

  static Future<List<ModelVariation>> fetchModelVariations(String brandModelId, String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-model-variations.php?token=$token&brands_model_id=$brandModelId&category_id=$categoryId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Model variations API response for brands_model_id $brandModelId, category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final variations = (data['data'] as List).map((e) => ModelVariation.fromJson(e)).toList();
          print('Model variations IDs: ${variations.map((v) => v.id).toSet()}');
          print('Model variations names: ${variations.map((v) => v.name).toSet()}');
          return variations;
        }
        print('No model variations found for brands_model_id: $brandModelId, category_id: $categoryId');
        return [];
      }
      print('Failed to fetch model variations: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching model variations: $e');
      return [];
    }
  }

  static Future<List<Attribute>> fetchAttributes(String categoryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter-attribute.php?token=$token&category_id=$categoryId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Attributes API response for category_id $categoryId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List).map((e) => Attribute.fromJson(e)).toList();
        }
        print('No attributes found for category_id: $categoryId');
        return [];
      }
      print('Failed to fetch attributes: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching attributes: $e');
      return [];
    }
  }

  static Future<List<AttributeVariation>> fetchAttributeVariations(String attributeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/filter-attribute-variations.php?token=$token&attribute_id=$attributeId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Attribute variations API response for attribute_id $attributeId: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List).map((e) => AttributeVariation.fromJson(e)).toList();
        }
        print('No variations found for attribute_id: $attributeId');
        return [];
      }
      print('Failed to fetch attribute variations: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('Error fetching attribute variations for attribute_id $attributeId: $e');
      return [];
    }
  }
}

class AdPostPage extends StatefulWidget {
  final Map<String, dynamic>? extra; // Contains categoryId, userId, and adData

  const AdPostPage({super.key, this.extra});

  @override
  State<AdPostPage> createState() => _AdPostPageState();
}

class _AdPostPageState extends State<AdPostPage> {
  final _formKey = GlobalKey<FormState>();
  String? _categoryId;
  String? _userId;
  Map<String, dynamic>? _adData;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
  }

  @override
  void initState() {
    super.initState();
    print('Received extra: ${widget.extra}');
    if (widget.extra != null) {
      _categoryId = widget.extra!['categoryId']?.toString();
      _userId = widget.extra!['userId']?.toString() ?? 'Unknown';
      _adData = widget.extra!['adData'] as Map<String, dynamic>?;
      if (_categoryId == null) {
        print('Error: categoryId is missing or invalid in extra: ${widget.extra}');
        Fluttertoast.showToast(
          msg: 'Invalid category ID',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      if (_adData != null) {
        print('Editing ad: ${_adData!['appId']}');
      }
    } else {
      print('Error: extra is null');
      _categoryId = null;
      _userId = 'Unknown';
      Fluttertoast.showToast(
        msg: 'No category or user ID provided',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
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
          _adData != null ? 'Edit Ad' : 'Post your Ad',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _submitForm,
            child: Text(
              _adData != null ? 'Update' : 'Post',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: AdPostForm(
        formKey: _formKey,
        categoryId: _categoryId ?? '',
        userId: _userId,
        adData: _adData,
        onSubmit: _submitForm,
      ),
    );
  }
}

class AdPostForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String categoryId;
  final String? userId;
  final Map<String, dynamic>? adData;
  final VoidCallback onSubmit;

  const AdPostForm({
    super.key,
    required this.formKey,
    required this.categoryId,
    this.userId,
    this.adData,
    required this.onSubmit,
  });

  @override
  State<AdPostForm> createState() => _AdPostFormState();
}

class _AdPostFormState extends State<AdPostForm> with SingleTickerProviderStateMixin {
  List<Brand> _brands = [];
  List<BrandModel> _brandModels = [];
  List<ModelVariation> _modelVariations = [];
  List<Map<String, dynamic>> _districts = [];
  Brand? _selectedBrand;
  BrandModel? _selectedBrandModel;
  ModelVariation? _selectedModelVariation;
  Map<String, String?> _selectedAttributes = {};
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _listPriceController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _districtController = TextEditingController();
  final _landMarkController = TextEditingController();
  final _registrationValidTillController = TextEditingController();
  final _insuranceUptoController = TextEditingController();
  final Map<String, List<AttributeVariation>> _attributeVariations = {};
  Map<String, String> _attributeIdMap = {};
  List<Attribute> _attributes = [];
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _imageError = false;
  final int _maxImages = 10;
  int _coverImageIndex = 0;
  final Map<String, TextEditingController> _attributeControllers = {};
  String? _selectedDistrict;

  List<String> _getRequiredAttributes(String categoryId) {
    switch (categoryId) {
      case '1':
        return ['Year', 'No of owners', 'Fuel Type', 'Transmission', 'KM Range', 'Sold by'];
      case '2':
        return ['Property Type', 'Area', 'Location'];
      case '3':
        return ['Vehicle Type', 'Year', 'Fuel Type'];
      case '4':
        return ['Item Type', 'Condition'];
      default:
        return [];
    }
  }

  void _updateModelVariations(List<ModelVariation> modelVariations) {
    setState(() {
      _modelVariations = modelVariations;
      if (_selectedModelVariation != null &&
          !modelVariations.any((item) => item.id == _selectedModelVariation!.id)) {
        _selectedModelVariation = null;
      }
      print('Updated model variations: ${modelVariations.map((v) => v.name).toList()}');
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();

    _fetchInitialData();
  }

  Future<void> _convertBase64ToFiles(List base64Images) async {
    final tempDir = await getTemporaryDirectory();
    final List<XFile> files = [];
    for (int i = 0; i < base64Images.length; i++) {
      try {
        final bytes = base64Decode(base64Images[i] as String);
        final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      } catch (e) {
        print('Error converting base64 image $i: $e');
      }
    }
    setState(() {
      _selectedImages.addAll(files);
      if (_coverImageIndex >= _selectedImages.length) {
        _coverImageIndex = 0;
      }
    });
  }

  Future<void> _convertBase64ToFile(String base64Image) async {
    try {
      final bytes = base64Decode(base64Image);
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ad_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      setState(() {
        _selectedImages.add(XFile(file.path));
        if (_coverImageIndex >= _selectedImages.length) {
          _coverImageIndex = 0;
        }
      });
    } catch (e) {
      print('Error converting single base64 image: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    if (widget.categoryId.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Error: No category selected',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    setState(() {
      _brands = [];
      _brandModels = [];
      _modelVariations = [];
      _districts = [];
      _selectedBrand = null;
      _selectedBrandModel = null;
      _selectedModelVariation = null;
      _attributes = [];
      _attributeVariations.clear();
      _attributeIdMap = {};
      _selectedAttributes = {};
      _attributeControllers.forEach((_, controller) => controller.dispose());
      _attributeControllers.clear();
    });

    // Pre-fill form with adData if provided
    if (widget.adData != null) {
      final ad = widget.adData!;
      _titleController.text = ad['title'] ?? '';
      _listPriceController.text = ad['price'] ?? '';
      _descriptionController.text = ad['description'] ?? '';
      _landMarkController.text = ad['land_mark'] ?? '';
      _registrationValidTillController.text = ad['registration_valid_till'] ?? '';
      _insuranceUptoController.text = ad['insurance_upto'] ?? '';
      _selectedDistrict = ad['district'] ?? null;
      _coverImageIndex = ad['coverImageIndex']?.toInt() ?? 0;
      // Load images
      if (ad['imagePathList'] != null && (ad['imagePathList'] as List).isNotEmpty) {
        _selectedImages.addAll((ad['imagePathList'] as List).map((path) => XFile(path as String)));
      } else if (ad['imageBase64List'] != null && (ad['imageBase64List'] as List).isNotEmpty) {
        await _convertBase64ToFiles(ad['imageBase64List'] as List);
      } else if (ad['imagePath'] != null && (ad['imagePath'] as String).isNotEmpty) {
        _selectedImages.add(XFile(ad['imagePath'] as String));
      } else if (ad['imageBase64'] != null && (ad['imageBase64'] as String).isNotEmpty) {
        await _convertBase64ToFile(ad['imageBase64'] as String);
      }
      print('Pre-filled form with adData: ${ad['appId']}');
    }

    // Fetch districts
    final districts = await AttributeValueService.fetchDistricts();
    setState(() {
      _districts = districts;
      _selectedDistrict = _selectedDistrict ?? (districts.isNotEmpty ? districts[0]['name'] : null);
      print('Loaded districts: ${districts.map((d) => d['name']).toList()}');
    });

    // Fetch brands
    final brands = await AttributeValueService.fetchBrands(widget.categoryId);
    setState(() {
      _brands = brands;
      print('Loaded brands for category ${widget.categoryId}: ${brands.map((b) => b.name).toList()}');
      // Set selected brand from adData
      if (widget.adData != null && widget.adData!['brand'] != null) {
        _selectedBrand = brands.firstWhere(
          (b) => b.id == widget.adData!['brand'],
          orElse: () => Brand(id: '', slug: '', categoryId: '', name: '', image: '', status: '', createdOn: '', updatedOn: ''),
        );
        if (_selectedBrand!.id.isEmpty) _selectedBrand = null;
      }
    });

    // Fetch brand models if brand is selected
    if (_selectedBrand != null) {
      final brandModels = await AttributeValueService.fetchBrandModels(_selectedBrand!.id, widget.categoryId);
      setState(() {
        _brandModels = brandModels;
        print('Loaded brand models for brand ${_selectedBrand!.name}: ${brandModels.map((m) => m.name).toList()}');
        // Set selected brand model from adData
        if (widget.adData != null && widget.adData!['model'] != null) {
          _selectedBrandModel = brandModels.firstWhere(
            (m) => m.id == widget.adData!['model'],
            orElse: () => BrandModel(id: '', brandId: '', slug: '', name: '', image: '', status: '', createdOn: '', updatedOn: ''),
          );
          if (_selectedBrandModel!.id.isEmpty) _selectedBrandModel = null;
        }
      });

      // Fetch model variations if brand model is selected
      if (_selectedBrandModel != null) {
        final modelVariations = await AttributeValueService.fetchModelVariations(_selectedBrandModel!.id, widget.categoryId);
        final uniqueModelVariations = modelVariations.asMap().entries.fold<List<ModelVariation>>(
          [],
          (uniqueList, entry) {
            if (!uniqueList.any((item) => item.id == entry.value.id)) {
              uniqueList.add(entry.value);
            }
            return uniqueList;
          },
        );
        setState(() {
          _modelVariations = uniqueModelVariations;
          print('Loaded model variations: ${uniqueModelVariations.map((v) => v.name).toList()}');
          // Set selected model variation from adData
          if (widget.adData != null && widget.adData!['model_variation'] != null) {
            _selectedModelVariation = uniqueModelVariations.firstWhere(
              (v) => v.id == widget.adData!['model_variation'],
              orElse: () => ModelVariation(id: '', slug: '', brandId: '', brandModelId: '', name: '', image: '', status: '', createdOn: '', updatedOn: ''),
            );
            if (_selectedModelVariation!.id.isEmpty) _selectedModelVariation = null;
          }
        });
      }
    }

    // Fetch attributes
    final attributes = await AttributeValueService.fetchAttributes(widget.categoryId);
    setState(() {
      _attributes = attributes;
      _attributeIdMap = {for (var attr in attributes) attr.name: attr.id};
      _selectedAttributes = {for (var attr in attributes) attr.name: null};
      for (var attr in attributes) {
        _attributeControllers[attr.name] = TextEditingController();
      }
      print('Loaded attributes for category ${widget.categoryId}: ${attributes.map((a) => a.name).toList()}');
      // Set selected attributes from adData.filters
      if (widget.adData != null && widget.adData!['filters'] != null) {
        try {
          final filters = jsonDecode(widget.adData!['filters'] as String) as Map<String, dynamic>;
          for (var attr in attributes) {
            final attrId = attr.id;
            if (filters.containsKey(attrId) && filters[attrId] is List && (filters[attrId] as List).isNotEmpty) {
              final variationId = filters[attrId][0].toString();
              _selectedAttributes[attr.name] = variationId; // Will be updated to name after fetching variations
            }
          }
        } catch (e) {
          print('Error parsing filters from adData: $e');
        }
      }
    });

    // Fetch attribute variations and update selected attributes
    for (var attr in attributes) {
      final variations = await AttributeValueService.fetchAttributeVariations(attr.id);
      setState(() {
        _attributeVariations[attr.name] = variations;
        print('Loaded variations for attribute ${attr.name} (ID: ${attr.id}): ${variations.map((v) => v.name).toList()}');
        // Update selected attributes with variation names
        if (_selectedAttributes[attr.name] != null) {
          final variationId = _selectedAttributes[attr.name];
          final variation = variations.firstWhere(
            (v) => v.id == variationId,
            orElse: () => AttributeVariation(id: '', attributeId: '', name: variationId ?? '', status: '', createdOn: '', updatedOn: ''),
          );
          _selectedAttributes[attr.name] = variation.name.isNotEmpty ? variation.name : variationId;
          if (_attributeControllers[attr.name] != null) {
            _attributeControllers[attr.name]!.text = variation.name.isNotEmpty ? variation.name : variationId ?? '';
          }
        }
      });
    }
  }

  Future<void> _fetchModelVariations(String brandModelId) async {
    final modelVariations = await AttributeValueService.fetchModelVariations(brandModelId, widget.categoryId);
    final uniqueModelVariations = modelVariations.asMap().entries.fold<List<ModelVariation>>(
      [],
      (uniqueList, entry) {
        if (!uniqueList.any((item) => item.id == entry.value.id)) {
          uniqueList.add(entry.value);
        }
        return uniqueList;
      },
    );
    _updateModelVariations(uniqueModelVariations);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxImages images allowed'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    try {
      if (source == ImageSource.camera) {
        final XFile? image = await _imagePicker.pickImage(source: source, imageQuality: 80);
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
            _imageError = false;
            if (_selectedImages.length == 1) {
              _coverImageIndex = 0;
            }
            print('Added camera image: ${image.path}');
          });
        }
      } else {
        final List<XFile>? images = await _imagePicker.pickMultiImage(imageQuality: 80);
        if (images != null && images.isNotEmpty) {
          setState(() {
            final newImages = images.take(_maxImages - _selectedImages.length).toList();
            _selectedImages.addAll(newImages);
            _imageError = false;
            if (_selectedImages.length == newImages.length) {
              _coverImageIndex = 0;
            }
            print('Added gallery images: ${newImages.map((img) => img.path).toList()}');
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceBottomSheetWidget(
        onCameraTap: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGalleryTap: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }

  Map<String, List<String>> getFilters() {
    final filters = <String, List<String>>{};
    _selectedAttributes.forEach((attrName, selectedValue) {
      if (selectedValue != null && selectedValue.isNotEmpty) {
        final variations = _attributeVariations[attrName];
        if (variations != null && variations.isNotEmpty) {
          final variation = variations.firstWhere(
            (v) => v.name == selectedValue,
            orElse: () => AttributeVariation(id: '', attributeId: _attributeIdMap[attrName] ?? '', name: '', status: '', createdOn: '', updatedOn: ''),
          );
          if (variation.id.isNotEmpty) {
            filters[_attributeIdMap[attrName] ?? ''] = [variation.id];
          } else {
            filters[_attributeIdMap[attrName] ?? ''] = [selectedValue];
          }
        } else {
          filters[_attributeIdMap[attrName] ?? ''] = [selectedValue];
        }
      }
    });
    if (widget.categoryId == '1' && _registrationValidTillController.text.isNotEmpty) {
      final regId = _attributeIdMap['Registration valid till'] ?? '27';
      filters[regId] = [_registrationValidTillController.text];
    }
    if (widget.categoryId == '1' && _insuranceUptoController.text.isNotEmpty) {
      final insId = _attributeIdMap['Insurance Upto'] ?? '28';
      filters[insId] = [_insuranceUptoController.text];
    }
    print('Filters: $filters');
    return filters;
  }

  Future<void> _submitForm() async {
    setState(() {
      _imageError = _selectedImages.isEmpty;
    });
    if (_imageError || !widget.formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_imageError ? 'Please add at least one photo' : 'Please fill all required fields'),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (widget.categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Category ID is missing'),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final requiredAttributes = _getRequiredAttributes(widget.categoryId);
    final missingAttributes = requiredAttributes.where(
      (attr) => _selectedAttributes[attr] == null || _selectedAttributes[attr]!.isEmpty,
    ).toList();
    if (missingAttributes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select: ${missingAttributes.join(", ")}'),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Prepare filters
    final filters = {
      "1": ["1"],
      "2": ["4"],
      "3": ["6"],
      "4": ["10"],
      "5": ["12"],
      "6": ["14"],
      "7": ["15"],
      "8": ["17"],
      "9": ["19"]
    };

    // Prepare form data for API
    final formData = {
      'user_id': widget.userId ?? '4',
      'title': _titleController.text,
      'category_id': widget.categoryId,
      'brand': _selectedBrand?.id ?? '14',
      'model': _selectedBrandModel?.id ?? '1',
      'model_variation': _selectedModelVariation?.id ?? '12',
      'description': _descriptionController.text,
      'price': _listPriceController.text,
      'filters': jsonEncode(filters),
      'parent_zone_id': '482',
      'land_mark': _landMarkController.text,
    };

    // Add registration and insurance fields for category '1' (Used Cars)
    if (widget.categoryId == '1') {
      formData['registration_valid_till'] = _registrationValidTillController.text;
      formData['insurance_upto'] = _insuranceUptoController.text;
    }

    // Log form data for debugging
    print('Submitting form data: $formData');
    print('Number of images: ${_selectedImages.length}');
    print('Cover image index: $_coverImageIndex');

    // Submit ad post
    try {
      final adPostRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${AttributeValueService.baseUrl}/add-post.php?token=${AttributeValueService.token}&user_id=${widget.userId ?? '4'}&title=${_titleController.text}&category_id=${widget.categoryId}&brand=${_selectedBrand?.id ?? '14'}&model=${_selectedBrandModel?.id ?? '1'}&model_variation=${_selectedModelVariation?.id ?? '12'}&description=${_descriptionController.text}&price=${_listPriceController.text}&filters=${jsonEncode(filters)}&parent_zone_id=482&land_mark=${_landMarkController.text}'),
      );
      adPostRequest.headers.addAll({
        'token': AttributeValueService.token,
        'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
      });

      final adPostResponse = await adPostRequest.send();
      final adPostResponseBody = await adPostResponse.stream.bytesToString();
      print('Ad post response status: ${adPostResponse.statusCode}');
      print('Ad post response body: $adPostResponseBody');

      final responseData = jsonDecode(adPostResponseBody);
      if (adPostResponse.statusCode == 200 && responseData['status'] == 'true') {
        final postId = responseData['data'] is List && responseData['data'].isNotEmpty
            ? responseData['data'][0]['id']?.toString() ?? 'new_${DateTime.now().millisecondsSinceEpoch}'
            : 'new_${DateTime.now().millisecondsSinceEpoch}';

        // Upload main image
        if (_selectedImages.isNotEmpty) {
          final mainImage = _selectedImages[_coverImageIndex];
          final mainImageRequest = http.MultipartRequest(
            'POST',
            Uri.parse('${AttributeValueService.baseUrl}/add-post-main-image.php?token=${AttributeValueService.token}&post_id=$postId&image=${mainImage.name}'),
          );
          mainImageRequest.headers.addAll({
            'token': AttributeValueService.token,
            'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
          });
          mainImageRequest.files.add(await http.MultipartFile.fromPath('image', mainImage.path));
          final mainImageResponse = await mainImageRequest.send();
          final mainImageResponseBody = await mainImageResponse.stream.bytesToString();
          print('Main image response status: ${mainImageResponse.statusCode}');
          print('Main image response body: $mainImageResponseBody');

          // Upload gallery images
          for (var i = 0; i < _selectedImages.length; i++) {
            if (i != _coverImageIndex) {
              final galleryImage = _selectedImages[i];
              final galleryImageRequest = http.MultipartRequest(
                'POST',
                Uri.parse('${AttributeValueService.baseUrl}/add-post-gallery-image.php?token=${AttributeValueService.token}&post_id=$postId&image=${galleryImage.name}'),
              );
              galleryImageRequest.headers.addAll({
                'token': AttributeValueService.token,
                'Cookie': 'PHPSESSID=sgju9bt1ljebrc8sbca4bcn64a',
              });
              galleryImageRequest.files.add(await http.MultipartFile.fromPath('image', galleryImage.path));
              final galleryImageResponse = await galleryImageRequest.send();
              final galleryImageResponseBody = await galleryImageResponse.stream.bytesToString();
              print('Gallery image $i response status: ${galleryImageResponse.statusCode}');
              print('Gallery image $i response body: $galleryImageResponseBody');
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.adData != null ? 'Ad updated successfully' : 'Ad posted successfully'),
            backgroundColor: Colors.green.withOpacity(0.8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );

        // Construct adData for navigation
        Map<String, dynamic> adData = Map<String, dynamic>.from(formData);
        adData['id'] = postId;
        adData['created_on'] = DateTime.now().toIso8601String();
        adData['updated_on'] = DateTime.now().toIso8601String();
        adData['image'] = _selectedImages[_coverImageIndex].path;
        print('Constructed adData: $adData');

        // Navigate to SellingStatusPage
        context.pushNamed(
          RouteNames.sellingstatuspage,
          extra: {
            'userId': widget.userId ?? '4',
            'adData': adData,
          },
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to save ad (Status: ${adPostResponse.statusCode})');
      }
    } catch (e) {
      print('Error submitting ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving ad: $e'),
          backgroundColor: Colors.red.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _getCategoryName(String categoryId) {
    const categoryMap = {
      '1': 'Used Cars',
      '2': 'Real Estate',
      '3': 'Commercial Vehicles',
      '4': 'Other',
    };
    return categoryMap[categoryId] ?? 'Unknown';
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
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
              itemBuilder: (context, index) {
                return Container(
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
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (index == _coverImageIndex)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.star,
                                    size: 20,
                                    color: index == _coverImageIndex ? Colors.yellow : Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _coverImageIndex = index;
                                      print('Set cover image to index: $index');
                                    });
                                  },
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
                              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
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
                                  onPressed: () {
                                    setState(() {
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
                                      print('Removed image at index: $index, new cover index: $_coverImageIndex');
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          if (_imageError)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                'Please add at least one photo',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
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
            ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildImagePicker()])
            : _buildImagePicker(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildKeyInfoSection() {
    return Column(
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
          onChanged: (Brand? newValue) async {
            setState(() {
              _selectedBrand = newValue;
              _selectedBrandModel = null;
              _selectedModelVariation = null;
              _brandModels = [];
              _modelVariations = [];
              print('Selected brand: ${newValue?.name} (ID: ${newValue?.id})');
            });
            if (newValue != null) {
              final brandModels = await AttributeValueService.fetchBrandModels(newValue.id, widget.categoryId);
              setState(() {
                _brandModels = brandModels;
                print('Loaded brand models for brand ${newValue.name}: ${brandModels.map((m) => m.name).toList()}');
              });
            }
          },
          isRequired: true,
          itemToString: (Brand item) => item.name,
          validator: (Brand? value) => value == null ? 'Please select a ${widget.categoryId == '2' ? 'property developer' : 'brand'}' : null,
          hintText: '',
        ),
        const SizedBox(height: 12),
        if (_brandModels.isNotEmpty)
          CustomDropdownWidget<BrandModel>(
            label: widget.categoryId == '2' ? 'Project' : 'Model',
            value: _selectedBrandModel,
            items: _brandModels,
            onChanged: (BrandModel? newValue) async {
              setState(() {
                _selectedBrandModel = newValue;
                _selectedModelVariation = null;
                _modelVariations = [];
                print('Selected brand model: ${newValue?.name} (ID: ${newValue?.id})');
              });
              if (newValue != null) {
                await _fetchModelVariations(newValue.id);
              }
            },
            isRequired: true,
            itemToString: (BrandModel item) => item.name,
            validator: (BrandModel? value) => value == null ? 'Please select a ${widget.categoryId == '2' ? 'project' : 'model'}' : null,
            hintText: '',
          ),
        if (_brandModels.isNotEmpty) const SizedBox(height: 12),
        if (_modelVariations.isNotEmpty)
          CustomDropdownWidget<ModelVariation>(
            label: 'Model Variation',
            value: _selectedModelVariation,
            items: _modelVariations,
            onChanged: (ModelVariation? newValue) {
              setState(() {
                _selectedModelVariation = newValue;
                print('Selected model variation: ${newValue?.name} (ID: ${newValue?.id})');
              });
            },
            isRequired: false,
            itemToString: (ModelVariation item) => item.name,
            validator: null,
            hintText: 'Select a variation',
          ),
        if (_modelVariations.isNotEmpty) const SizedBox(height: 12),
        CustomFormField(
          controller: _titleController,
          label: 'Title',
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a title';
            }
            return null;
          },
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        CustomFormField(
          controller: _listPriceController,
          label: 'List Price',
          isNumberInput: true,
          isRequired: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter the list price';
            }
            final listPrice = double.tryParse(value);
            if (listPrice == null) {
              return 'Please enter a valid number';
            }
            if (_offerPriceController.text.isNotEmpty) {
              final offerPrice = double.tryParse(_offerPriceController.text);
              if (offerPrice != null && offerPrice > listPrice) {
                return 'List price must be greater than or equal to offer price';
              }
            }
            return null;
          },
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        CustomDropdownWidget<String>(
          label: 'District',
          value: _selectedDistrict,
          items: _districts.isNotEmpty ? _districts.map((d) => d['name'] as String).toList() : ['No districts available'],
          onChanged: (String? newValue) {
            if (newValue != null && newValue != 'No districts available') {
              setState(() {
                _selectedDistrict = newValue;
                print('Selected district: $newValue');
              });
            }
          },
          isRequired: true,
          itemToString: (String item) => item,
          validator: (String? value) => value == null || value == 'No districts available' ? 'Please select a district' : null,
          hintText: '',
        ),
        const SizedBox(height: 12),
        CustomFormField(
          controller: _landMarkController,
          label: 'Landmark',
          alignLabelWithHint: true,
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        if (widget.categoryId == '1') ...[
          CustomFormField(
            controller: _registrationValidTillController,
            label: 'Registration Valid Till',
            onChanged: (value) {},
          ),
          const SizedBox(height: 12),
          CustomFormField(
            controller: _insuranceUptoController,
            label: 'Insurance Upto',
            onChanged: (value) {},
          ),
          const SizedBox(height: 12),
        ],
        CustomFormField(
          controller: _descriptionController,
          label: 'Description',
          alignLabelWithHint: true,
          maxLines: 5,
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildMoreInfoSection() {
    if (_attributes.isEmpty) return const SizedBox.shrink();

    return Column(
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
          final isRequired = _getRequiredAttributes(widget.categoryId).contains(attr.name);
          final hasVariations = _attributeVariations[attr.name]?.isNotEmpty ?? false;

          if (hasVariations) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomDropdownWidget<String>(
                label: attr.name,
                value: _selectedAttributes[attr.name],
                items: _attributeVariations[attr.name]?.map((v) => v.name).toList() ?? ['No options available'],
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != 'No options available') {
                    setState(() {
                      _selectedAttributes[attr.name] = newValue;
                      print('Selected ${attr.name}: $newValue');
                    });
                  }
                },
                isRequired: isRequired,
                itemToString: (String item) => item,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty || value == 'No options available') {
                          return 'Please select ${attr.name}';
                        }
                        return null;
                      }
                    : null,
                hintText: '',
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CustomFormField(
                controller: _attributeControllers[attr.name]!,
                label: attr.name,
                isRequired: isRequired,
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ${attr.name}';
                        }
                        return null;
                      }
                    : null,
                onChanged: (value) {
                  setState(() {
                    _selectedAttributes[attr.name] = value;
                    print('Entered ${attr.name}: $value');
                  });
                },
              ),
            );
          }
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Column(
      children: [
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(
              widget.adData != null ? 'Update Ad' : 'Post Ad',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildImageSection(),
        _buildKeyInfoSection(),
        _buildMoreInfoSection(),
        _buildSubmitButton(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(key: widget.formKey, child: _buildFormFields()),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _listPriceController.dispose();
    _offerPriceController.dispose();
    _districtController.dispose();
    _landMarkController.dispose();
    _registrationValidTillController.dispose();
    _insuranceUptoController.dispose();
    _attributeControllers.forEach((_, controller) => controller.dispose());
    _animationController.dispose();
    super.dispose();
  }
}