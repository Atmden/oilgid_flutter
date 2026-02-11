import 'package:flutter_riverpod/legacy.dart';
import '../../domain/entities/oil_item.dart';

final selectedOilProvider = StateProvider<OilItem?>((ref) => null);