import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:oil_gid/core/api/user_api.dart';
import 'package:oil_gid/core/storage/token_storage.dart';
import 'package:oil_gid/includes/NavigationDrawer.dart';
import 'package:oil_gid/includes/main_app_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userApi = UserApi();
  final _tokenStorage = TokenStorage();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _isEditing = false;
  bool _isSavingProfile = false;
  String? _errorMessage;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _userApi.getProfile();
      await _tokenStorage.saveUserProfile(profile);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _errorMessage = null;
        _isEditing = false;
      });
      _fillEditControllers(profile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _fillEditControllers(Map<String, dynamic> profile) {
    _nameController.text = _formatValue(profile['name']) == '—'
        ? ''
        : _formatValue(profile['name']);
    _emailController.text = _formatValue(profile['email']) == '—'
        ? ''
        : _formatValue(profile['email']);
    final rawBirthDate = _formatValue(profile['birth_date']);
    _birthDateController.text = rawBirthDate == '—'
        ? ''
        : _formatBirthDateForEdit(rawBirthDate);
  }

  String _formatBirthDateForEdit(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return value;
    }
    return '${parsed.day}.${parsed.month}.${parsed.year}';
  }

  DateTime? _parseBirthDateInput(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }

    final byDots = RegExp(r'^(\d{1,2})\.(\d{1,2})\.(\d{4})$').firstMatch(text);
    if (byDots != null) {
      final day = int.tryParse(byDots.group(1)!);
      final month = int.tryParse(byDots.group(2)!);
      final year = int.tryParse(byDots.group(3)!);
      if (day == null || month == null || year == null) return null;
      final candidate = DateTime(year, month, day);
      if (candidate.year == year &&
          candidate.month == month &&
          candidate.day == day) {
        return candidate;
      }
      return null;
    }

    return DateTime.tryParse(text);
  }

  String _toApiBirthDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  void _startEditing() {
    if (_profile == null) return;
    setState(() {
      _isEditing = true;
      _errorMessage = null;
    });
    _fillEditControllers(_profile!);
  }

  void _cancelEditing() {
    if (_profile == null) return;
    setState(() {
      _isEditing = false;
      _errorMessage = null;
    });
    _fillEditControllers(_profile!);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final parsed = _parseBirthDateInput(_birthDateController.text);
    final initial = parsed ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;
    _birthDateController.text = '${picked.day}.${picked.month}.${picked.year}';
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final birthDateRaw = _birthDateController.text.trim();
    final parsedBirthDate = _parseBirthDateInput(birthDateRaw);

    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Введите имя.';
      });
      return;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Введите корректный email.';
      });
      return;
    }
    if (birthDateRaw.isNotEmpty && parsedBirthDate == null) {
      setState(() {
        _errorMessage = 'Дата рождения должна быть в формате D.M.YYYY.';
      });
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _errorMessage = null;
    });

    try {
      final updated = await _userApi.updateProfile(
        name: name,
        email: email.isEmpty ? null : email,
        birthDate: parsedBirthDate == null ? null : _toApiBirthDate(parsedBirthDate),
      );
      await _tokenStorage.saveUserProfile(updated);
      if (!mounted) return;
      setState(() {
        _profile = updated;
        _isEditing = false;
      });
      _fillEditControllers(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
      _errorMessage = null;
    });
    try {
      await _tokenStorage.clearUser();
      await _tokenStorage.clearUserProfile();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoggingOut = false;
      });
    }
  }

  String _formatValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '—' : text;
  }

  String _formatBirthDate(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return '—';
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return text;
    }
    return '${parsed.day}.${parsed.month}.${parsed.year}';
  }

  Widget _buildInfoRow({
    required String label,
    required dynamic value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            _formatValue(value),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Не удалось загрузить профиль.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    const avatarUrl = 'https://picsum.photos/200';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isEditing && (_errorMessage ?? '').isNotEmpty) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 48,
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(strokeWidth: 2),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _formatValue(_profile!['name']),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _formatValue(_profile!['phone']),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          if (!_isEditing) ...[
            _buildInfoRow(label: 'Email', value: _profile!['email']),
            _buildInfoRow(
              label: 'Дата рождения',
              value: _formatBirthDate(_profile!['birth_date']),
            ),
            _buildInfoRow(
              label: 'Дата регистрации',
              value: _profile!['created_at'],
            ),
          ] else ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _birthDateController,
              readOnly: true,
              onTap: _pickBirthDate,
              decoration: InputDecoration(
                labelText: 'Дата рождения',
                hintText: 'D.M.YYYY',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _pickBirthDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
            if ((_errorMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSavingProfile ? null : _cancelEditing,
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSavingProfile ? null : _saveProfile,
                    child: _isSavingProfile
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Сохранить'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              label: 'Дата регистрации',
              value: _profile!['created_at'],
            ),
          ],
          const SizedBox(height: 12),
          if (!_isEditing) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSavingProfile ? null : _startEditing,
                child: const Text('Редактировать'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isLoggingOut ? null : _logout,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Выйти'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Navigationdrawer(),
      appBar: const MainAppBar(title: 'Профиль'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }
}
