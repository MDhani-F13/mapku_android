import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  File? _logFile;

  factory DebugLogger() => _instance;

  DebugLogger._internal();

  Future<void> _initLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFileName =
          'debug_logs_${DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now())}.txt';
      _logFile = File('${directory.path}/$logFileName');
      await _logFile!.create(recursive: true);
      print('[DebugLogger] Log file created: ${_logFile!.path}');
    } catch (e) {
      print('[DebugLogger] Failed to create log file: $e');
      _logFile = null;
    }
  }

  Future<void> log(String message) async {
    final logLine =
        '[${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}] $message';
    if (_logFile == null) {
      await _initLogFile();
    }
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('$logLine\n', mode: FileMode.append);
      } catch (e) {
        print('[DebugLogger] Failed to write to log file: $e');
      }
    }
    // ✅ Always print to console!
    print(logLine);
  }
}
