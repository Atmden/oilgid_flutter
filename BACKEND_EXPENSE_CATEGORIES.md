# Backend: Expense Categories + ServiceRecord refactor

## Контекст

Flutter-приложение OilGid получило фичу учёта расходов по автомобилям. Категории расходов хранятся на сервере, принадлежат пользователю. Пользователь может создавать свои категории (название, иконка из фиксированного набора, цвет) и редактировать/удалять любые (в том числе дефолтные).

**Существующая модель `service_records`** была переработана: поле `service_type` (строка) заменено на `category_id` (FK на новую таблицу `expense_categories`).

---

## 1. Новая таблица `expense_categories`

### Migration

```php
Schema::create('expense_categories', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('name');
    $table->string('icon_key', 64)->default('more_horiz');
    $table->string('color_hex', 9)->default('#546E7A');
    $table->boolean('is_default')->default(false);
    $table->timestamps();

    $table->index('user_id');
});
```

### Model `ExpenseCategory`

```php
class ExpenseCategory extends Model
{
    protected $fillable = ['user_id', 'name', 'icon_key', 'color_hex', 'is_default'];

    protected $casts = ['is_default' => 'boolean'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function serviceRecords(): HasMany
    {
        return $this->hasMany(ServiceRecord::class, 'category_id');
    }
}
```

---

## 2. Изменения в таблице `service_records`

### Migration

```php
Schema::table('service_records', function (Blueprint $table) {
    // Удалить service_type (был string, nullable или required)
    $table->dropColumn('service_type');

    // Добавить category_id — nullable, чтобы не сломать старые записи
    $table->foreignId('category_id')
        ->nullable()
        ->after('user_car_id')
        ->constrained('expense_categories')
        ->nullOnDelete();
});
```

> **Важно:** `nullOnDelete()` — чтобы при удалении категории записи не исчезали, а просто теряли категорию.

### Model `ServiceRecord` — добавить relation

```php
public function category(): BelongsTo
{
    return $this->belongsTo(ExpenseCategory::class, 'category_id');
}
```

Убрать `service_type` из `$fillable`, добавить `category_id`.

---

## 3. Дефолтные категории

При первом обращении пользователя к `GET /garage/expense-categories`, если у него ещё нет ни одной категории — создать дефолтный набор.

### Дефолтный набор

| name | icon_key | color_hex |
|------|----------|-----------|
| Топливо | `local_gas_station` | `#1976D2` |
| ТО | `build` | `#388E3C` |
| Ремонт | `car_repair` | `#E64A19` |
| Страховка | `security` | `#7B1FA2` |
| Штраф | `gavel` | `#C62828` |
| Мойка | `cleaning_services` | `#0097A7` |
| Парковка | `local_parking` | `#455A64` |
| Запчасти | `settings` | `#5D4037` |
| Налог | `receipt_long` | `#827717` |
| Прочее | `more_horiz` | `#546E7A` |

Все с `is_default = true`.

### Логика в контроллере (или отдельный метод)

```php
private function seedDefaultCategories(User $user): void
{
    $defaults = [
        ['name' => 'Топливо',    'icon_key' => 'local_gas_station', 'color_hex' => '#1976D2'],
        ['name' => 'ТО',         'icon_key' => 'build',             'color_hex' => '#388E3C'],
        ['name' => 'Ремонт',     'icon_key' => 'car_repair',        'color_hex' => '#E64A19'],
        ['name' => 'Страховка',  'icon_key' => 'security',          'color_hex' => '#7B1FA2'],
        ['name' => 'Штраф',      'icon_key' => 'gavel',             'color_hex' => '#C62828'],
        ['name' => 'Мойка',      'icon_key' => 'cleaning_services', 'color_hex' => '#0097A7'],
        ['name' => 'Парковка',   'icon_key' => 'local_parking',     'color_hex' => '#455A64'],
        ['name' => 'Запчасти',   'icon_key' => 'settings',          'color_hex' => '#5D4037'],
        ['name' => 'Налог',      'icon_key' => 'receipt_long',      'color_hex' => '#827717'],
        ['name' => 'Прочее',     'icon_key' => 'more_horiz',        'color_hex' => '#546E7A'],
    ];

    foreach ($defaults as $item) {
        $user->expenseCategories()->create([...$item, 'is_default' => true]);
    }
}
```

---

## 4. Эндпоинты

Все маршруты — под middleware `auth:sanctum` (или что используется в проекте). Пользователь видит только свои категории.

### Маршруты (routes/api.php)

```php
Route::middleware('auth:sanctum')->prefix('garage')->group(function () {
    // ... существующие маршруты гаража ...

    Route::get('/expense-categories', [ExpenseCategoryController::class, 'index']);
    Route::post('/expense-categories', [ExpenseCategoryController::class, 'store']);
    Route::patch('/expense-categories/{category}', [ExpenseCategoryController::class, 'update']);
    Route::delete('/expense-categories/{category}', [ExpenseCategoryController::class, 'destroy']);
});
```

---

## 5. `ExpenseCategoryController`

### index — `GET /garage/expense-categories`

Сидирует дефолтные, если пусто. Возвращает все категории пользователя.

**Ответ:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Топливо",
      "icon_key": "local_gas_station",
      "color_hex": "#1976D2",
      "is_default": true
    }
  ]
}
```

### store — `POST /garage/expense-categories`

**Request body:**
```json
{
  "name": "Аренда гаража",
  "icon_key": "garage",
  "color_hex": "#455A64"
}
```

**Валидация:**
```php
$request->validate([
    'name'      => 'required|string|max:64',
    'icon_key'  => 'required|string|max:64',
    'color_hex' => ['required', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
]);
```

**Ответ:**
```json
{
  "success": true,
  "data": {
    "id": 11,
    "name": "Аренда гаража",
    "icon_key": "garage",
    "color_hex": "#455A64",
    "is_default": false
  }
}
```

### update — `PATCH /garage/expense-categories/{category}`

Те же поля, все опциональные (`sometimes`). Проверить что `category->user_id === auth()->id()`, иначе 403.

**Ответ:** аналогично `store`.

### destroy — `DELETE /garage/expense-categories/{category}`

Проверить что `category->user_id === auth()->id()`, иначе 403.

**Ответ:**
```json
{
  "success": true
}
```

---

## 6. Изменения в `ServiceRecordController`

### store / update

Убрать `service_type` из валидации и `$fillable`. Добавить `category_id`:

```php
$request->validate([
    'user_car_id'  => 'required|integer|exists:user_cars,id',
    'service_date' => 'required|date',
    'category_id'  => 'nullable|integer|exists:expense_categories,id',
    'mileage'      => 'nullable|integer|min:0',
    'total_cost'   => 'nullable|numeric|min:0',
    'currency'     => 'nullable|string|in:RUB,USD,KZT,EUR',
    'notes'        => 'nullable|string|max:2000',
    'items'        => 'nullable|array',
    'items.*.name'       => 'required|string|max:255',
    'items.*.quantity'   => 'required|integer|min:1',
    'items.*.unit_price' => 'required|numeric|min:0',
]);
```

> Если хочешь ограничить `category_id` только категориями текущего пользователя:
> ```php
> 'category_id' => [
>     'nullable', 'integer',
>     Rule::exists('expense_categories', 'id')->where('user_id', auth()->id()),
> ],
> ```

### index / show — включить `category` в ответ

```php
$records = ServiceRecord::with(['items', 'attachments', 'category'])
    ->where('user_car_id', $userCarId)
    ->orderBy('service_date', 'desc')
    ->get();
```

**Структура объекта `service_record` в ответе:**

```json
{
  "id": 42,
  "user_car_id": 7,
  "service_date": "2026-05-20",
  "category_id": 1,
  "category": {
    "id": 1,
    "name": "Топливо",
    "icon_key": "local_gas_station",
    "color_hex": "#1976D2",
    "is_default": true
  },
  "mileage": 85000,
  "total_cost": "4500.00",
  "currency": "KZT",
  "notes": null,
  "items": [],
  "attachments": []
}
```

> Поле `service_type` — **убрать из ответа полностью**.

---

## 7. Авторизация / политики

Минимально — проверять `user_id` вручную в контроллере. Если в проекте используются `Policy` — добавить `ExpenseCategoryPolicy` с методами `view`, `update`, `delete` (все проверяют `$user->id === $category->user_id`).

---

## 8. Ресурсы (опционально)

Если в проекте используются `JsonResource`:

```php
// ExpenseCategoryResource
public function toArray($request): array
{
    return [
        'id'         => $this->id,
        'name'       => $this->name,
        'icon_key'   => $this->icon_key,
        'color_hex'  => $this->color_hex,
        'is_default' => (bool) $this->is_default,
    ];
}
```

---

## 9. Чеклист

- [ ] Migration: создать `expense_categories`
- [ ] Migration: изменить `service_records` (drop `service_type`, add `category_id`)
- [ ] Model `ExpenseCategory` + relation в `User` (`hasMany`)
- [ ] Model `ServiceRecord`: relation `category`, убрать `service_type` из fillable
- [ ] `ExpenseCategoryController` (index, store, update, destroy)
- [ ] Seeding дефолтных категорий при первом index
- [ ] Маршруты в `routes/api.php`
- [ ] `ServiceRecordController`: убрать `service_type`, добавить `category_id`, eager load `category`
- [ ] Убедиться что все существующие тесты проходят (или обновить)
