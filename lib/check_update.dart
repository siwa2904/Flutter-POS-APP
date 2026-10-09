import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mispos/services/update_service.dart';

// ชุดสีเดียวกับหน้าตั้งค่าเครื่อง
const _accent = Color(0xFF1976D2);
const _accentSoft = Color(0xFFE3F0FB);
const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF4B5563);
const _surfaceMuted = Color(0xFFF3F4F6);
const _successBackground = Color(0xFFE8F5E9);
const _successText = Color(0xFF1B5E20);
const _warningBackground = Color(0xFFFFF4E5);
const _warningText = Color(0xFF8A4B00);
const _errorBackground = Color(0xFFFDECEA);
const _errorText = Color(0xFFB71C1C);

class CheckUpdate {
  /// เช็คอัตโนมัติจะแสดง dialog มีอัปเดตแค่ครั้งเดียวต่อการเปิดแอป
  static bool _shownThisSession = false;
  static DateTime? _nextAutoCheckAt;
  static bool _isRunning = false;

  /// [isManual] = กดจากหน้าตั้งค่า แสดงผลทุกกรณี รวมถึงเป็นเวอร์ชันล่าสุดแล้วหรือเช็คไม่ได้
  /// เช็คอัตโนมัติถูกเรียกจาก build() ของหน้าแรกทุกครั้งที่ rebuild จึงเว้นระยะไว้
  /// เช็คไม่สำเร็จลองใหม่ได้ใน 5 นาที สำเร็จแล้วเช็คซ้ำทุก 1 ชั่วโมง เพราะเครื่อง POS เปิดค้างทั้งวัน
  static Future<void> check({bool isManual = false}) async {
    if (_isRunning) return;
    if (!isManual) {
      if (_shownThisSession) return;
      final next = _nextAutoCheckAt;
      if (next != null && DateTime.now().isBefore(next)) return;
    }

    _isRunning = true;
    if (isManual) {
      Get.dialog(const _CheckingDialog(), barrierDismissible: false);
    }
    UpdateCheckResult result;
    try {
      result = await UpdateService.check();
    } catch (e) {
      // ห้ามหลุดออกไป ไม่งั้นหน้า "กำลังเช็คอัปเดต" ที่ปิดเองไม่ได้จะค้าง
      // และ _isRunning ค้างเป็น true จนกดเช็คอัปเดตอีกไม่ได้
      print("CheckUpdate: $e");
      result = UpdateCheckResult(UpdateCheckStatus.failed,
          error: 'เกิดข้อผิดพลาด: $e');
    }
    if (isManual) Get.back();
    _isRunning = false;

    if (!isManual) {
      _nextAutoCheckAt = DateTime.now().add(
          result.status == UpdateCheckStatus.failed
              ? const Duration(minutes: 5)
              : const Duration(hours: 1));
    }

    switch (result.status) {
      case UpdateCheckStatus.available:
        if (!isManual) _shownThisSession = true;
        _offerUpdate(result);
        break;
      case UpdateCheckStatus.upToDate:
        if (isManual) {
          Get.dialog(_MessageDialog(
            icon: Icons.check_circle_outline,
            iconColor: _successText,
            iconBackground: _successBackground,
            title: 'เป็นเวอร์ชันล่าสุดแล้ว',
            body: 'เครื่องนี้ใช้ ${result.currentLabel}',
          ));
        }
        break;
      case UpdateCheckStatus.failed:
        print("CheckUpdate: ${result.error}");
        if (isManual) {
          Get.dialog(_MessageDialog(
            icon: Icons.error_outline,
            iconColor: _errorText,
            iconBackground: _errorBackground,
            title: 'เช็คอัปเดตไม่สำเร็จ',
            body: result.error,
          ));
        }
        break;
    }
  }

  /// แบบบังคับ ปิดหน้าดาวน์โหลดด้วยทางไหนก็ตามต้องกลับมาหน้ามีเวอร์ชันใหม่
  /// ทั้งโหลดไม่สำเร็จแล้วกดปิด กดยกเลิกระหว่างโหลด หรือกดยกเลิกในหน้าติดตั้งของ Android
  /// ไม่งั้นแคชเชียร์ขายต่อได้ทั้งที่ยังไม่อัปเดต และจะไม่ถูกถามอีกจนกว่าจะเปิดแอปใหม่
  static Future<void> _offerUpdate(UpdateCheckResult result) async {
    final info = result.info!;
    final required = info.isRequiredFor(result.currentBuild);
    while (true) {
      final wantsUpdate = await Get.dialog<bool>(
        _UpdateAvailableDialog(result: result, required: required),
        barrierDismissible: !required,
      );
      if (wantsUpdate != true) return;
      await Get.dialog(_DownloadDialog(info: info), barrierDismissible: false);
      if (!required) return;
    }
  }
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({required this.child, this.width = 560});

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: child,
        ),
      ),
    );
  }
}

Widget _iconBadge(IconData icon, Color color, Color background) {
  return Container(
    width: 56,
    height: 56,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(icon, color: color, size: 30),
  );
}

Widget _title(String text) => Text(text,
    style: GoogleFonts.kanit(
        fontSize: 22, fontWeight: FontWeight.w500, color: _textPrimary));

Widget _body(String text, {Color color = _textSecondary}) => Text(text,
    style: GoogleFonts.kanit(
        fontSize: 16, fontWeight: FontWeight.w300, color: color));

ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: _accent,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.kanit(fontSize: 17, fontWeight: FontWeight.w500),
    );

ButtonStyle _textButtonStyle() => TextButton.styleFrom(
      foregroundColor: _textSecondary,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: GoogleFonts.kanit(fontSize: 17, fontWeight: FontWeight.w500),
    );

class _CheckingDialog extends StatelessWidget {
  const _CheckingDialog();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: _DialogShell(
        width: 420,
        child: Row(children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: _accent),
          ),
          const SizedBox(width: 20),
          Expanded(child: _body('กำลังเช็คอัปเดต...', color: _textPrimary)),
        ]),
      ),
    );
  }
}

class _MessageDialog extends StatelessWidget {
  const _MessageDialog({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _iconBadge(icon, iconColor, iconBackground),
          const SizedBox(height: 16),
          _title(title),
          const SizedBox(height: 8),
          _body(body),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: _primaryButtonStyle(),
              child: const Text('ตกลง'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdateAvailableDialog extends StatelessWidget {
  const _UpdateAvailableDialog({required this.result, required this.required});

  final UpdateCheckResult result;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final info = result.info!;
    return WillPopScope(
      onWillPop: () async => !required,
      child: _DialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: _iconBadge(
                  Icons.system_update_alt_rounded, _accent, _accentSoft),
            ),
            const SizedBox(height: 16),
            _title('มีเวอร์ชันใหม่'),
            const SizedBox(height: 12),
            _versionLine('เวอร์ชันใหม่', info.label, bold: true),
            const SizedBox(height: 4),
            _versionLine('เครื่องนี้', result.currentLabel),
            if (info.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _body(info.message, color: _textPrimary),
              ),
            ],
            if (required) ...[
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _warningBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: _warningText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('เวอร์ชันนี้จำเป็น ต้องอัปเดตก่อนใช้งานต่อ',
                        style: GoogleFonts.kanit(
                            fontSize: 16, color: _warningText)),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!required) ...[
                  TextButton(
                    onPressed: () => Get.back(),
                    style: _textButtonStyle(),
                    child: const Text('ภายหลัง'),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton.icon(
                  // CheckUpdate._offerUpdate เป็นคนเปิดหน้าดาวน์โหลดต่อ
                  onPressed: () => Get.back(result: true),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('อัปเดตตอนนี้'),
                  style: _primaryButtonStyle(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionLine(String label, String value, {bool bold = false}) {
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label,
            style: GoogleFonts.kanit(
                fontSize: 16, fontWeight: FontWeight.w300, color: _textSecondary)),
      ),
      Text(value,
          style: GoogleFonts.kanit(
              fontSize: 16,
              fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
              color: _textPrimary)),
    ]);
  }
}

enum _DownloadStage { permission, downloading, installing, failed }

/// ขอสิทธิ์ → ดาวน์โหลด → ตรวจไฟล์ → เปิดตัวติดตั้ง ล้มเหลวตรงไหนกดลองใหม่ได้
class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.info});

  final UpdateInfo info;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  _DownloadStage _stage = _DownloadStage.permission;
  int _received = 0;
  int _total = -1;
  String _error = '';
  CancelToken? _cancelToken;
  bool _userCancelled = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _stage = _DownloadStage.permission;
      _received = 0;
      _total = -1;
      _error = '';
      _userCancelled = false;
    });

    if (!await UpdateService.ensureInstallPermission()) {
      // ขึ้นบรรทัดเอง เพราะ Flutter 3.3 ตัดคำไทยกลางคำ ("กดล|องใหม่")
      _fail('ต้องอนุญาต "ติดตั้งแอปที่ไม่รู้จัก" ให้ MIS POS ก่อน\nแล้วกดลองใหม่');
      return;
    }
    if (!mounted) return;

    final token = CancelToken();
    _cancelToken = token;
    setState(() => _stage = _DownloadStage.downloading);

    try {
      final file = await UpdateService.download(
        widget.info,
        cancelToken: token,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _stage = _DownloadStage.installing);
      await UpdateService.install(file);
      if (mounted) Get.back();
    } on UpdateException catch (e) {
      if (_userCancelled) {
        if (mounted) Get.back();
        return;
      }
      _fail(e.message);
    } catch (e) {
      _fail('เกิดข้อผิดพลาด: $e');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _stage = _DownloadStage.failed;
      _error = message;
    });
  }

  void _cancel() {
    _userCancelled = true;
    _cancelToken?.cancel();
  }

  bool get _isVerifying =>
      _stage == _DownloadStage.downloading && _total > 0 && _received >= _total;

  String get _titleText {
    switch (_stage) {
      case _DownloadStage.permission:
        return 'ขอสิทธิ์ติดตั้งแอป';
      case _DownloadStage.downloading:
        return _isVerifying ? 'กำลังตรวจสอบไฟล์' : 'กำลังดาวน์โหลดอัปเดต';
      case _DownloadStage.installing:
        return 'กำลังเปิดตัวติดตั้ง';
      case _DownloadStage.failed:
        return 'อัปเดตไม่สำเร็จ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => _stage == _DownloadStage.failed,
      child: _DialogShell(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _title(_titleText),
            const SizedBox(height: 4),
            _body('เวอร์ชัน ${widget.info.label}'),
            const SizedBox(height: 20),
            ..._content(),
          ],
        ),
      ),
    );
  }

  List<Widget> _content() {
    switch (_stage) {
      case _DownloadStage.permission:
        return [
          _progressBar(null),
          const SizedBox(height: 12),
          _body('ถ้าระบบเปิดหน้าตั้งค่าขึ้นมา ให้เปิดสวิตช์ "อนุญาตจากแหล่งที่มานี้" แล้วกดย้อนกลับ'),
        ];
      case _DownloadStage.downloading:
        final fraction = _total > 0 ? _received / _total : null;
        return [
          _progressBar(fraction),
          const SizedBox(height: 12),
          _body(_isVerifying
              ? 'ดาวน์โหลดครบแล้ว กำลังตรวจว่าไฟล์ถูกต้อง'
              : _progressText(fraction)),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _isVerifying ? null : _cancel,
              style: _textButtonStyle(),
              child: const Text('ยกเลิก'),
            ),
          ),
        ];
      case _DownloadStage.installing:
        return [
          _progressBar(1),
          const SizedBox(height: 12),
          _body('กด "ติดตั้ง" ในหน้าที่ Android เปิดขึ้นมา แอปจะเริ่มใหม่เป็นเวอร์ชันใหม่'),
        ];
      case _DownloadStage.failed:
        return [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _errorBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.error_outline, color: _errorText),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_error,
                    style: GoogleFonts.kanit(fontSize: 16, color: _errorText)),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                style: _textButtonStyle(),
                child: const Text('ปิด'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _start,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ลองใหม่'),
                style: _primaryButtonStyle(),
              ),
            ],
          ),
        ];
    }
  }

  Widget _progressBar(double? value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        color: _accent,
        backgroundColor: _accentSoft,
      ),
    );
  }

  String _progressText(double? fraction) {
    String mb(int bytes) => (bytes / (1024 * 1024)).toStringAsFixed(1);
    if (fraction == null) return 'ได้มาแล้ว ${mb(_received)} MB';
    return '${mb(_received)} / ${mb(_total)} MB · ${(fraction * 100).toStringAsFixed(0)}%';
  }
}
