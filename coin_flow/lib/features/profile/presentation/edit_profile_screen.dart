import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  // Переменные для работы с фото
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 1. Выбор изображения из галереи
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75, // Сжимаем немного для скорости
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора фото: $e')),
      );
    }
  }

  // 2. Загрузка изображения в Firebase Storage
  Future<String?> _uploadImage(String userId) async {
    if (_selectedImage == null) return null;

    try {
      // Ссылка: avatars/user_id.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      // Загружаем файл
      await storageRef.putFile(_selectedImage!);

      // Получаем URL
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw Exception('Не удалось загрузить фото: $e');
    }
  }

  // 3. Сохранение профиля (Имя + Фото)
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // Если выбрали новое фото, загружаем его
      if (_selectedImage != null) {
        final photoUrl = await _uploadImage(_user!.uid);
        if (photoUrl != null) {
          await _user?.updatePhotoURL(photoUrl);
        }
      }

      // Обновляем имя, если изменилось
      if (_nameController.text.trim() != _user?.displayName) {
        await _user?.updateDisplayName(_nameController.text.trim());
      }

      await _user?.reload(); // Обновляем локальный кеш юзера

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль успешно обновлен')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage, // Клик для смены фото
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.5),
                          width: 2,
                        ),
                        image: _getImageProvider(), // Отображаем фото
                      ),
                      child: _selectedImage == null && _user?.photoURL == null
                          ? Center(
                        child: Text(
                          _user?.email?.substring(0, 1).toUpperCase() ?? "U",
                          style: GoogleFonts.inter(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Ваше имя",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Введите имя',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Email (нельзя изменить)",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Text(
                    _user?.email ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("Сохранить изменения"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Вспомогательный метод для выбора источника картинки
  DecorationImage? _getImageProvider() {
    if (_selectedImage != null) {
      return DecorationImage(
        image: FileImage(_selectedImage!),
        fit: BoxFit.cover,
      );
    } else if (_user?.photoURL != null) {
      return DecorationImage(
        image: NetworkImage(_user!.photoURL!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }
}