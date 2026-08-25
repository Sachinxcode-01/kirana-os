import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final ValueChanged<XFile?> onImageSelected;
  final VoidCallback? onImageRemoved;
  final bool isLoading;

  const ProductImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageSelected,
    this.onImageRemoved,
    this.isLoading = false,
  });

  @override
  State<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends State<ProductImagePicker> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedFile;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Image file exceeds maximum size limit of 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = image;
        });
        widget.onImageSelected(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPickerSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Product Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt_outlined, color: Colors.blue),
                title: const Text('Take Photo (Camera)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: Colors.green),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedFile != null ||
                  (widget.currentImageUrl != null &&
                      widget.currentImageUrl!.isNotEmpty))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Remove Image',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedFile = null;
                    });
                    widget.onImageSelected(null);
                    if (widget.onImageRemoved != null) {
                      widget.onImageRemoved!();
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedFile != null) {
      return Image.file(
        File(_selectedFile!.path),
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    }

    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      if (widget.currentImageUrl!.startsWith('http://') ||
          widget.currentImageUrl!.startsWith('https://')) {
        return Image.network(
          widget.currentImageUrl!,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        );
      } else if (File(widget.currentImageUrl!).existsSync()) {
        return Image.file(
          File(widget.currentImageUrl!),
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        );
      }
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 32),
          SizedBox(height: 4),
          Text(
            'Add Image',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.isLoading ? null : _showPickerSourceSheet,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              if (widget.isLoading)
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
