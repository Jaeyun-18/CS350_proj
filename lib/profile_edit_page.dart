import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth/auth_service.dart';
import 'profile_storage.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.uid,
    required this.currentDisplayName,
    required this.currentPhotoUrl,
  });

  final String uid;
  final String currentDisplayName;
  final String? currentPhotoUrl;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _text = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _green = Color(0xFF22C55E);
  static const Color _border = Color(0xFFE2E8F0);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _nameController;
  File? _pickedImage;
  bool _isSaving = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentDisplayName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_isPicking || _isSaving) {
      return;
    }
    setState(() => _isPicking = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (!mounted || picked == null) {
        return;
      }
      setState(() {
        _pickedImage = File(picked.path);
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $error')));
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newName = _nameController.text.trim();
      if (newName != widget.currentDisplayName.trim()) {
        await AuthService.instance.updateDisplayName(
          uid: widget.uid,
          currentDisplayName: widget.currentDisplayName,
          newDisplayName: newName,
        );
      }

      if (_pickedImage != null) {
        final url = await ProfileStorage.instance.uploadAvatar(
          uid: widget.uid,
          file: _pickedImage!,
        );
        await AuthService.instance.updatePhotoUrl(
          uid: widget.uid,
          photoUrl: url,
        );
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyAuthMessage(error))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  ImageProvider? _avatarImage() {
    if (_pickedImage != null) {
      return FileImage(_pickedImage!);
    }
    final url = widget.currentPhotoUrl;
    if (url != null && url.isNotEmpty) {
      return NetworkImage(url);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.currentDisplayName.isNotEmpty
        ? widget.currentDisplayName[0].toUpperCase()
        : 'W';
    final avatar = _avatarImage();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: _text,
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.3),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: avatar == null
                            ? const LinearGradient(
                                colors: [Color(0xFF72DCA0), Color(0xFF22C55E)],
                              )
                            : null,
                        image: avatar == null
                            ? null
                            : DecorationImage(image: avatar, fit: BoxFit.cover),
                      ),
                      child: avatar == null
                          ? Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 44,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: _green,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _isPicking || _isSaving
                              ? null
                              : _pickFromGallery,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _isPicking || _isSaving ? null : _pickFromGallery,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(
                    _pickedImage == null
                        ? 'Change profile picture'
                        : 'Pick a different picture',
                  ),
                  style: TextButton.styleFrom(foregroundColor: _green),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'NICKNAME',
                style: TextStyle(
                  color: _muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                validator: AuthService.instance.validateNickname,
                decoration: InputDecoration(
                  hintText: 'Your display name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _green, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nicknames must be unique across WeBuyDivvy.',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
