import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadProfilePicturePage extends StatefulWidget {
  final Map<String, dynamic>? currentUserData;
  const UploadProfilePicturePage({super.key, this.currentUserData});

  @override
  State<UploadProfilePicturePage> createState() =>
      _UploadProfilePicturePageState();
}

class _UploadProfilePicturePageState extends State<UploadProfilePicturePage> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  // Pick image and open manual crop dialog (1:1)
  Future<void> _pickAndCrop() async {
    try {
      final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      final File pickedFile = File(picked.path);

      // Open manual crop dialog, get cropped file (or null if cancelled)
      if (!mounted) return;
      final File? cropped = await showDialog<File?>(
        context: context,
        builder: (_) => _CropDialog(imageFile: pickedFile),
      );

      final pathToUpload = (cropped != null) ? cropped.path : picked.path;
      if (pathToUpload.isEmpty) return;

      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('User belum login')));
        }
        return;
      }

      final file = File(pathToUpload);
      final ref = FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile-picture.jpg');
      final uploadTask =
          ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile.profilePicture': url,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Foto profil berhasil diunggah'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error upload profile pic: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Delete profile picture
  Future<void> _deleteProfilePicture() async {
    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Foto Profil'),
        content: const Text('Apakah Anda yakin ingin menghapus foto profil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isUploading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('User belum login')));
        }
        return;
      }

      // Delete from Firebase Storage
      await FirebaseStorage.instance
          .ref()
          .child('users/${user.uid}/profile-picture.jpg')
          .delete();

      // Update Firestore to remove profile picture
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profile.profilePicture': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Foto profil berhasil dihapus'),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error deleting profile pic: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unggah Foto Profil'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black87),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Pilih foto dari galeri, lalu crop 1:1 (geser & zoom).'),
              const SizedBox(height: 16),
              _isUploading
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickAndCrop,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pilih & Crop Foto'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _deleteProfilePicture,
                          icon: const Icon(Icons.delete),
                          label: const Text('Hapus Foto Profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[400],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Dialog crop manual 1:1 menggunakan InteractiveViewer + RepaintBoundary ---
class _CropDialog extends StatefulWidget {
  final File imageFile;
  const _CropDialog({required this.imageFile});

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  // controller for InteractiveViewer is not strictly necessary, we track transforms visually

  // Capture the RepaintBoundary and write PNG bytes to temp file
  Future<File?> _captureCroppedImage() async {
    try {
      final RenderRepaintBoundary? boundary = _repaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // Higher pixelRatio for better quality
      final ui.Image img = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData =
          await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final tmp = File(
          '${Directory.systemTemp.path}/profile_crop_${DateTime.now().millisecondsSinceEpoch}.png');
      await tmp.writeAsBytes(pngBytes);
      return tmp;
    } catch (e) {
      debugPrint('Error capturing cropped image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dialog UI: square preview with InteractiveViewer for pan/zoom
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text('Atur posisi & zoom lalu tekan "Crop & Upload"'),
          const SizedBox(height: 12),
          // Square crop area
          SizedBox(
            width: 320,
            height: 320,
            child: ClipRect(
              child: RepaintBoundary(
                key: _repaintKey,
                child: Stack(
                  fit: StackFit.passthrough,
                  children: [
                    // Background: center-cropped image that can be transformed by InteractiveViewer
                    InteractiveViewer(
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: SizedBox(
                        width: 320,
                        height: 320,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                          child: Image.file(widget.imageFile),
                        ),
                      ),
                    ),
                    // Overlay border to show crop area
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.9),
                                width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Capture and return file
                  final cropped = await _captureCroppedImage();
                  if (mounted) {
                    Navigator.pop(context, cropped);
                  }
                },
                child: const Text('Crop & Upload'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
