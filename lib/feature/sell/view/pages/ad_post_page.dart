import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lelamonline_flutter/core/theme/app_theme.dart';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Processing your ad...')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post your Ad'),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _submitForm, child: const Text('Post')),
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

class _AdPostFormState extends State<AdPostForm> {
  final _makecontroller = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _districtController = TextEditingController();
  final _landMarkController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDistrict;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAuctionable = false;

  final List<String> _districts = [
    'Ernakulam',
    'Idukki',
    'Kannur',
    'Kasaragod',
    'Kollam',
    'Kottayam',
    'Kozhikode',
    'Malappuram',
    'Palakkad',
    'Pathanamthitta',
    'Thiruvananthapuram',
    'Thrissur',
    'Wayanad',
  ];

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
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _makecontroller.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImageSourceBottomSheet() {
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
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 32),
                onPressed: _showImageSourceBottomSheet,
              ),
            );
          }
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImages[index].path),
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        setState(() {
                          _selectedImages.removeAt(index);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: widget.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Photos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildImagePicker(),
              const SizedBox(height: 20),
              //! =======================Make Dropdown=======================
              CustomDropdownWidget<String>(
                label: 'Make',
                value: _selectedCategory,
                items: _categories,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                prefixIcon: Icons.category_outlined,
                isRequired: true,
                itemToString: (String item) => item,
              ),
              const SizedBox(height: 20),
              CustomFormField(
                controller: _priceController,
                label: 'Price',
                prefixIcon: Icons.currency_rupee,
                isNumberInput: true,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              CustomDropdownWidget<String>(
                label: 'District',
                value: _selectedDistrict,
                items: _districts,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDistrict = newValue;
                  });
                },
                prefixIcon: Icons.location_on_outlined,
                isRequired: true,
                itemToString: (String item) => item,
              ),

              const SizedBox(height: 20),
              CustomFormField(
                controller: _landMarkController,
                label: 'Landmark',
                prefixIcon: Icons.location_on_outlined,
                alignLabelWithHint: true,
              ),
              const SizedBox(height: 20),
              CustomFormField(
                controller: _descriptionController,
                label: 'Description',
                prefixIcon: Icons.description_outlined,
                alignLabelWithHint: true,
                maxLines: 5,
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text('Allow Auction'),
                subtitle: const Text('Enable bidding on your item'),
                value: _isAuctionable,
                onChanged: (bool value) {
                  setState(() {
                    _isAuctionable = value;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Post Ad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
