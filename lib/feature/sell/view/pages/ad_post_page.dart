// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/core/utils/districts.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/custom_dropdown_widget.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/image_source_bottom_sheet.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/text_field_widget.dart';

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
  final String ifDetailsIcons;
  final String detailsIcons;
  final String detailsIconsOrder;
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
    required this.ifDetailsIcons,
    required this.detailsIcons,
    required this.detailsIconsOrder,
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
      ifDetailsIcons: json['if_details_icons']?.toString() ?? '',
      detailsIcons: json['details_icons']?.toString() ?? '',
      detailsIconsOrder: json['details_icons_order']?.toString() ?? '',
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
        print('Brands response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List).map((e) => Brand.fromJson(e)).toList();
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

  static Future<List<BrandModel>> fetchBrandModels(String brandId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-model.php?token=$token&brand_id=$brandId'),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Brand models response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          return (data['data'] as List)
              .map((e) => BrandModel.fromJson(e))
              .toList();
        }
        print('No brand models found for brand_id: $brandId');
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
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/list-model-variation.php?token=$token&brands_model_id=$brandModelId',
        ),
        headers: {
          'token': token,
          'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Model variations response: $data');
        if (data['status'] == 'true' && data['data'] is List) {
          final variations =
              (data['data'] as List)
                  .map((e) => ModelVariation.fromJson(e))
                  .toList();
          // Log unique IDs and names
          print('Model variations IDs: ${variations.map((v) => v.id).toSet()}');
          print(
            'Model variations names: ${variations.map((v) => v.name).toSet()}',
          );
          return variations;
        }
        print('No model variations found for brands_model_id: $brandModelId');
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
        print('Attributes response: $data');
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
        print('Attribute variations response for ID $attributeId: $data');
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
      print('Error fetching attribute variations for ID $attributeId: $e');
      return [];
    }
  }
}

class AdPostPage extends StatefulWidget {
  final String category;
  const AdPostPage({super.key, required this.category});

  @override
  State<AdPostPage> createState() => _AdPostPageState();
}

class _AdPostPageState extends State<AdPostPage> {
  final _formKey = GlobalKey<FormState>();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'Post your Ad',
          style: TextStyle(
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
              'Post',
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
        initialCategory: widget.category,
        onSubmit: _submitForm,
      ),
    );
  }
}

class AdPostForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String initialCategory;
  final VoidCallback onSubmit;

  const AdPostForm({
    super.key,
    required this.formKey,
    required this.initialCategory,
    required this.onSubmit,
  });

  @override
  State<AdPostForm> createState() => _AdPostFormState();
}

class _AdPostFormState extends State<AdPostForm>
    with SingleTickerProviderStateMixin {
  String? _categoryId;
  List<Brand> _brands = [];
  List<BrandModel> _brandModels = [];
  List<ModelVariation> _modelVariations = [];
  Brand? _selectedBrand;
  BrandModel? _selectedBrandModel;
  ModelVariation? _selectedModelVariation;
  Map<String, String?> _selectedAttributes = {};
  final _makeController = TextEditingController();
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
  final int _maxImages = 5;

  String? _selectedDistrict =
      districts.isNotEmpty ? districts[0] : 'Thiruvananthapuram';
  void _updateModelVariations(List<ModelVariation> modelVariations) {
    setState(() {
      _modelVariations = modelVariations;
      // Ensure _selectedModelVariation is valid
      if (_selectedModelVariation != null &&
          !modelVariations.any(
            (item) => item.id == _selectedModelVariation!.id,
          )) {
        _selectedModelVariation = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _categoryId = '1'; // Use category_id=1 for Used Cars
    print('Fetching initial data for category_id: $_categoryId');

    // Fetch brands
    final brands = await AttributeValueService.fetchBrands(_categoryId ?? '1');
    print('Fetched brands: ${brands.map((b) => b.name).toList()}');
    setState(() {
      _brands = brands;
    });

    // Fetch attributes
    final attributes = await AttributeValueService.fetchAttributes(
      _categoryId ?? '1',
    );
    print(
      'Fetched attributes: ${attributes.map((a) => {'id': a.id, 'name': a.name}).toList()}',
    );
    setState(() {
      _attributes = attributes;
      _attributeIdMap = {for (var attr in attributes) attr.name: attr.id};
      _selectedAttributes = {for (var attr in attributes) attr.name: null};
    });

    // Fetch variations for each attribute
    for (var attr in attributes) {
      final variations = await AttributeValueService.fetchAttributeVariations(
        attr.id,
      );
      print(
        'Variations for ${attr.name} (ID: ${attr.id}): ${variations.map((v) => v.name).toList()}',
      );
      setState(() {
        _attributeVariations[attr.name] = variations;
      });
    }
  }

  // In the brand model selection, ensure unique model variations
  Future<void> _fetchModelVariations(String brandModelId) async {
    final modelVariations = await AttributeValueService.fetchModelVariations(
      brandModelId,
    );
    // Remove duplicates based on id or name
    final uniqueModelVariations = modelVariations
        .asMap()
        .entries
        .fold<List<ModelVariation>>([], (uniqueList, entry) {
          if (!uniqueList.any((item) => item.id == entry.value.id)) {
            uniqueList.add(entry.value);
          }
          return uniqueList;
        });
    setState(() {
      _modelVariations = uniqueModelVariations;
      // Reset selected model variation if it’s not in the new list
      if (_selectedModelVariation != null &&
          !uniqueModelVariations.contains(_selectedModelVariation)) {
        _selectedModelVariation = null;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxImages images allowed'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
          _imageError = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showImageSourceBottomSheet() {
    if (_selectedImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_maxImages images allowed'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ImageSourceBottomSheetWidget(
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
        final variation = _attributeVariations[attrName]?.firstWhere(
          (v) => v.name == selectedValue,
          orElse:
              () => AttributeVariation(
                id: '',
                attributeId: _attributeIdMap[attrName] ?? '',
                name: '',
                status: '',
                createdOn: '',
                updatedOn: '',
              ),
        );
        if (variation != null && variation.id.isNotEmpty) {
          filters[_attributeIdMap[attrName] ?? ''] = [variation.id];
        }
      }
    });
    if (_registrationValidTillController.text.isNotEmpty) {
      final regId = _attributeIdMap['Registration valid till'] ?? '27';
      filters[regId] = [_registrationValidTillController.text];
    }
    if (_insuranceUptoController.text.isNotEmpty) {
      final insId = _attributeIdMap['Insurance Upto'] ?? '28';
      filters[insId] = [_insuranceUptoController.text];
    }
    print('Filters: $filters');
    return filters;
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
                        if (index == 0)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
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
                          right: 8,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 10.0,
                                sigmaY: 10.0,
                              ),
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

  Widget _buildMoreInfoSection() {
    final List<Map<String, String>> attributes = [
      {
        'attribute_name': 'Brand',
        'attribute_value': _selectedBrand?.name ?? 'N/A',
      },
      {
        'attribute_name': 'Model',
        'attribute_value': _selectedBrandModel?.name ?? 'N/A',
      },
      {
        'attribute_name': 'Model Variation',
        'attribute_value': _selectedModelVariation?.name ?? 'N/A',
      },
      {
        'attribute_name': 'Price',
        'attribute_value':
            _listPriceController.text.isNotEmpty
                ? '₹${_listPriceController.text}'
                : 'N/A',
      },
      {
        'attribute_name': 'Landmark',
        'attribute_value':
            _landMarkController.text.isNotEmpty
                ? _landMarkController.text
                : 'N/A',
      },
      {
        'attribute_name': 'Description',
        'attribute_value':
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : 'N/A',
      },
      {
        'attribute_name': 'District',
        'attribute_value': _selectedDistrict ?? 'N/A',
      },
      {
        'attribute_name': 'Registration valid till',
        'attribute_value':
            _registrationValidTillController.text.isNotEmpty
                ? _registrationValidTillController.text
                : 'N/A',
      },
      {
        'attribute_name': 'Insurance Upto',
        'attribute_value':
            _insuranceUptoController.text.isNotEmpty
                ? _insuranceUptoController.text
                : 'N/A',
      },
      ..._attributes.map(
        (attr) => {
          'attribute_name': attr.name,
          'attribute_value': _selectedAttributes[attr.name] ?? 'N/A',
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'More Info',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ...attributes
            .where(
              (attr) =>
                  attr['attribute_value'] != 'N/A' &&
                  attr['attribute_value']!.isNotEmpty,
            )
            .map(
              (attr) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      attr['attribute_name']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        attr['attribute_value']!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  void _submitForm() async {
    setState(() {
      _imageError = _selectedImages.isEmpty;
    });
    if (_imageError || !widget.formKey.currentState!.validate()) {
      return;
    }

    if (_categoryId == null) {
      Fluttertoast.showToast(
        msg: 'Category ID is missing',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    // Validate required attributes
    final requiredAttributes = [
      'Year',
      'No of owners',
      'Fuel Type',
      'Transmission',
      'KM Range',
      'Sold by',
    ];
    final missingAttributes =
        requiredAttributes
            .where(
              (attr) =>
                  _selectedAttributes[attr] == null ||
                  _selectedAttributes[attr]!.isEmpty,
            )
            .toList();
    if (missingAttributes.isNotEmpty) {
      Fluttertoast.showToast(
        msg: 'Please select: ${missingAttributes.join(", ")}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    final filters = getFilters();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AttributeValueService.baseUrl}/add-post.php'),
    );
    request.headers.addAll({'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln'});
    request.fields.addAll({
      'token': AttributeValueService.token,
      'user_id': '4', // Replace with actual user ID
      'title': _makeController.text,
      'category_id': _categoryId ?? '1',
      'brand': _selectedBrand?.id ?? '',
      'model': _selectedBrandModel?.id ?? '',
      'model_variation': _selectedModelVariation?.id ?? '',
      'description': _descriptionController.text,
      'price': _listPriceController.text,
      'filters': jsonEncode(filters),
      'parent_zone_id': '2', // Replace with actual zone ID
      'land_mark': _landMarkController.text,
      'district': _selectedDistrict ?? '',
    });

    for (var image in _selectedImages) {
      request.files.add(
        await http.MultipartFile.fromPath('images[]', image.path),
      );
    }

    try {
      final response = await request.send();
      final responseString = await response.stream.bytesToString();
      print('Add post response: $responseString');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(responseString);
        if (responseData['status'] == 'true') {
          Fluttertoast.showToast(
            msg: 'Ad posted successfully',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.green.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
          widget.onSubmit();
        } else {
          Fluttertoast.showToast(
            msg: 'Failed to post ad: ${responseData['message']}',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.withOpacity(0.8),
            textColor: Colors.white,
            fontSize: 16.0,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to post ad: HTTP ${response.statusCode}',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } catch (e) {
      print('Error submitting form: $e');
      Fluttertoast.showToast(
        msg: 'Error: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  IconData _getIconForAttribute(String attributeName) {
    switch (attributeName) {
      case 'Year':
        return Icons.calendar_today;
      case 'No of owners':
        return Icons.person;
      case 'Fuel Type':
        return Icons.local_gas_station;
      case 'Transmission':
        return Icons.settings;
      case 'KM Range':
        return Icons.speed;
      case 'Sold by':
        return Icons.person;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: widget.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                CustomDropdownWidget<Brand>(
                  label: 'Brand',
                  value: _selectedBrand,
                  items: _brands,
                  onChanged: (Brand? newValue) async {
                    setState(() {
                      _selectedBrand = newValue;
                      _selectedBrandModel = null;
                      _selectedModelVariation = null;
                      _brandModels = [];
                      _modelVariations = [];
                    });
                    if (newValue != null) {
                      final brandModels =
                          await AttributeValueService.fetchBrandModels(
                            newValue.id,
                          );
                      setState(() {
                        _brandModels = brandModels;
                      });
                    }
                  },
                  prefixIcon: Icons.branding_watermark,
                  isRequired: true,
                  itemToString: (Brand item) => item.name,
                ),
                const SizedBox(height: 12),
                CustomDropdownWidget<BrandModel>(
                  label: 'Model',
                  value: _selectedBrandModel,
                  items: _brandModels,
                  onChanged: (BrandModel? newValue) async {
                    setState(() {
                      _selectedBrandModel = newValue;
                      _selectedModelVariation = null;
                      _modelVariations = [];
                    });
                    if (newValue != null) {
                      final modelVariations =
                          await AttributeValueService.fetchModelVariations(
                            newValue.id,
                          );
                      _updateModelVariations(modelVariations);
                    }
                  },
                  prefixIcon: Icons.model_training,
                  isRequired: true,
                  itemToString: (BrandModel item) => item.name,
                ),
                const SizedBox(height: 12),
                CustomDropdownWidget<ModelVariation>(
                  label: 'Model Variation',
                  value: _selectedModelVariation,
                  items: _modelVariations,
                  onChanged: (ModelVariation? newValue) {
                    setState(() {
                      _selectedModelVariation = newValue;
                      print('Selected Model Variation: ${newValue?.name}');
                    });
                  },
                  prefixIcon: Icons.category,
                  isRequired: false,
                  itemToString: (ModelVariation item) => item.name,
                  validator: (ModelVariation? value) {
                    if (_modelVariations.isEmpty) {
                      return 'No model variations available';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _makeController,
                  label: 'Make',
                  prefixIcon: Icons.directions_car,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter make';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _listPriceController,
                  label: 'List Price',
                  prefixIcon: Icons.currency_rupee,
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
                      final offerPrice = double.tryParse(
                        _offerPriceController.text,
                      );
                      if (offerPrice != null && offerPrice > listPrice) {
                        return 'List price must be greater than or equal to offer price';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _offerPriceController,
                  label: 'Offer Price',
                  prefixIcon: Icons.currency_rupee,
                  isNumberInput: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final offerPrice = double.tryParse(value);
                    if (offerPrice == null) {
                      return 'Please enter a valid number';
                    }
                    if (_listPriceController.text.isNotEmpty) {
                      final listPrice = double.tryParse(
                        _listPriceController.text,
                      );
                      if (listPrice != null && offerPrice > listPrice) {
                        return 'Offer price must be less than or equal to list price';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomDropdownWidget<String>(
                  label: 'District',
                  value: _selectedDistrict,
                  items: districts,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDistrict = newValue;
                    });
                  },
                  prefixIcon: Icons.location_on_outlined,
                  isRequired: true,
                  itemToString: (String item) => item,
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _landMarkController,
                  label: 'Landmark',
                  prefixIcon: Icons.location_on_outlined,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _registrationValidTillController,
                  label: 'Registration Valid Till',
                  prefixIcon: Icons.date_range,
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _insuranceUptoController,
                  label: 'Insurance Upto',
                  prefixIcon: Icons.security,
                ),
                const SizedBox(height: 12),
                CustomFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  prefixIcon: Icons.description_outlined,
                  alignLabelWithHint: true,
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                ..._attributes.map((attr) {
                  final isRequired = [
                    'Year',
                    'No of owners',
                    'Fuel Type',
                    'Transmission',
                    'KM Range',
                    'Sold by',
                  ].contains(attr.name);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomDropdownWidget<String>(
                      label: attr.name,
                      value: _selectedAttributes[attr.name],
                      items:
                          _attributeVariations[attr.name]
                              ?.map((v) => v.name)
                              .toList() ??
                          ['No options available'],
                      onChanged: (String? newValue) {
                        if (newValue != null &&
                            newValue != 'No options available') {
                          setState(() {
                            _selectedAttributes[attr.name] = newValue;
                            print('Selected ${attr.name}: $newValue');
                          });
                        }
                      },
                      prefixIcon: _getIconForAttribute(attr.name),
                      isRequired: isRequired,
                      itemToString: (String item) => item,
                    ),
                  );
                }),
                const SizedBox(height: 24),
                _buildMoreInfoSection(),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'Post Ad',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _descriptionController.dispose();
    _listPriceController.dispose();
    _offerPriceController.dispose();
    _districtController.dispose();
    _landMarkController.dispose();
    _registrationValidTillController.dispose();
    _insuranceUptoController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
