import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mispos/check_update.dart';
import 'package:mispos/controllers/setting_controller.dart';

/// แถบหัวใช้สีแดงเดียวกับหน้าแรก (Colors.redAccent) ตามสีบริษัท
const _appBarColor = Colors.redAccent;

/// ปุ่มและสวิตช์ใช้น้ำเงินตามธีมของแอป เคอร์เซอร์กับหมุดเลือกข้อความจะได้สีเดียวกัน
const _accent = Color(0xFF1976D2);
const _background = Color(0xFFF3F4F6);
const _border = Color(0xFFE5E7EB);
const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF4B5563);
const _textCaption = Color(0xFF6B7280);
const _iconBackground = Color(0xFFEEF2F7);
const _iconColor = Color(0xFF374151);
const _successBackground = Color(0xFFE8F5E9);
const _successText = Color(0xFF1B5E20);
const _errorBackground = Color(0xFFFDECEA);
const _errorText = Color(0xFFB71C1C);

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  final SettingController settingCtrl = Get.put(SettingController());

  @override
  void initState() {
    super.initState();
    settingCtrl.loadSetting();
    settingCtrl.refreshServerStatus();
    settingCtrl.refreshCardCheckServer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        title: Text(
          'ตั้งค่าเครื่อง',
          style: GoogleFonts.kanit(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        actions: [
          Obx(() => Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    settingCtrl.appVersion.value.isEmpty
                        ? ''
                        : 'MIS POS v${settingCtrl.appVersion.value}',
                    style: GoogleFonts.kanit(
                        fontSize: 15, fontWeight: FontWeight.w300),
                  ),
                ),
              )),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _section(
                      'การเชื่อมต่อ',
                      [_serverRow(), _posRow()],
                      caption: 'แตะเพื่อแก้ไข ระบบจะทดสอบการเชื่อมต่อก่อนบันทึกทุกครั้ง',
                    ),
                    const SizedBox(height: 20),
                    _section('การขาย', [_saleOfflineRow(), _cardCheckRow()]),
                    const SizedBox(height: 20),
                    _section(
                      'เสียง',
                      [_soundRow()],
                      caption: 'สวิตช์ทุกตัวมีผลทันที ไม่ต้องกดบันทึก',
                    ),
                    const SizedBox(height: 20),
                    _section('แอปพลิเคชัน', [_versionRow()]),
                  ],
                )),
          ),
        ),
      ),
    );
  }

  Widget _serverRow() {
    final ip = settingCtrl.ipServer.value;
    return _row(
      icon: Icons.dns_outlined,
      title: 'IP Server',
      subtitle: ip.isEmpty ? 'ยังไม่ได้ตั้งค่า แตะเพื่อตั้งค่า' : ip,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _serverStatusChip(),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      ]),
      onTap: _openEditServer,
    );
  }

  Widget _posRow() {
    final id = settingCtrl.posID.value;
    return _row(
      icon: Icons.tablet_android_outlined,
      title: 'รหัสเครื่อง',
      subtitle: id.isEmpty
          ? 'ยังไม่ได้ตั้งค่า'
          : '$id · รหัสในบิล ${settingCtrl.posCodeFor(id)}',
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
      onTap: _openEditServer,
    );
  }

  Widget _saleOfflineRow() {
    final value = settingCtrl.saleOffline.value;
    return _row(
      icon: Icons.cloud_off_outlined,
      title: 'ขาย Offline',
      subtitle: 'บันทึกบิลไว้ในเครื่องเมื่อติดต่อ server ไม่ได้',
      trailing: _switch(value, settingCtrl.setSaleOffline),
      onTap: () => settingCtrl.setSaleOffline(!value),
    );
  }

  Widget _cardCheckRow() {
    final value = settingCtrl.cardCheckEnabled.value;
    return _row(
      icon: Icons.credit_card_outlined,
      title: 'ปุ่มเช็คบัตรในหน้าขาย',
      subtitle: 'ดูยอดเงินคงเหลือในบัตร ไม่ตัดเงิน ไม่สร้างบิล',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _cardCheckServerChip(),
        const SizedBox(width: 8),
        _switch(value, settingCtrl.setCardCheckEnabled),
      ]),
      onTap: () => settingCtrl.setCardCheckEnabled(!value),
    );
  }

  /// เปิดสวิตช์ไว้แต่ server ยังไม่แก้ carddetail แคชเชียร์กดแล้วจะเจอ error
  /// ป้ายนี้ให้คนตั้งเครื่องเห็นก่อน
  Widget _cardCheckServerChip() {
    if (!settingCtrl.cardCheckEnabled.value) return const SizedBox.shrink();
    if (settingCtrl.isCheckingCardServer.value) {
      return _chip(
          'กำลังตรวจสอบ server', _iconBackground, _textSecondary, null);
    }
    final ready = settingCtrl.cardCheckServerReady.value;
    if (ready == null) return const SizedBox.shrink();
    return ready
        ? _chip('server พร้อม', _successBackground, _successText,
            Icons.check_rounded)
        : _chip('server ยังไม่รองรับ', _errorBackground, _errorText,
            Icons.close_rounded);
  }

  Widget _soundRow() {
    final value = settingCtrl.soundEnabled.value;
    return _row(
      icon: value ? Icons.volume_up_outlined : Icons.volume_off_outlined,
      title: 'เสียงแจ้งผลชำระเงินด้วยบัตร',
      subtitle: 'สำเร็จ · ไม่สำเร็จ · แตะบัตรซ้ำ',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        _pillButton(
          icon: Icons.play_arrow_rounded,
          label: 'ทดสอบเสียง',
          onPressed: value ? settingCtrl.testSound : null,
        ),
        const SizedBox(width: 8),
        _switch(value, settingCtrl.setSoundEnabled),
      ]),
      onTap: () => settingCtrl.setSoundEnabled(!value),
    );
  }

  Widget _versionRow() {
    final version = settingCtrl.appVersion.value;
    return _row(
      icon: Icons.info_outline,
      title: 'เวอร์ชัน',
      subtitle: version.isEmpty
          ? '-'
          : '$version · build ${settingCtrl.appBuildNumber.value}',
      trailing: _pillButton(
        icon: Icons.system_update_alt_rounded,
        label: 'เช็คอัปเดต',
        onPressed: () => CheckUpdate.check(isManual: true),
      ),
    );
  }

  void _openEditServer() {
    showDialog(
      context: context,
      builder: (_) => _EditServerDialog(settingCtrl: settingCtrl),
    );
  }

  Widget _serverStatusChip() {
    if (settingCtrl.isRefreshingStatus.value) {
      return _chip('กำลังตรวจสอบ', _iconBackground, _textSecondary, null);
    }
    final reachable = settingCtrl.serverReachable.value;
    if (reachable == null) return const SizedBox.shrink();
    return reachable
        ? _chip('เชื่อมต่อได้', _successBackground, _successText,
            Icons.check_rounded)
        : _chip('เชื่อมต่อไม่ได้', _errorBackground, _errorText,
            Icons.close_rounded);
  }

  Widget _section(String title, List<Widget> rows, {String? caption}) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(const Divider(
            height: 1, thickness: 1, indent: 76, color: _border));
      }
      children.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(title,
              style: GoogleFonts.kanit(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _textSecondary)),
        ),
        Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _border),
          ),
          child: Column(children: children),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8),
            child: Text(caption,
                style: GoogleFonts.kanit(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: _textCaption)),
          ),
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: _iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: GoogleFonts.kanit(
                            fontSize: 18, color: _textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: GoogleFonts.kanit(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: _textSecondary)),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing],
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(bool value, ValueChanged<bool> onChanged) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: _accent,
    );
  }

  Widget _chip(String label, Color background, Color foreground, IconData? icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 6),
        ],
        Text(label, style: GoogleFonts.kanit(fontSize: 14, color: foreground)),
      ]),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _accent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
        side: BorderSide(
            color: onPressed == null ? _border : _accent, width: 1.5),
        textStyle: GoogleFonts.kanit(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }
}

/// แก้ IP Server และรหัสเครื่อง
/// ปุ่มบันทึกจะทดสอบการเชื่อมต่อก่อนเสมอ ผ่านแล้วจึงบันทึกและเริ่มแอปใหม่
class _EditServerDialog extends StatefulWidget {
  const _EditServerDialog({required this.settingCtrl});

  final SettingController settingCtrl;

  @override
  State<_EditServerDialog> createState() => _EditServerDialogState();
}

class _EditServerDialogState extends State<_EditServerDialog> {
  late final TextEditingController _ipCtrl =
      TextEditingController(text: widget.settingCtrl.ipServer.value);
  late final TextEditingController _posCtrl =
      TextEditingController(text: widget.settingCtrl.posID.value);

  bool _isChecking = false;
  bool? _isConnected;
  String _message = '';

  @override
  void dispose() {
    _ipCtrl.dispose();
    _posCtrl.dispose();
    super.dispose();
  }

  Future<bool> _testConnection() async {
    setState(() {
      _isChecking = true;
      _isConnected = null;
    });
    final ok =
        await widget.settingCtrl.checkServerConnection(_ipCtrl.text.trim());
    if (!mounted) return false;
    setState(() {
      _isChecking = false;
      _isConnected = ok;
      _message = widget.settingCtrl.connectionMessage.value;
    });
    return ok;
  }

  Future<void> _save() async {
    if (_posCtrl.text.trim().isEmpty) {
      setState(() {
        _isConnected = false;
        _message = 'กรุณากรอกรหัสเครื่อง';
      });
      return;
    }
    if (!await _testConnection()) return;
    await widget.settingCtrl
        .saveServerSetting(_ipCtrl.text.trim(), _posCtrl.text.trim());
    Get.offAllNamed("/");
  }

  @override
  Widget build(BuildContext context) {
    final posId = _posCtrl.text.trim();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('แก้ไขการเชื่อมต่อ Server',
                  style: GoogleFonts.kanit(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: _textPrimary)),
              const SizedBox(height: 20),
              _field(
                label: 'IP Server',
                controller: _ipCtrl,
                hint: 'เช่น 192.168.1.10:8080',
                autofocus: true,
              ),
              const SizedBox(height: 16),
              _field(
                label: 'รหัสเครื่อง',
                controller: _posCtrl,
                keyboardType: TextInputType.number,
                helper: posId.isEmpty
                    ? null
                    : 'รหัสในบิล ${widget.settingCtrl.posCodeFor(posId)}',
              ),
              const SizedBox(height: 20),
              _statusBox(),
              Text('บันทึกแล้วแอปจะเริ่มใหม่เพื่อใช้ค่าใหม่',
                  style: GoogleFonts.kanit(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: _textCaption)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _iconColor,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      textStyle: GoogleFonts.kanit(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('ยกเลิก'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _isChecking ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      side: const BorderSide(color: _accent, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.kanit(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('ทดสอบการเชื่อมต่อ'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isChecking ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: GoogleFonts.kanit(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('บันทึก'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBox() {
    if (_isChecking) {
      return _statusContainer(
        background: _iconBackground,
        foreground: _textSecondary,
        leading: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
        ),
        text: 'กำลังทดสอบการเชื่อมต่อ...',
      );
    }
    if (_isConnected == null) return const SizedBox.shrink();
    return _isConnected!
        ? _statusContainer(
            background: _successBackground,
            foreground: _successText,
            leading: const Icon(Icons.check_rounded, color: _successText),
            text: _message,
          )
        : _statusContainer(
            background: _errorBackground,
            foreground: _errorText,
            leading: const Icon(Icons.error_outline, color: _errorText),
            text: _message,
          );
  }

  Widget _statusContainer({
    required Color background,
    required Color foreground,
    required Widget leading,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: GoogleFonts.kanit(fontSize: 16, color: foreground)),
        ),
      ]),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helper,
    TextInputType? keyboardType,
    bool autofocus = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.kanit(fontSize: 16, color: _iconColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: autofocus,
          onChanged: (_) => setState(() => _isConnected = null),
          style: GoogleFonts.kanit(fontSize: 18, color: _textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle: GoogleFonts.kanit(fontSize: 14, color: _textCaption),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
                borderSide: const BorderSide(color: _accent, width: 2)),
          ),
        ),
      ],
    );
  }
}
