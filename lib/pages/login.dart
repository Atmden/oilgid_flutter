import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oil_gid/core/api/auth_api.dart';
import 'package:oil_gid/core/api/auth_registration_service.dart';
import 'package:oil_gid/core/storage/token_storage.dart';

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final limited = _extractLocalDigits(newValue.text);
    final formatted = _format(limited);
    final beforeCursor = newValue.selection.baseOffset <= 0
        ? ''
        : newValue.text.substring(0, newValue.selection.baseOffset);
    final localDigitsBeforeCursor = _extractLocalDigits(beforeCursor).length;
    final cursorOffset = _cursorOffsetForLocalDigits(
      formatted,
      min(localDigitsBeforeCursor, limited.length),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorOffset),
    );
  }

  String _extractLocalDigits(String text) {
    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('7')) {
      digits = digits.substring(1);
    }
    return digits.substring(0, min(10, digits.length));
  }

  int _cursorOffsetForLocalDigits(String formatted, int localDigitsCount) {
    if (localDigitsCount <= 0) {
      return 2; // after +7
    }

    var seenAllDigits = 0;
    var seenLocalDigits = 0;
    for (var i = 0; i < formatted.length; i++) {
      final char = formatted[i];
      final isDigit = char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
      if (!isDigit) continue;

      seenAllDigits++;
      // First digit in formatted string is country code "7".
      if (seenAllDigits == 1) continue;

      seenLocalDigits++;
      if (seenLocalDigits == localDigitsCount) {
        return i + 1;
      }
    }

    return formatted.length;
  }

  String _format(String localDigits) {
    final buffer = StringBuffer()..write('+7');

    if (localDigits.isNotEmpty) {
      buffer.write(' (');
      buffer.write(localDigits.substring(0, min(3, localDigits.length)));
      if (localDigits.length >= 3) {
        buffer.write(')');
      }
    }

    if (localDigits.length > 3) {
      buffer.write(' ');
      buffer.write(localDigits.substring(3, min(6, localDigits.length)));
    }

    if (localDigits.length > 6) {
      buffer.write('-');
      buffer.write(localDigits.substring(6, min(8, localDigits.length)));
    }

    if (localDigits.length > 8) {
      buffer.write('-');
      buffer.write(localDigits.substring(8, min(10, localDigits.length)));
    }

    return buffer.toString();
  }
}

enum _AuthStep {
  phoneInput,
  codeVerify,
  profileInput,
  passwordCreate,
  pinCreate,
  pinLogin,
  passwordLogin,
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _tokenStorage = TokenStorage();
  final _authApi = AuthApi();
  final _registrationService = AuthRegistrationService();

  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginPinController = TextEditingController();
  final _phoneMaskFormatter = _PhoneMaskFormatter();

  _AuthStep _step = _AuthStep.phoneInput;
  bool _isLoading = false;
  bool _isSmsSendDisabled = false;
  bool _isConsentAccepted = false;
  String? _errorMessage;
  String _normalizedPhone = '';
  String? _storedPhone;
  String? _storedPasswordHash;
  String? _storedPinHash;
  String _rawPassword = '';
  String _pinDraft = '';
  String _pinConfirmDraft = '';
  bool _isPinConfirmationStep = false;

  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7';
    _loadExistingRegistration();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsCodeController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _loginPasswordController.dispose();
    _loginPinController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingRegistration() async {
    final isRegistered = await _tokenStorage.isPhoneRegistrationCompleted();
    if (!mounted) return;

    if (isRegistered) {
      _storedPhone = await _tokenStorage.getRegisteredPhone();
      _storedPasswordHash = await _tokenStorage.getPasswordHash();
      _storedPinHash = await _tokenStorage.getPinHash();
      setState(() {
        _step = _AuthStep.pinLogin;
      });
    }
  }

  String _hashValue(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }

  String? _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('7')) {
      digits = digits.substring(1);
    }
    if (digits.length != 10) {
      return null;
    }
    return '+7$digits';
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _isLoading = value;
    });
  }

  Future<void> _sendSmsCode() async {
    if (_isSmsSendDisabled) {
      return;
    }

    final normalized = _normalizePhone(_phoneController.text);
    if (normalized == null) {
      _setError('Введите номер в международном формате, например +77011234567.');
      return;
    }

    _setLoading(true);
    setState(() {
      _isSmsSendDisabled = true;
    });
    _setError('');
    _normalizedPhone = normalized;

    try {
      await _authApi.sendCode(normalized);
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.codeVerify;
        _errorMessage = null;
      });
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSmsSendDisabled = false;
        });
      }
      _setLoading(false);
    }
  }

  Future<void> _verifySmsCode() async {
    final code = _smsCodeController.text.trim();
    if (code.length < 4) {
      _setError('Введите корректный код.');
      return;
    }

    _setLoading(true);
    _setError('');

    try {
      final result = await _authApi.verifyCode(
        phone: _normalizedPhone,
        code: code,
      );
      if (!mounted) return;
      if (result) {
        setState(() {
          _step = _AuthStep.profileInput;
          _errorMessage = null;
        });
      } else {
        _setError('Неверный код подтверждения.');
      }
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _setLoading(false);
    }
  }

  void _saveProfileStep() {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      _setError('Введите имя.');
      return;
    }

    setState(() {
      _step = _AuthStep.passwordCreate;
      _errorMessage = null;
    });
  }

  void _savePasswordStep() {
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;
    if (password.length < 6) {
      _setError('Пароль должен содержать минимум 6 символов.');
      return;
    }
    if (password != confirm) {
      _setError('Пароли не совпадают.');
      return;
    }

    setState(() {
      _storedPasswordHash = _hashValue(password);
      _rawPassword = password;
      _step = _AuthStep.pinCreate;
      _pinDraft = '';
      _pinConfirmDraft = '';
      _isPinConfirmationStep = false;
      _errorMessage = null;
    });
  }

  Future<void> _finishRegistration() async {
    if (!RegExp(r'^\d{4}$').hasMatch(_pinDraft)) {
      _setError('PIN должен состоять из 4 цифр.');
      return;
    }
    if (_pinDraft != _pinConfirmDraft) {
      _setError('PIN-коды не совпадают.');
      return;
    }
    if (_storedPasswordHash == null || _rawPassword.isEmpty) {
      _setError('Сессия регистрации устарела. Начните регистрацию заново.');
      return;
    }
    if (_normalizedPhone.isEmpty) {
      _setError('Не удалось определить номер телефона.');
      return;
    }
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _setError('Введите имя.');
      return;
    }

    _setLoading(true);
    _setError('');
    try {
      await _registrationService.completeRegistration(
        AuthRegistrationPayload(
          phoneNumber: _normalizedPhone,
          name: name,
          password: _rawPassword,
          passwordHash: _storedPasswordHash!,
          pin: _pinDraft,
          pinHash: _hashValue(_pinDraft),
        ),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (_) {
      _setError('Не удалось завершить регистрацию. Повторите попытку.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loginWithPin() async {
    final pin = _loginPinController.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      _setError('Введите 4-значный PIN.');
      return;
    }

    final hash = _hashValue(pin);
    if (_storedPinHash == null || hash != _storedPinHash) {
      _setError('Неверный PIN.');
      return;
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Future<void> _logoutToPhoneAuth() async {
    _setLoading(true);
    _setError('');
    try {
      await _tokenStorage.clearPhoneRegistrationData();
      if (!mounted) return;
      setState(() {
        _step = _AuthStep.phoneInput;
        _storedPhone = null;
        _storedPasswordHash = null;
        _storedPinHash = null;
        _isSmsSendDisabled = false;
        _isConsentAccepted = false;
        _phoneController.text = '+7';
        _nameController.clear();
        _smsCodeController.clear();
        _loginPinController.clear();
        _loginPasswordController.clear();
      });
    } catch (_) {
      _setError('Не удалось выйти из аккаунта.');
    } finally {
      _setLoading(false);
    }
  }

  void _onPinPadPressed(String value) {
    setState(() {
      if (!_isPinConfirmationStep) {
        if (_pinDraft.length < 4) {
          _pinDraft += value;
        }
        if (_pinDraft.length == 4) {
          _isPinConfirmationStep = true;
        }
      } else {
        if (_pinConfirmDraft.length < 4) {
          _pinConfirmDraft += value;
        }
      }
      _errorMessage = null;
    });
  }

  void _onPinPadBackspace() {
    setState(() {
      if (_isPinConfirmationStep) {
        if (_pinConfirmDraft.isNotEmpty) {
          _pinConfirmDraft = _pinConfirmDraft.substring(
            0,
            _pinConfirmDraft.length - 1,
          );
        } else {
          _isPinConfirmationStep = false;
        }
      } else if (_pinDraft.isNotEmpty) {
        _pinDraft = _pinDraft.substring(0, _pinDraft.length - 1);
      }
      _errorMessage = null;
    });
  }

  Widget _buildPinDots(String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < value.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Colors.black87 : Colors.transparent,
            border: Border.all(color: Colors.black45),
          ),
        );
      }),
    );
  }

  Widget _buildPinPadButton({
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return SizedBox(
      width: 76,
      height: 76,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.black26),
        ),
        child: icon == null
            ? Text(label, style: const TextStyle(fontSize: 24))
            : Icon(icon),
      ),
    );
  }

  Widget _buildPinPad() {
    final canWritePin = !_isLoading &&
        ((!_isPinConfirmationStep && _pinDraft.length < 4) ||
            (_isPinConfirmationStep && _pinConfirmDraft.length < 4));
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ]) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row
                .map(
                  (digit) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildPinPadButton(
                      label: digit,
                      onPressed: canWritePin ? () => _onPinPadPressed(digit) : null,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildPinPadButton(
                label: '',
                onPressed: null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildPinPadButton(
                label: '0',
                onPressed: canWritePin ? () => _onPinPadPressed('0') : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: _buildPinPadButton(
                label: '',
                icon: Icons.backspace_outlined,
                onPressed: _isLoading ? null : _onPinPadBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _loginWithPassword() async {
    final password = _loginPasswordController.text;
    if (password.length < 6) {
      _setError('Введите пароль не короче 6 символов.');
      return;
    }
    final hash = _hashValue(password);
    if (_storedPasswordHash == null || hash != _storedPasswordHash) {
      _setError('Неверный пароль.');
      return;
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Регистрация по номеру телефона',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneMaskFormatter],
          decoration: const InputDecoration(
            labelText: 'Номер телефона',
            hintText: '+7 (___) ___-__-__',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _isConsentAccepted,
              onChanged: (value) {
                setState(() {
                  _isConsentAccepted = value ?? false;
                });
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Я принимаю ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/terms_of_use'),
                      child: const Text(
                        'Условия использования',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ' и ',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/privacy_policy'),
                      child: const Text(
                        'Политику конфиденциальности',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      '.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading || _isSmsSendDisabled || !_isConsentAccepted
              ? null
              : _sendSmsCode,
          child: const Text('Отправить код в WhatsApp'),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Код отправлен в WhatsApp на $_normalizedPhone',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _smsCodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Код из WhatsApp',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifySmsCode,
          child: const Text('Подтвердить код'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendSmsCode,
          child: const Text('Отправить код повторно'),
        ),
      ],
    );
  }

  Widget _buildProfileStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Расскажите о себе',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nameController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfileStep,
          child: const Text('Продолжить'),
        ),
      ],
    );
  }

  Widget _buildPasswordCreateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Придумайте пароль для повторного входа',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.next,
          enableSuggestions: false,
          autocorrect: false,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordConfirmController,
          keyboardType: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          enableSuggestions: false,
          autocorrect: false,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Подтверждение пароля',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePasswordStep,
          child: const Text('Продолжить'),
        ),
      ],
    );
  }

  Widget _buildPinCreateStep() {
    final activePin = _isPinConfirmationStep ? _pinConfirmDraft : _pinDraft;
    final title = _isPinConfirmationStep
        ? 'Повторите PIN-код'
        : 'Придумайте PIN-код';
    final subtitle = _isPinConfirmationStep
        ? 'Введите те же 4 цифры ещё раз'
        : 'Введите 4 цифры для быстрого доступа';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 20),
        _buildPinDots(activePin),
        const SizedBox(height: 20),
        _buildPinPad(),
        const SizedBox(height: 12),
        if (_isPinConfirmationStep)
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _pinDraft = '';
                      _pinConfirmDraft = '';
                      _isPinConfirmationStep = false;
                      _errorMessage = null;
                    });
                  },
            child: const Text('Сбросить PIN и ввести заново'),
          ),
        ElevatedButton(
          onPressed:
              _isLoading || _pinDraft.length != 4 || _pinConfirmDraft.length != 4
              ? null
              : _finishRegistration,
          child: const Text('Завершить регистрацию'),
        ),
      ],
    );
  }

  Widget _buildPinLoginStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Быстрый вход по PIN',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        if (_storedPhone != null) ...[
          const SizedBox(height: 8),
          Text('Телефон: $_storedPhone'),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _loginPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: 'PIN',
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _loginWithPin,
          child: const Text('Войти'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _step = _AuthStep.passwordLogin;
                    _errorMessage = null;
                  });
                },
          child: const Text('Войти по паролю'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _logoutToPhoneAuth,
          child: const Text('Выйти и войти по номеру'),
        ),
      ],
    );
  }

  Widget _buildPasswordLoginStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Вход по паролю',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        if (_storedPhone != null) ...[
          const SizedBox(height: 8),
          Text('Телефон: $_storedPhone'),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _loginPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Пароль',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _loginWithPassword,
          child: const Text('Войти'),
        ),
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  setState(() {
                    _step = _AuthStep.pinLogin;
                    _errorMessage = null;
                  });
                },
          child: const Text('Вернуться ко входу по PIN'),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _AuthStep.phoneInput:
        return _buildPhoneStep();
      case _AuthStep.codeVerify:
        return _buildCodeStep();
      case _AuthStep.profileInput:
        return _buildProfileStep();
      case _AuthStep.passwordCreate:
        return _buildPasswordCreateStep();
      case _AuthStep.pinCreate:
        return _buildPinCreateStep();
      case _AuthStep.pinLogin:
        return _buildPinLoginStep();
      case _AuthStep.passwordLogin:
        return _buildPasswordLoginStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход и регистрация')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepContent(),
                  if (_isLoading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if ((_errorMessage ?? '').isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
