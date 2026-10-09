#!/usr/bin/env bash
# สร้าง update.json สำหรับระบบอัปเดตในแอป จาก pubspec.yaml และ APK release ที่ build แล้ว
# ไม่ต้องพิมพ์ version / build / sha256 เอง กันพิมพ์ผิดแบบใส่ "1.1.6+6909001" ในช่อง version
#
# ใช้:  scripts/make_update_json.sh <apk_url> "<ข้อความแจ้งผู้ใช้>" [min_build]
#   min_build  เครื่องที่ build ต่ำกว่านี้ต้องอัปเดตก่อนใช้งานต่อ ไม่ใส่ = ไม่บังคับ
#              แอป 1.1.6 ลงไปไม่รู้จัก min_build ถ้าต้องบังคับเครื่องพวกนั้นด้วย ให้เพิ่ม "force": true เอง
#
# ผลลัพธ์: build/app/outputs/flutter-apk/update.json
set -euo pipefail

cd "$(dirname "$0")/.."

if [ $# -lt 2 ]; then
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
fi

APK_URL=$1
MESSAGE=$2
MIN_BUILD=${3:-}
APK=build/app/outputs/flutter-apk/app-release.apk
OUT=build/app/outputs/flutter-apk/update.json

if [ ! -f "$APK" ]; then
  echo "ไม่พบ $APK ให้ build release ก่อน" >&2
  exit 1
fi

# APK ต้อง build หลังแก้ pubspec ครั้งล่าสุด ไม่งั้นเลขใน update.json จะไม่ตรงกับไฟล์จริง
if [ pubspec.yaml -nt "$APK" ]; then
  echo "pubspec.yaml ใหม่กว่า $APK แปลว่ายังไม่ได้ build release หลังแก้เวอร์ชัน" >&2
  exit 1
fi

FULL=$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '[:space:]')
VERSION=${FULL%%+*}
BUILD=${FULL##*+}
case $BUILD in
  '' | *[!0-9]*) echo "อ่านเลข build จาก pubspec.yaml ไม่ได้: $FULL" >&2; exit 1 ;;
esac
case $MIN_BUILD in
  *[!0-9]*) echo "min_build ต้องเป็นตัวเลข: $MIN_BUILD" >&2; exit 1 ;;
esac

SHA=$(shasum -a 256 "$APK" | awk '{print $1}')

python3 - "$VERSION" "$BUILD" "$MIN_BUILD" "$APK_URL" "$SHA" "$MESSAGE" > "$OUT" <<'EOF'
import json
import sys

version, build, min_build, apk_url, sha, message = sys.argv[1:]
data = {"version": version, "build": int(build)}
if min_build:
    data["min_build"] = int(min_build)
data.update({"apk_url": apk_url, "sha256": sha, "message": message})
print(json.dumps(data, ensure_ascii=False, indent=4))
EOF

echo "สร้าง $OUT แล้ว:"
cat "$OUT"
echo
echo "อัปโหลด update.json ไปที่ http://<IP Server>/api/update.json และ APK ไปที่ $APK_URL ให้เป็นไฟล์เดียวกับที่ใช้สร้าง"
