import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../config/api_keys.dart';

class ImageKitService {
  final Dio _dio = Dio();

  final String _uploadUrl = "https://upload.imagekit.io/api/v1/files/upload";

  // Upload single image
  Future<Map<String, String>?> uploadImage({
    required File imageFile,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Compress image first
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        '${imageFile.path}_compressed.jpg',
        quality: 70,
        minWidth: 1024,
        minHeight: 1024,
      );

      if (compressedFile == null) {
        print('Image compression failed');
        return null;
      }

      // Create proper multipart form data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'fileName': fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg',
        'folder': folder,
      });

      // Create Basic Auth header
      final credentials =
          base64Encode(utf8.encode('${ApiKeys.imagekitPrivateKey}:'));

      print('Uploading to ImageKit...');

      // Upload with proper authentication
      Response response = await _dio.post(
        _uploadUrl,
        data: formData,
        options: Options(
          headers: {
            "Authorization": "Basic $credentials",
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Upload successful: ${response.data["url"]}');
        return {
          "url": response.data["url"] as String,
          "fileId": response.data["fileId"] as String,
          "thumbnailUrl":
              (response.data["thumbnailUrl"] ?? response.data["url"]) as String,
        };
      } else {
        print('Upload failed: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      if (e is DioException) {
        print('Error response: ${e.response?.data}');
      }
    }
    return null;
  }

  // Upload multiple images
  Future<List<Map<String, String>>> uploadMultipleImages({
    required List<File> imageFiles,
    required String folder,
  }) async {
    List<Map<String, String>> uploadedImages = [];

    for (int i = 0; i < imageFiles.length; i++) {
      print('Uploading image ${i + 1}/${imageFiles.length}');

      Map<String, String>? result = await uploadImage(
        imageFile: imageFiles[i],
        folder: folder,
        fileName: 'item_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
      );

      if (result != null) {
        uploadedImages.add(result);
      } else {
        print('Failed to upload image ${i + 1}');
      }
    }

    return uploadedImages;
  }

  // Delete image by file ID
  Future<bool> deleteImage(String fileId) async {
    try {
      final credentials =
          base64Encode(utf8.encode('${ApiKeys.imagekitPrivateKey}:'));

      Response response = await _dio.delete(
        "https://api.imagekit.io/v1/files/$fileId",
        options: Options(
          headers: {
            "Authorization": "Basic $credentials",
          },
        ),
      );

      return response.statusCode == 204;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
}
