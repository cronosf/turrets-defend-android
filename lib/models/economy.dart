import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_strings.dart';

/// Central run state: currency, base health, wave counter and persisted
/// settings/high-score. Exposed as a [ChangeNotifier] so both the Flutter
/// HUD widgets and the Flame game can listen/react without tight coupling.
class Economy extends ChangeNotifier {
  static const double maxBaseHp = 100;
  static const double startMoney = 60;
  static const double adCooldownSeconds = 25;

  double money = startMoney;
  double baseHp = maxBaseHp;
  int wave = 1;
  int score = 0;
  int turretsPurchased = 0;
  int bestWave = 0;
  int bestScore = 0;
  int lastWave = 0;
  int lastScore = 0;
  int waveEnemiesTotal = 0;
  int waveEnemiesResolved = 0;

  double adCooldown = 0;
  bool sellMode = false;
  bool musicOn = true;
  bool soundOn = true;
  bool vibrationOn = true;
  bool tipsOn = true;
  double musicVolume = 7;
  double soundVolume = 7;
  AppLanguage language = AppLanguage.es;
  bool notificationsOn = true;

  bool gameOver = false;

  SharedPreferences? _prefs;

  Future<void> loadPersisted() async {
    _prefs = await SharedPreferences.getInstance();
    bestWave = _prefs?.getInt('best_wave') ?? 0;
    bestScore = _prefs?.getInt('best_score') ?? 0;
    lastWave = _prefs?.getInt('last_wave') ?? 0;
    lastScore = _prefs?.getInt('last_score') ?? 0;
    musicOn = _prefs?.getBool('music_on') ?? true;
    soundOn = _prefs?.getBool('sound_on') ?? true;
    vibrationOn = _prefs?.getBool('vibration_on') ?? true;
    tipsOn = _prefs?.getBool('tips_on') ?? true;
    notificationsOn = _prefs?.getBool('notifications_on') ?? true;
    musicVolume = _prefs?.getDouble('music_volume') ?? 7;
    soundVolume = _prefs?.getDouble('sound_volume') ?? 7;
    language = (_prefs?.getString('language') ?? 'es') == 'en'
        ? AppLanguage.en
        : AppLanguage.es;
    notifyListeners();
  }

  void resetRun() {
    money = startMoney;
    baseHp = maxBaseHp;
    wave = 1;
    score = 0;
    turretsPurchased = 0;
    adCooldown = 0;
    sellMode = false;
    gameOver = false;
    waveEnemiesTotal = 0;
    waveEnemiesResolved = 0;
    notifyListeners();
  }

  bool spend(num amount) {
    if (money < amount) return false;
    money -= amount;
    notifyListeners();
    return true;
  }

  void addMoney(num amount) {
    money += amount;
    notifyListeners();
  }

  void addScore(int points) {
    score += points;
    notifyListeners();
  }

  void damageBase(double amount) {
    if (gameOver) return;
    baseHp -= amount;
    if (baseHp <= 0) {
      baseHp = 0;
      gameOver = true;
      _finalizeRun();
    }
    notifyListeners();
  }

  /// Called once a run ends: the wave/score reached always become "last
  /// played", but "best" only ever moves up, never down.
  void _finalizeRun() {
    lastWave = wave;
    lastScore = score;
    _prefs?.setInt('last_wave', lastWave);
    _prefs?.setInt('last_score', lastScore);
    if (wave > bestWave) {
      bestWave = wave;
      _prefs?.setInt('best_wave', bestWave);
    }
    if (score > bestScore) {
      bestScore = score;
      _prefs?.setInt('best_score', bestScore);
    }
  }

  void nextWave() {
    wave += 1;
    notifyListeners();
  }

  void setWaveProgress(int resolved, int total) {
    waveEnemiesResolved = resolved;
    waveEnemiesTotal = total;
    notifyListeners();
  }

  void tickAdCooldown(double dt) {
    if (adCooldown > 0) {
      adCooldown = (adCooldown - dt).clamp(0, adCooldownSeconds);
      notifyListeners();
    }
  }

  bool claimFreeTurret() {
    if (adCooldown > 0) return false;
    adCooldown = adCooldownSeconds;
    notifyListeners();
    return true;
  }

  void toggleSellMode() {
    sellMode = !sellMode;
    notifyListeners();
  }

  void setMusicOn(bool v) {
    musicOn = v;
    _prefs?.setBool('music_on', v);
    notifyListeners();
  }

  void setSoundOn(bool v) {
    soundOn = v;
    _prefs?.setBool('sound_on', v);
    notifyListeners();
  }

  void setVibrationOn(bool v) {
    vibrationOn = v;
    _prefs?.setBool('vibration_on', v);
    notifyListeners();
  }

  void setTipsOn(bool v) {
    tipsOn = v;
    _prefs?.setBool('tips_on', v);
    notifyListeners();
  }

  void setNotificationsOn(bool v) {
    notificationsOn = v;
    _prefs?.setBool('notifications_on', v);
    notifyListeners();
  }

  void setMusicVolume(double v) {
    musicVolume = v;
    _prefs?.setDouble('music_volume', v);
    notifyListeners();
  }

  void setSoundVolume(double v) {
    soundVolume = v;
    _prefs?.setDouble('sound_volume', v);
    notifyListeners();
  }

  void setLanguage(AppLanguage v) {
    language = v;
    _prefs?.setString('language', v == AppLanguage.en ? 'en' : 'es');
    notifyListeners();
  }
}
