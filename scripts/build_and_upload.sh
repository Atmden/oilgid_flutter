#!/bin/bash
# Сборка iOS и загрузка в TestFlight
# Использование: ./scripts/build_and_upload.sh

set -euo pipefail

# ── Цвета ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${BLUE}▶${NC} $1"; }
ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗ ОШИБКА:${NC} $1"; exit 1; }

# ── Конфигурация ──────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

WORKSPACE="$PROJECT_DIR/ios/Runner.xcworkspace"
SCHEME="Runner"
EXPORT_OPTIONS="$SCRIPT_DIR/ExportOptions.plist"

API_KEY_ID="R4RG9M96A4"
API_ISSUER_ID="1d66b42f-f23c-4ee8-a510-e0d6b6475a0d"
API_KEY_FILE="$SCRIPT_DIR/AuthKey_R4RG9M96A4.p8"

BUILD_DIR="/tmp/oilgid_build"
ARCHIVE_PATH="$BUILD_DIR/Runner.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"

# ── Проверки ──────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}━━━ OILGID iOS Build & Upload ━━━${NC}\n"

[[ -d "$WORKSPACE" ]]      || fail "Workspace не найден: $WORKSPACE"
[[ -f "$EXPORT_OPTIONS" ]] || fail "ExportOptions.plist не найден: $EXPORT_OPTIONS"
[[ -f "$API_KEY_FILE" ]]   || fail "API ключ не найден: $API_KEY_FILE"

command -v flutter >/dev/null  || fail "flutter не найден в PATH"
command -v xcodebuild >/dev/null || fail "xcodebuild не найден"
command -v xcrun >/dev/null    || fail "xcrun не найден"

# ── Читаем версию из pubspec.yaml ─────────────────────────────────────────────
PUBSPEC="$PROJECT_DIR/pubspec.yaml"
VERSION_LINE=$(grep "^version:" "$PUBSPEC" | head -1)
# Формат: 1.1.7+26
FULL_VERSION=$(echo "$VERSION_LINE" | sed 's/version: *//')
MARKETING_VERSION=$(echo "$FULL_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$FULL_VERSION" | cut -d'+' -f2)

log "Версия: ${BOLD}$MARKETING_VERSION${NC} (build $BUILD_NUMBER)"

# ── Проверяем дубликат билда в App Store Connect ──────────────────────────────
log "Проверяю дубликат в App Store Connect..."
DUPLICATE=$(python3 - <<PYEOF
import jwt, time, json, urllib.request, urllib.error, sys

key_id    = "$API_KEY_ID"
issuer_id = "$API_ISSUER_ID"
key_file  = "$API_KEY_FILE"
app_id    = "6758605190"
build_num = "$BUILD_NUMBER"
version   = "$MARKETING_VERSION"

with open(key_file) as f:
    private_key = f.read()

now = int(time.time())
token = jwt.encode(
    {"iss": issuer_id, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
    private_key, algorithm="ES256", headers={"kid": key_id}
)
headers = {"Authorization": f"Bearer {token}"}

url = (
    f"https://api.appstoreconnect.apple.com/v1/builds"
    f"?filter[app]={app_id}"
    f"&filter[version]={build_num}"
    f"&filter[preReleaseVersion.version]={version}"
    f"&fields[builds]=version,uploadedDate,processingState"
    f"&limit=5"
)
try:
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read())
    builds = data.get("data", [])
    if builds:
        b = builds[0]["attributes"]
        print(f"FOUND|{b.get('processingState','?')}|{b.get('uploadedDate','?')}")
    else:
        print("OK")
except Exception as e:
    print(f"ERROR|{e}")
PYEOF
)

if [[ "$DUPLICATE" == OK ]]; then
    ok "Дубликатов нет, продолжаю"
elif [[ "$DUPLICATE" == ERROR* ]]; then
    warn "Не удалось проверить дубликаты (${DUPLICATE#ERROR|}), продолжаю"
else
    STATE=$(echo "$DUPLICATE" | cut -d'|' -f2)
    DATE=$(echo "$DUPLICATE"  | cut -d'|' -f3)
    echo -e "${RED}✗ Билд v$MARKETING_VERSION ($BUILD_NUMBER) уже существует в App Store Connect!${NC}"
    echo -e "  Статус: ${BOLD}$STATE${NC}  |  Загружен: $DATE"
    echo -e "\nЧтобы загрузить новый билд, увеличь build number в ${BOLD}pubspec.yaml${NC}."
    exit 1
fi

# ── Очищаем build dir ─────────────────────────────────────────────────────────
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# ── 1. Flutter build ios ──────────────────────────────────────────────────────
echo -e "\n${BOLD}[1/3] Flutter build ios --release${NC}"
cd "$PROJECT_DIR"
flutter build ios --release --no-codesign \
    --build-name="$MARKETING_VERSION" \
    --build-number="$BUILD_NUMBER" \
  && ok "Flutter build завершён" || fail "flutter build ios провалился"

# ── 2. xcodebuild archive ─────────────────────────────────────────────────────
echo -e "\n${BOLD}[2/3] Архивирование (xcodebuild archive)${NC}"
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=63H8F54AU7 \
    | xcpretty 2>/dev/null || true

# xcpretty может отсутствовать — проверяем наличие архива
[[ -d "$ARCHIVE_PATH" ]] && ok "Архив создан: $ARCHIVE_PATH" \
    || fail "Архив не создан. Проверь вывод xcodebuild выше."

# ── 3. Экспорт и загрузка в TestFlight ───────────────────────────────────────
# destination: upload в ExportOptions.plist — xcodebuild сам загружает в App Store Connect
echo -e "\n${BOLD}[3/3] Экспорт и загрузка в TestFlight${NC}"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -authenticationKeyPath "$API_KEY_FILE" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" \
    -allowProvisioningUpdates \
  && ok "Загрузка завершена! Сборка появится в TestFlight через несколько минут." \
  || fail "Экспорт/загрузка провалились"

echo -e "\n${GREEN}${BOLD}━━━ Готово: v$MARKETING_VERSION ($BUILD_NUMBER) → TestFlight ━━━${NC}\n"
