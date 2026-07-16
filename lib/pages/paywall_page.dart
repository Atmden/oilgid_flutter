import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:oil_gid/core/api/app_api.dart';
import 'package:oil_gid/core/storage/token_storage.dart';
import 'package:oil_gid/features/subscription/domain/entities/subscription_plan.dart';
import 'package:oil_gid/features/subscription/domain/entities/subscription_status.dart';
import 'package:oil_gid/themes/app_colors.dart';

class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  final _api = AppApi().subscriptionApi;

  // Планы текущей платформы (app_store или play_market)
  List<SubscriptionPlan> _plans = [];
  Map<String, ProductDetails> _storeProducts = {};
  SubscriptionPlan? _selected;

  bool _loading = true;
  bool _purchasing = false;
  bool _alreadyActive = false;
  bool _requiresLogin = false;
  String? _error;

  late StreamSubscription<List<PurchaseDetails>> _purchaseSub;
  Timer? _purchaseTimeoutTimer;

  String get _currentPlatform => Platform.isIOS ? 'app_store' : 'play_market';

  @override
  void initState() {
    super.initState();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => _showError('Ошибка магазина: $e'),
    );
    _load();
  }

  @override
  void dispose() {
    _purchaseSub.cancel();
    _purchaseTimeoutTimer?.cancel();
    super.dispose();
  }

  void _startPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted || !_purchasing) return;
      setState(() => _purchasing = false);
      _showError('Магазин не ответил. Попробуйте позже.');
    });
  }

  void _stopPurchaseTimeout() {
    _purchaseTimeoutTimer?.cancel();
    _purchaseTimeoutTimer = null;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _requiresLogin = false;
    });
    try {
      // Без токена планы не грузим — просим войти
      final userToken = await TokenStorage().getUserToken();
      if (userToken == null || userToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          _requiresLogin = true;
          _loading = false;
        });
        return;
      }

      // Проверяем активную подписку до загрузки планов
      SubscriptionStatus? status;
      try {
        status = await _api.getStatus();
      } catch (_) {}
      if (status != null && status.isActive) {
        if (!mounted) return;
        setState(() {
          _alreadyActive = true;
          _loading = false;
        });
        return;
      }

      final allPlans = await _api.getPlans();
      // Показываем только планы текущей платформы
      final List<SubscriptionPlan> plans = allPlans
          .where((p) => p.platform == _currentPlatform)
          .toList();

      Map<String, ProductDetails> storeProducts = {};
      if (plans.isNotEmpty) {
        final available = await InAppPurchase.instance.isAvailable();
        if (available) {
          final ids = plans.map((p) => p.productId).toSet();
          final response =
              await InAppPurchase.instance.queryProductDetails(ids);
          for (final p in response.productDetails) {
            storeProducts[p.id] = p;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _storeProducts = storeProducts;
        _selected = plans.isEmpty
            ? null
            : plans.firstWhere(
                (p) => p.billingPeriod == 'monthly',
                orElse: () => plans.first,
              );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _purchasing = true);
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _stopPurchaseTimeout();
        try {
          await _validateWithBackend(purchase);
          await InAppPurchase.instance.completePurchase(purchase);
          if (!mounted) return;
          setState(() => _purchasing = false);
          _onSuccess(purchase.status == PurchaseStatus.restored);
        } catch (e) {
          if (!mounted) return;
          setState(() => _purchasing = false);
          _showError(e.toString().replaceFirst('Exception: ', ''));
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        _stopPurchaseTimeout();
        if (!mounted) return;
        // Пользователь сам отменил покупку — ошибку не показываем
        setState(() => _purchasing = false);
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _stopPurchaseTimeout();
        if (!mounted) return;
        setState(() => _purchasing = false);
        final msg = purchase.error?.message ?? '';
        // Пользователь сам отменил — не показываем ошибку
        if (msg != 'userCancelled' &&
            purchase.error?.code != 'playstore_cancel') {
          _showError(msg.isNotEmpty ? msg : 'Ошибка при покупке.');
        }
        continue;
      }

    }
  }

  Future<void> _validateWithBackend(PurchaseDetails purchase) async {
    // Находим план по productId чтобы взять правильный platformKey
    final plan = _plans.firstWhere(
      (p) => p.productId == purchase.productID,
      orElse: () => _plans.first,
    );
    await _api.validatePurchase(
      platform: plan.platformKey,
      productId: purchase.productID,
      transactionId: Platform.isIOS
          ? purchase.verificationData.serverVerificationData
          : null,
      purchaseToken: Platform.isAndroid
          ? purchase.verificationData.serverVerificationData
          : null,
    );
  }

  Future<void> _buy() async {
    final plan = _selected;
    if (plan == null) return;

    // Покупку нельзя привязать к аккаунту без авторизации
    final userToken = await TokenStorage().getUserToken();
    if (userToken == null || userToken.isEmpty) {
      if (!mounted) return;
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Требуется вход'),
          content: const Text(
            'Для оформления подписки необходимо войти в аккаунт.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Войти'),
            ),
          ],
        ),
      );
      if (goLogin == true && mounted) {
        Navigator.pushNamed(context, '/login');
      }
      return;
    }

    final storeProduct = _storeProducts[plan.productId];
    if (storeProduct == null) {
      _showError('Продукт не найден в магазине. Попробуйте позже.');
      return;
    }

    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _showError('Магазин недоступен. Проверьте интернет-соединение.');
      return;
    }

    setState(() => _purchasing = true);
    _startPurchaseTimeout();
    try {
      await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: storeProduct),
      );
    } catch (e) {
      _stopPurchaseTimeout();
      if (!mounted) return;
      setState(() => _purchasing = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _restore() async {
    final available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      _showError('Магазин недоступен. Проверьте интернет-соединение.');
      return;
    }
    setState(() => _purchasing = true);
    _startPurchaseTimeout();
    try {
      await InAppPurchase.instance.restorePurchases();
      // Результат придёт через purchaseStream
    } catch (e) {
      _stopPurchaseTimeout();
      if (!mounted) return;
      setState(() => _purchasing = false);
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _onSuccess(bool isRestore) {
    if (!mounted) return;
    final msg = isRestore
        ? 'Подписка успешно восстановлена!'
        : 'Подписка успешно оформлена!';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
    Navigator.of(context).pop(true);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Подписка'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requiresLogin
              ? _buildRequiresLogin()
              : _alreadyActive
                  ? _buildAlreadyActive()
                  : _error != null
                      ? _ErrorView(message: _error!, onRetry: _load)
                      : _plans.isEmpty
                          ? const Center(
                              child: Text(
                                'Тарифы временно недоступны.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: _plans[i],
                      storeProduct: _storeProducts[_plans[i].productId],
                      isSelected: _selected?.id == _plans[i].id,
                      onTap: () => setState(() => _selected = _plans[i]),
                    ),
                  ),
                  childCount: _plans.length,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
        if (_purchasing)
          const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildRequiresLogin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Colors.black26),
            const SizedBox(height: 24),
            const Text(
              'Требуется вход',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Для оформления подписки необходимо войти в аккаунт.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login')
                    .then((_) => _load()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlreadyActive() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 72, color: AppColors.accentDark),
            const SizedBox(height: 24),
            const Text(
              'Подписка активна',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'У вас уже есть активная подписка. Все функции приложения доступны.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Отлично'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.workspace_premium,
                size: 44,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Откройте полный доступ',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Ведите историю обслуживания автомобилей, храните документы и сервисные записи.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          _FeatureRow('Гараж с историей обслуживания'),
          _FeatureRow('Записи о ТО и ремонтах'),
          _FeatureRow('Фото и документы к каждой записи'),
          _FeatureRow('Приоритетная поддержка (годовой план)'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected != null && !_purchasing ? _buy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Оформить подписку',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _purchasing ? null : _restore,
            child: const Text(
              'Восстановить покупку',
              style: TextStyle(color: Colors.black45, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Подписка продлевается автоматически. Отменить можно в настройках магазина.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black38),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://oilgid.kz/terms-of-use'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'Условия использования',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Text(
                '  ·  ',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://oilgid.kz/privacy-policy'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text(
                  'Политика конфиденциальности',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final ProductDetails? storeProduct;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.storeProduct,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Цена берётся из магазина; если продукт ещё не загружен — показываем прочерк
    final priceStr = storeProduct?.price ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.black26,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                plan.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  priceStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  plan.periodLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
