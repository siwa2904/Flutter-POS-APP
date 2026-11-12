# posapp

A new Flutter project.

## ปล่อยอัปเดตแอป

เครื่อง POS อัปเดตตัวเองผ่าน server ของร้าน ไม่ผ่าน Play Store
แอปอ่านไฟล์ `http://<IP Server>/api/update.json` โดย IP Server คือค่าในหน้าตั้งค่าเครื่อง
ถ้าเลข `build` ในไฟล์สูงกว่าแอปที่ลงอยู่ จะขึ้นกล่อง "มีเวอร์ชันใหม่"
พอกดอัปเดต แอปจะดาวน์โหลด APK ตรวจ sha256 แล้วเปิดหน้าติดตั้งของ Android

แอปเช็คเองตอนเปิดหน้าแรก ถ้าไม่สำเร็จจะลองใหม่ใน 5 นาที ถ้าสำเร็จจะเช็คซ้ำทุก 1 ชั่วโมง
หรือกดเช็คเองได้ที่ ตั้งค่าเครื่อง → เช็คอัปเดต ซึ่งจะบอกสาเหตุถ้าเช็คไม่ได้

### ก่อนเริ่ม

- **Flutter 3.3.10 ผ่าน FVM** ใช้ `fvm flutter ...` เสมอ ห้ามใช้ `flutter` ตัว global
  เพราะเวอร์ชันใหม่กว่าจะเขียน `pubspec.lock` ใหม่และ build ไม่ผ่าน ต้องใช้ JDK 17
- **คีย์ที่ใช้ sign APK** release build ใช้ debug key ของเครื่องที่ build คือ `~/.android/debug.keystore`
  (ดู `signingConfig` ใน `android/app/build.gradle`)
  ต้อง build จากเครื่องเดิม หรือ copy ไฟล์นี้ไปเครื่องที่ build ถ้าคีย์ไม่ตรง เครื่อง POS จะติดตั้งทับไม่ได้
  ต้องถอนแอปเก่าออกก่อน และข้อมูลในเครื่องจะหายทั้งหมด เช่น IP Server และบิล offline
  **ให้ backup ไฟล์นี้ไว้เสมอ**

### ขั้นตอน

1. **แก้เวอร์ชัน** ใน `pubspec.yaml` เช่น `version: 1.1.7+6910001`
   - ตัวเลขหลัง `+` คือเลข build ต้องมากกว่าตัวที่ปล่อยไปแล้วทุกครั้ง แอปใช้เลขนี้ตัดสินว่ามีอัปเดต
   - เปลี่ยนชื่อเวอร์ชัน (ส่วนหน้า `+`) ทุกครั้งด้วย เพราะแอป 1.1.6 ลงไปเทียบแค่ชื่อเวอร์ชัน
     ถ้าชื่อเท่าเดิม เครื่องพวกนั้นจะไม่เห็นอัปเดต

2. **Build**
   ```bash
   fvm flutter build apk --release
   ```
   ได้ไฟล์ `build/app/outputs/flutter-apk/app-release.apk`

3. **สร้าง update.json** ด้วยสคริปต์ ห้ามพิมพ์เอง สคริปต์อ่านเวอร์ชันจาก `pubspec.yaml` และคำนวณ sha256 จาก APK ให้
   ```bash
   scripts/make_update_json.sh "<apk_url>" "<ข้อความแจ้งผู้ใช้>" [min_build]

   # ตัวอย่าง
   scripts/make_update_json.sh "http://192.168.50.250:8080/api/file/mispos-1.1.7.apk" "เพิ่มปุ่มเพิ่มลดจำนวนสินค้า"
   ```
   - `apk_url` คือที่ที่ APK จะอยู่บน server หลังอัปโหลด เครื่อง POS ต้องเข้าถึงลิงก์นี้ได้
   - ข้อความคือสิ่งที่แคชเชียร์เห็นในกล่องแจ้งอัปเดต
   - `min_build` ใส่เมื่อต้องการบังคับอัปเดต ดูหัวข้อ "บังคับอัปเดต" ด้านล่าง

   ได้ไฟล์ `update.json` และ `mispos-<version>.apk` (สำเนาของ `app-release.apk`) ใน `build/app/outputs/flutter-apk/`
   ถ้าสคริปต์ขึ้นว่า "pubspec.yaml ใหม่กว่า APK" แปลว่าแก้เวอร์ชันแล้วยังไม่ได้ build ใหม่ ให้ทำข้อ 2 ก่อน

4. **อัปโหลดขึ้น server** ทั้ง 2 ไฟล์

   | ไฟล์ในเครื่อง | วางบน server ให้เปิดได้ที่ |
   |---|---|
   | `build/app/outputs/flutter-apk/mispos-<version>.apk` | ตรงกับ `apk_url` |
   | `build/app/outputs/flutter-apk/update.json` | `http://<IP Server>/api/update.json` |

   APK ต้องเป็นตัวเดียวกับที่ใช้สร้าง update.json ถ้า build ใหม่หลังรันสคริปต์ sha256 จะไม่ตรง และแอปจะไม่ยอมติดตั้ง
   ให้รันสคริปต์ใหม่แล้วอัปโหลดทั้งสองไฟล์อีกครั้ง

5. **ตรวจหลังอัปโหลด**
   ```bash
   curl -s http://192.168.50.250:8080/api/update.json
   curl -sI <apk_url> | grep -i content-type   # ต้องเป็น application/vnd.android.package-archive
   curl -s <apk_url> | shasum -a 256           # ต้องตรงกับ sha256 ใน update.json
   ```

6. **ลองกับเครื่อง POS 1 เครื่องก่อน** ที่ ตั้งค่าเครื่อง → เช็คอัปเดต → อัปเดตตอนนี้
   - ครั้งแรก Android จะให้อนุญาต "ติดตั้งแอปที่ไม่รู้จัก" ให้ MIS POS ก่อน ให้เปิดสวิตช์แล้วกลับมากดลองใหม่
   - ติดตั้งเสร็จแล้ว ดูเลข build ในหน้าตั้งค่าว่าเปลี่ยนแล้ว

### ตั้งค่า server ครั้งแรก

ใส่ไฟล์ `.htaccess` ในโฟลเดอร์ที่เก็บ APK โดยมีบรรทัดนี้

```apache
AddType application/vnd.android.package-archive .apk
```

ถ้าไม่ใส่ Apache จะส่งไฟล์โดยไม่บอกชนิดไฟล์ เวลาโหลดผ่านเบราว์เซอร์จะได้ไฟล์ zip ที่ติดตั้งไม่ได้
ส่วนการอัปเดตในแอปยังใช้ได้ แต่ควรใส่ไว้สำหรับกรณีที่ต้องติดตั้งเองผ่านลิงก์

### ช่องใน update.json

| ช่อง | ความหมาย |
|---|---|
| `version` | ชื่อเวอร์ชัน เช่น `"1.1.7"` ห้ามใส่ `+build` ต่อท้าย |
| `build` | เลข build แอปจะแจ้งอัปเดตเมื่อเลขนี้สูงกว่าเครื่อง |
| `apk_url` | ลิงก์ดาวน์โหลด APK |
| `sha256` | ใช้ตรวจว่าไฟล์ที่โหลดมาถูกตัว ถ้าไม่ตรงจะไม่ติดตั้ง |
| `message` | ข้อความในกล่องแจ้งอัปเดต |
| `min_build` | ไม่บังคับใส่ เครื่องที่ build ต่ำกว่านี้ต้องอัปเดตก่อนใช้งานต่อ |
| `force` | ไม่บังคับใส่ `true` = บังคับอัปเดต ใช้กับแอป 1.1.6 ลงไปที่ไม่รู้จัก `min_build` |

### บังคับอัปเดต

ใส่ `min_build` ตอนรันสคริปต์ เช่น `scripts/make_update_json.sh "<apk_url>" "<ข้อความ>" 6910001`
เครื่องที่ build ต่ำกว่า 6910001 จะเห็นกล่องอัปเดตที่ไม่มีปุ่ม "ภายหลัง" ปิดไม่ได้
และถ้าดาวน์โหลดไม่สำเร็จจะวนกลับมาที่กล่องนี้จนกว่าจะอัปเดต

แอป 1.1.6 ลงไปไม่รู้จัก `min_build` ถ้าต้องบังคับเครื่องพวกนั้นด้วย ให้เพิ่ม `"force": true` ใน update.json เอง
แอปตั้งแต่ 1.1.7 จะไม่สน `force` เมื่อมี `min_build` อยู่ เครื่องที่อัปเดตแล้วจึงไม่โดนบังคับซ้ำ

### แก้ปัญหา

| อาการ | สาเหตุและวิธีแก้ |
|---|---|
| เครื่องไม่ขึ้นว่ามีอัปเดต | `build` ใน update.json ไม่สูงกว่าเครื่อง หรือ update.json ไม่ได้อยู่ที่ `/api/update.json` ของ IP Server ของเครื่องนั้น กดเช็คอัปเดตในหน้าตั้งค่าเพื่อดูสาเหตุ |
| "ไม่พบไฟล์ update.json บน Server" | ยังไม่ได้อัปโหลด หรือวางผิดที่ |
| "ไฟล์ update.json บน Server รูปแบบไม่ถูกต้อง" | JSON เสีย ให้สร้างใหม่ด้วยสคริปต์ |
| "Server ตอบกลับผิดปกติ (status: 404) ตรวจสอบ apk_url" | `apk_url` ไม่ตรงกับที่อัปโหลด APK ไว้ |
| "ดาวน์โหลดไม่สำเร็จ ตรวจสอบเครือข่ายแล้วลองใหม่" | เครื่อง POS เข้าถึงที่อยู่ใน `apk_url` ไม่ได้ เช่นใส่ IP ผิด |
| "ไฟล์ที่ได้ไม่ใช่ APK" | `apk_url` ชี้ไปที่หน้าเว็บหรือหน้า error แทนไฟล์ APK |
| "ไฟล์ไม่ตรงกับ sha256 ใน update.json" | อัปโหลด APK คนละตัวกับที่ใช้สร้าง update.json ให้รันสคริปต์ใหม่แล้วอัปโหลดทั้งคู่ |
| Android ขึ้นว่าแอปไม่ได้ติดตั้ง | คีย์ไม่ตรงเพราะ build จากเครื่องอื่น หรือเลข build ต่ำกว่าตัวที่ลงอยู่ |
| โหลด APK ผ่านเบราว์เซอร์แล้วได้ไฟล์ zip | ยังไม่ได้ใส่ `.htaccess` |

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

