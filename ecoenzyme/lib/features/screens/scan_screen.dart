import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.onImageSelected});

  final ValueChanged<XFile> onImageSelected;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _imagePicker = ImagePicker();
  bool _isPickingImage = false;

  Future<void> _pickCrop(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (image != null && mounted) {
        widget.onImageSelected(image);
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the photo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Get to know your crop.',
            style: textTheme.headlineSmall?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a clear photo of a crop or plant. EcoAI will look at the image and answer your question.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_camera_back_outlined,
                    color: Color(0xFFA5D66A),
                    size: 58,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Photograph a crop',
                  style: textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Focus on the leaves, fruit, or area you want help with. Your photo will be added to an EcoAI chat.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isPickingImage
                      ? null
                      : () => _pickCrop(ImageSource.camera),
                  icon: _isPickingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _isPickingImage ? 'Opening camera…' : 'Take a photo',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFA5D66A),
                    foregroundColor: const Color(0xFF1B4332),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _isPickingImage
                      ? null
                      : () => _pickCrop(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose from gallery'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('FOR A HELPFUL ANSWER', style: textTheme.labelMedium),
          const SizedBox(height: 12),
          const _TipCard(
            icon: Icons.wb_sunny_outlined,
            title: 'Use natural light',
            description:
                'A clear, well-lit photo helps show details on the plant.',
          ),
          const _TipCard(
            icon: Icons.center_focus_strong_outlined,
            title: 'Get close and focus',
            description:
                'Include the affected leaves or fruit without blurring.',
          ),
          const _TipCard(
            icon: Icons.chat_bubble_outline,
            title: 'Ask a specific question',
            description:
                'Add details such as crop type, location, and when symptoms began.',
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}
