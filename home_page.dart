import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'background_remover.dart';
import 'object_remover.dart';
import 'image_enhancer.dart';
import 'text_remover.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A4E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF5B3FA0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      size: 13,
                      color: Color(0xFFA78BFA),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AI POWERED',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFC4A9F5),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Title
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Magic ',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    TextSpan(
                      text: 'Eraser',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Transform your photos with AI — fast, beautiful, effortless.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 24),

              // Stat Row
              Row(
                children: [
                  _buildStatCard('4', 'AI tools'),
                  const SizedBox(width: 10),
                  _buildStatCard('1-tap', 'Processing'),
                  const SizedBox(width: 10),
                  _buildStatCard('HD', 'Export quality'),
                ],
              ),

              const SizedBox(height: 24),

              // Upload Zone
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFA78BFA),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Drag & drop your image here\nor ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'browse from gallery',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 28),

              // Features Label
              const Text(
                'FEATURES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 12),

              // Feature Cards
              _buildFeatureCard(
                icon: Icons.layers_clear,
                title: 'Background Remover',
                description: 'Instantly cut out backgrounds with precision',
                iconBg: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF7C3AED),
                onTap: () => _openFeatureScreen(
                  () => BackgroundRemover(initialImage: _selectedImage),
                ),
              ),
              const SizedBox(height: 10),
              _buildFeatureCard(
                icon: Icons.auto_fix_high,
                title: 'Object Remover',
                description: 'Erase unwanted objects seamlessly',
                iconBg: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFBE185D),
                onTap: () => _openFeatureScreen(
                  () => ObjectRemover(initialImage: _selectedImage),
                ),
              ),
              const SizedBox(height: 10),
              _buildFeatureCard(
                icon: Icons.auto_awesome,
                title: 'Image Enhancer',
                description: 'Boost colors, clarity, and sharpness',
                iconBg: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF047857),
                onTap: () => _openFeatureScreen(
                  () => ImageEnhancer(initialImage: _selectedImage),
                ),
              ),
              const SizedBox(height: 10),
              _buildFeatureCard(
                icon: Icons.text_fields,
                title: 'Text Remover',
                description: 'Clean text and watermarks from images',
                iconBg: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF1D4ED8),
                onTap: () => _openFeatureScreen(
                  () => TextRemover(initialImage: _selectedImage),
                ),
              ),

              const SizedBox(height: 28),

              // Recent Edits
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT EDITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRecentThumb('Background'),
                    const SizedBox(width: 10),
                    _buildRecentThumb('Enhanced'),
                    const SizedBox(width: 10),
                    _buildRecentThumb('Object'),
                    const SizedBox(width: 10),
                    _buildRecentThumb('Text'),
                    const SizedBox(width: 10),
                    _buildAddThumb(),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconBg,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentThumb(String label) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(Icons.image_outlined, size: 26, color: Colors.grey),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddThumb() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child: const Center(child: Icon(Icons.add, size: 26, color: Colors.grey)),
    );
  }

  void _openFeatureScreen(Widget Function() pageBuilder) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => pageBuilder()));
  }
}
