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
//  final String ifDetailsIcons;
//  final String detailsIcons;
//  final String detailsIconsOrder;
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
    //required this.ifDetailsIcons,
   // required this.detailsIcons,
   // required this.detailsIconsOrder,
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
    //ifDetailsIcons: json['if_details_icons']?.toString() ?? '',
    //  detailsIcons: json['details_icons']?.toString() ?? '',
     // detailsIconsOrder: json['details_icons_order']?.toString() ?? '',
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
  final String categoryId;
  const AdPostPage({super.key, required this.categoryId});

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
        categoryId: widget.categoryId,
        onSubmit: _submitForm,
      ),
    );
  }
}

class AdPostForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final String categoryId;
  final VoidCallback onSubmit;

  const AdPostForm({
    super.key,
    required this.formKey,
    required this.categoryId,
    required this.onSubmit,
  });

  @override
  State<AdPostForm> createState() => _AdPostFormState();
}

class _AdPostFormState extends State<AdPostForm> with SingleTickerProviderStateMixin {
  String? _categoryId;
  List<Brand> _brands = [];
  List<BrandModel> _brandModels = [];
  List<ModelVariation> _modelVariations = [];
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
  final int _maxImages = 10; // Allow up to 10 images
  int _coverImageIndex = 0; // Tracks the index of the cover image
  final Map<String, TextEditingController> _attributeControllers = {};

  String? _selectedDistrict = districts.isNotEmpty ? districts[0] : 'Thiruvananthapuram';

  List<String> _getRequiredAttributes(String categoryId) {
    switch (categoryId) {
      case '1': // Used Cars
        return [
          'Year',
          'No of owners',
          'Fuel Type',
          'Transmission',
          'KM Range',
          'Sold by',
        ];
      case '2': // Real Estate
        return [
          'Property Type',
          'Area',
          'Location',
        ];
      case '3': // Commercial Vehicles
        return [
          'Vehicle Type',
          'Year',
          'Fuel Type',
        ];
      case '4': // Others
        return [
          'Item Type',
          'Condition',
        ];
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

  Future<void> _fetchInitialData() async {
    _categoryId = widget.categoryId;
    if (_categoryId == null || _categoryId!.isEmpty) {
      print('Error: categoryId is null or empty');
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
    print('Fetching initial data for category_id: $_categoryId');

    // Clear previous data to prevent cross-category contamination
    setState(() {
      _brands = [];
      _brandModels = [];
      _modelVariations = [];
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

    // Fetch brands for the category
    final brands = await AttributeValueService.fetchBrands(_categoryId!);
    setState(() {
      _brands = brands;
      print('Loaded brands for category $_categoryId: ${brands.map((b) => b.name).toList()}');
    });

    // Fetch attributes for the category
    final attributes = await AttributeValueService.fetchAttributes(_categoryId!);
    setState(() {
      _attributes = attributes;
      _attributeIdMap = {for (var attr in attributes) attr.name: attr.id};
      _selectedAttributes = {for (var attr in attributes) attr.name: null};
      for (var attr in attributes) {
        _attributeControllers[attr.name] = TextEditingController();
      }
      print('Loaded attributes for category $_categoryId: ${attributes.map((a) => a.name).toList()}');
    });

    // Fetch attribute variations
    for (var attr in attributes) {
      final variations = await AttributeValueService.fetchAttributeVariations(attr.id);
      setState(() {
        _attributeVariations[attr.name] = variations;
        print('Loaded variations for attribute ${attr.name} (ID: ${attr.id}): ${variations.map((v) => v.name).toList()}');
      });
    }
  }

  Future<void> _fetchModelVariations(String brandModelId) async {
    final modelVariations = await AttributeValueService.fetchModelVariations(brandModelId, _categoryId!);
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
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (image != null) {
          setState(() {
            _selectedImages.add(image);
            _imageError = false;
            // If this is the first image, set it as cover
            if (_selectedImages.length == 1) {
              _coverImageIndex = 0;
            }
            print('Added camera image: ${image.path}');
          });
        }
      } else {
        final List<XFile>? images = await _imagePicker.pickMultiImage(
          imageQuality: 80,
        );
        if (images != null && images.isNotEmpty) {
          setState(() {
            final newImages = images.take(_maxImages - _selectedImages.length).toList();
            _selectedImages.addAll(newImages);
            _imageError = false;
            // If no images existed before, set the first new image as cover
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
            orElse: () => AttributeVariation(
              id: '',
              attributeId: _attributeIdMap[attrName] ?? '',
              name: '',
              status: '',
              createdOn: '',
              updatedOn: '',
            ),
          );
          if (variation.id.isNotEmpty) {
            filters[_attributeIdMap[attrName] ?? ''] = [variation.id];
          }
        } else {
          filters[_attributeIdMap[attrName] ?? ''] = [selectedValue];
        }
      }
    });
    if (_categoryId == '1' && _registrationValidTillController.text.isNotEmpty) {
      final regId = _attributeIdMap['Registration valid till'] ?? '27';
      filters[regId] = [_registrationValidTillController.text];
    }
    if (_categoryId == '1' && _insuranceUptoController.text.isNotEmpty) {
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
                        // Cover Photo Label
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
                        // Set as Cover Button
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
                        // Remove Image Button
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
                                  icon: const Icon(Icons.close, size: 20, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                      // Adjust cover image index if necessary
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

    final requiredAttributes = _getRequiredAttributes(_categoryId!);
    final missingAttributes = requiredAttributes
        .where((attr) => _selectedAttributes[attr] == null || _selectedAttributes[attr]!.isEmpty)
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

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AttributeValueService.baseUrl}/add-post.php'),
    );
    request.headers.addAll({'Cookie': 'PHPSESSID=fmnu7gp638cltiqjss9380hfln'});
    request.fields.addAll({
      'token': AttributeValueService.token,
      'user_id': '4',
      'title': _titleController.text,
      'category_id': _categoryId!,
      'brand': _selectedBrand?.id ?? '',
      'model': _selectedBrandModel?.id ?? '',
      'model_variation': _selectedModelVariation?.id ?? '',
      'description': _descriptionController.text,
      'price': _listPriceController.text,
      'filters': jsonEncode(getFilters()),
      'parent_zone_id': '2',
      'land_mark': _landMarkController.text,
      'district': _selectedDistrict ?? '',
    });

    // Add cover image first (if it exists)
    if (_selectedImages.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('images[]', _selectedImages[_coverImageIndex].path, filename: 'cover_${_selectedImages[_coverImageIndex].name}'));
      // Add remaining images
      for (var i = 0; i < _selectedImages.length; i++) {
        if (i != _coverImageIndex) {
          request.files.add(await http.MultipartFile.fromPath('images[]', _selectedImages[i].path));
        }
      }
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

  // IconData _getIconForAttribute(String attributeName) {
  //   switch (attributeName) {
  //     case 'Year':
  //       return Icons.calendar_today;
  //     case 'No of owners':
  //       return Icons.person;
  //     case 'Fuel Type':
  //       return Icons.local_gas_station;
  //     case 'Transmission':
  //       return Icons.settings;
  //     case 'KM Range':
  //       return Icons.speed;
  //     case 'Sold by':
  //       return Icons.person;
  //     case 'Property Type':
  //       return Icons.home;
  //     case 'Area':
  //       return Icons.square_foot;
  //     case 'Location':
  //       return Icons.location_on;
  //     case 'Vehicle Type':
  //       return Icons.directions_car;
  //     case 'Item Type':
  //       return Icons.category;
  //     case 'Condition':
  //       return Icons.check_circle;
  //     default:
  //       return Icons.info;
  //   }
  // }

  Widget _buildFormFields() {
    List<Widget> fields = [];

    // Add Photos Section
    fields.addAll([
      const SizedBox(height: 24),
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
    ]);

    // Key Information Section
    fields.addAll([
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
        label: _categoryId == '2' ? 'Property Developer' : 'Brand',
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
          if (newValue != null && _categoryId != null) {
            final brandModels = await AttributeValueService.fetchBrandModels(newValue.id, _categoryId!);
            setState(() {
              _brandModels = brandModels;
              print('Loaded brand models for brand ${newValue.name}: ${brandModels.map((m) => m.name).toList()}');
            });
          }
        },
      //  prefixIcon: Icons.branding_watermark,
        isRequired: true,
        itemToString: (Brand item) => item.name,
        validator: (Brand? value) => value == null ? 'Please select a ${_categoryId == '2' ? 'property developer' : 'brand'}' : null,
        hintText: '',
      ),
      const SizedBox(height: 12),
    ]);

    // Conditionally show Brand Model dropdown if models are available
    if (_brandModels.isNotEmpty) {
      fields.addAll([
        CustomDropdownWidget<BrandModel>(
          label: _categoryId == '2' ? 'Project' : 'Model',
          value: _selectedBrandModel,
          items: _brandModels,
          onChanged: (BrandModel? newValue) async {
            setState(() {
              _selectedBrandModel = newValue;
              _selectedModelVariation = null;
              _modelVariations = [];
              print('Selected brand model: ${newValue?.name} (ID: ${newValue?.id})');
            });
            if (newValue != null && _categoryId != null) {
              await _fetchModelVariations(newValue.id);
            }
          },
         // prefixIcon: Icons.model_training,
          isRequired: true,
          itemToString: (BrandModel item) => item.name,
          validator: (BrandModel? value) => value == null ? 'Please select a ${_categoryId == '2' ? 'project' : 'model'}' : null,
          hintText: '',
        ),
        const SizedBox(height: 12),
      ]);
    }

    // Conditionally show Model Variation dropdown if variations are available
    if (_modelVariations.isNotEmpty) {
      fields.addAll([
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
         // prefixIcon: Icons.category,
          isRequired: false,
          itemToString: (ModelVariation item) => item.name,
          validator: null,
          hintText: 'Select a variation',
        ),
        const SizedBox(height: 12),
      ]);
    }

    fields.addAll([
      CustomFormField(
        controller: _titleController,
        label: 'Title',
       // prefixIcon: Icons.title,
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
       // prefixIcon: Icons.currency_rupee,
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
      // CustomFormField(
      //   controller: _offerPriceController,
      //   label: 'Offer Price',
      //   prefixIcon: Icons.currency_rupee,
      //   isNumberInput: true,
      //   validator: (value) {
      //     if (value == null || value.isEmpty) return null;
      //     final offerPrice = double.tryParse(value);
      //     if (offerPrice == null) {
      //       return 'Please enter a valid number';
      //     }
      //     if (_listPriceController.text.isNotEmpty) {
      //       final listPrice = double.tryParse(_listPriceController.text);
      //       if (listPrice != null && offerPrice > listPrice) {
      //         return 'Offer price must be less than or equal to list price';
      //       }
      //     }
      //     return null;
      //   },
      //   onChanged: (value) {},
      // ),
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
       // prefixIcon: Icons.location_on_outlined,
        isRequired: true,
        itemToString: (String item) => item,
        validator: (String? value) => value == null ? 'Please select a district' : null,
        hintText: '',
      ),
      const SizedBox(height: 12),
      CustomFormField(
        controller: _landMarkController,
        label: 'Landmark',
       // prefixIcon: Icons.location_on_outlined,
        alignLabelWithHint: true,
        onChanged: (value) {},
      ),
      const SizedBox(height: 12),
    ]);

    if (_categoryId == '1') {
      fields.addAll([
        CustomFormField(
          controller: _registrationValidTillController,
          label: 'Registration Valid Till',
       //   prefixIcon: Icons.date_range,
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
        CustomFormField(
          controller: _insuranceUptoController,
          label: 'Insurance Upto',
        //  prefixIcon: Icons.security,
          onChanged: (value) {},
        ),
        const SizedBox(height: 12),
      ]);
    }

    fields.add(CustomFormField(
      controller: _descriptionController,
      label: 'Description',
     // prefixIcon: Icons.description_outlined,
      alignLabelWithHint: true,
      maxLines: 5,
      onChanged: (value) {},
    ));

    // More Info Section
    if (_attributes.isNotEmpty) {
      fields.addAll([
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
      ]);

      fields.addAll(_attributes.map((attr) {
        final isRequired = _getRequiredAttributes(_categoryId ?? '').contains(attr.name);
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
            //  prefixIcon: _getIconForAttribute(attr.name),
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
              //prefixIcon: _getIconForAttribute(attr.name),
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
      }).toList());
    }

    fields.addAll([
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: const Text(
            'Post Ad',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 24),
    ]);

    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: fields);
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
            child: _buildFormFields(),
          ),
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