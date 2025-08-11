// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
import 'package:lelamonline_flutter/core/utils/districts.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/custom_dropdown_widget.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/image_source_bottom_sheet.dart';
import 'package:lelamonline_flutter/feature/sell/view/widgets/text_field_widget.dart';

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
      Fluttertoast.showToast(
        msg: 'Ad posted successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green.withOpacity(0.8),
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
  final _makeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _listPriceController = TextEditingController();
  final _offerPriceController = TextEditingController();
  final _districtController = TextEditingController();
  final _landMarkController = TextEditingController();
  String? _selectedMake;
  String? _selectedDistrict =
      districts.isNotEmpty ? districts[0] : 'Thiruvananthapuram';
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _imageError = false;
  final int _maxImages = 5; // Maximum number of images allowed

  final List<String> _categories = [
    'Used Cars',
    'Real Estate',
    'Commercial Vehicles',
    'Other',
    'Mobile Phones',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMake = widget.initialCategory;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();
  }

  @override
  void dispose() {
    _makeController.dispose();
    _descriptionController.dispose();
    _listPriceController.dispose();
    _offerPriceController.dispose();
    _districtController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.only(bottom: 8),
            child:
                _selectedImages.isEmpty
                    ? Container(
                      width: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
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
                    )
                    : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _selectedImages.length) {
                          if (_selectedImages.length < _maxImages) {
                            return Container(
                              width: 120,
                              margin: const EdgeInsets.only(right: 12),
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
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
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
                                  width: 120,
                                  height: 150,
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
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
          ),
          if (_imageError)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Please add at least one photo',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
              ),
            ),
        ],
      ),
    );
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
                CustomDropdownWidget<String>(
                  label: 'Make',
                  value: _selectedMake,
                  items: _categories,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedMake = newValue;
                    });
                  },
                  prefixIcon: Icons.category_outlined,
                  isRequired: true,
                  itemToString: (String item) => item,
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                CustomFormField(
                  controller: _offerPriceController,
                  label: 'Offer Price',
                  prefixIcon: Icons.currency_rupee,
                  isNumberInput: true,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the offer price';
                    }
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
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                CustomFormField(
                  controller: _landMarkController,
                  label: 'Landmark',
                  prefixIcon: Icons.location_on_outlined,
                  alignLabelWithHint: true,
                ),
                const SizedBox(height: 24),
                CustomFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  prefixIcon: Icons.description_outlined,
                  alignLabelWithHint: true,
                  maxLines: 5,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _imageError = _selectedImages.isEmpty;
                      });
                      if (_selectedImages.isEmpty) return;
                      widget.onSubmit();
                    },
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
}
