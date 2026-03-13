import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class ImageDownloader {
  static Future<String?> downloadImage(String url, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';
      
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      
      final file = File(filePath);
      await file.writeAsBytes(response.data);
      return filePath;
    } catch (e) {
      return null;
    }
  }
}
