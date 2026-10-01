import 'package:audioplayers/audioplayers.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mispos/utils/constants.dart';

/// เสียงแจ้งผลการตัดเงินด้วยบัตร ให้แคชเชียร์รับรู้ผลโดยไม่ต้องจ้องจอ
///
/// เล่นแบบ fire-and-forget เสมอ ผู้เรียกไม่ต้อง await และไม่ต้องดักข้อผิดพลาด
/// เสียงที่เล่นไม่ออกถือเป็นเรื่องรอง ห้ามทำให้ flow การขายสะดุด
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  /// สวิตช์เปิดปิดเสียงจุดเดียวของทั้งแอป ผูกกับหน้าตั้งค่าเครื่อง
  ///
  /// อ่านจาก GetStorage ทุกครั้งที่จะเล่น สลับในหน้าตั้งค่าแล้วมีผลกับบิลถัดไปทันที
  /// เครื่องที่ยังไม่เคยตั้งค่าถือว่าเปิดเสียงไว้
  static bool get enabled =>
      GetStorage().read<bool>(Constant.soundEnabled) ?? true;

  static set enabled(bool value) =>
      GetStorage().write(Constant.soundEnabled, value);

  /// ชื่อไฟล์เก็บไว้จุดเดียว ถ้าได้ไฟล์เสียงใหม่มาให้แก้ที่นี่
  static const String _successFile = 'sounds/pay_success.wav';
  static const String _failedFile = 'sounds/pay_failed.wav';
  static const String _duplicateFile = 'sounds/pay_duplicate.wav';

  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _failedPlayer = AudioPlayer();
  final AudioPlayer _duplicatePlayer = AudioPlayer();

  bool _isPreloaded = false;

  /// โหลดไฟล์เสียงเข้า player ไว้ล่วงหน้า เรียกตอน OrdersController.onInit()
  ///
  /// ถ้าไม่ preload จะมีดีเลย์ตอน decode ทุกบิล ทำให้เสียงมาช้ากว่าที่จอขึ้นผล
  Future<void> preload() async {
    if (_isPreloaded) return;
    try {
      await _successPlayer.setSource(AssetSource(_successFile));
      await _failedPlayer.setSource(AssetSource(_failedFile));
      await _duplicatePlayer.setSource(AssetSource(_duplicateFile));

      await _successPlayer.setReleaseMode(ReleaseMode.stop);
      await _failedPlayer.setReleaseMode(ReleaseMode.stop);
      await _duplicatePlayer.setReleaseMode(ReleaseMode.stop);

      _isPreloaded = true;
      print("SoundService: preload done");
    } catch (e) {
      print("SoundService: preload failed => $e");
    }
  }

  /// ตัดเงินจากบัตรสำเร็จ
  void playSuccess() => _play(_successPlayer, "success");

  /// ตัดเงินไม่สำเร็จ เช่น ไม่พบบัตร ยอดเงินไม่พอ หรือ server ตอบกลับผิดรูปแบบ
  void playFailed() => _play(_failedPlayer, "failed");

  /// แตะบัตรซ้ำหลังจ่ายสำเร็จแล้ว ไม่ได้ตัดเงินรอบสอง
  void playDuplicate() => _play(_duplicatePlayer, "duplicate");

  void _play(AudioPlayer player, String tag) {
    if (!enabled) return;
    player.stop().then((_) => player.resume()).catchError((e) {
      print("SoundService: play $tag failed => $e");
    });
  }

  void dispose() {
    _successPlayer.dispose();
    _failedPlayer.dispose();
    _duplicatePlayer.dispose();
    _isPreloaded = false;
  }
}
