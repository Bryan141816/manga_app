import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, dynamic>>?> _getChapters(
    String mangaId, int offset) async {
  List<Map<String, dynamic>> chapterIds = [];

  final String url =
      "https://api.mangadex.org/chapter?manga=$mangaId&limit=100&offset=$offset&translatedLanguage[]=en&order[chapter]=desc";
  try {
    final chapterListresponse = await http.get(Uri.parse(url));
    if (chapterListresponse.statusCode == 200) {
      final Map<String, dynamic> chapterJsonResponse =
          json.decode(chapterListresponse.body);
      final List<dynamic> chapterList = chapterJsonResponse['data'];
      for (final chapter in chapterList) {
        final String id = chapter['id'];
        final String volume = chapter["attributes"]["volume"] ?? "";
        final String chapterNumber = chapter["attributes"]["chapter"] ?? "";
        final String title = chapter["attributes"]["title"] ?? "";
        final String pubishDate = chapter["attributes"]["publishAt"] ?? "";
        final int pageNumber = chapter["attributes"]["pages"];
        if (pageNumber > 0) {
          chapterIds.add({
            'chapter_id': id,
            'volume': volume,
            'chapterNumber': chapterNumber,
            'title': title,
            'publishDate': pubishDate,
          });
        }
      }
    }
  } catch (e) {
    print('Error: $e');
    // Rethrow the error to be caught by the retry mechanism
    rethrow;
  }
  return chapterIds;
}

Future<List<Map<String, dynamic>>?> getChapters(String mangaId) async {
  List<Map<String, dynamic>> chapterIds = [];
  int offset = 0;
  while (true) {
    final chapters = await _getChapters(mangaId, offset);
    if (chapters != null && chapters.isNotEmpty) {
      for (var element in chapters) {
        chapterIds.add(element);
      }
      offset += 100; // Increase offset for the next set of chapters
    } else {
      break;
    }
  }
  return chapterIds;
}

Future<Map<String, dynamic>> _getChapterPages(String coverId) async {
  final apiUrl = 'https://api.mangadex.org/at-home/server/$coverId';

  try {
    http.Response response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResult = json.decode(response.body);

      if (jsonResult['result'] == 'ok' &&
          jsonResult.containsKey('baseUrl') &&
          jsonResult.containsKey('chapter')) {
        String baseUrl = jsonResult['baseUrl'];
        String hash = jsonResult['chapter']['hash'];
        List<String> data = List<String>.from(jsonResult['chapter']['data']);
        List<String> dataSaver =
            List<String>.from(jsonResult['chapter']['dataSaver']);

        // Creating a Map to store the extracted values
        Map<String, dynamic> result = {
          'baseUrl': baseUrl,
          'hash': hash,
          'data': data,
          'dataSaver': dataSaver,
        };

        // Returning the Map
        return result;
      } else {
        throw Exception('Error in API response');
      }
    } else {
      throw Exception('Error: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}

Future<List<String>> getChapterPages(String coverId) async {
  List<String> imageList = [];
  Map<String, dynamic> page = await _getChapterPages(coverId);
  String baseUrl = page["baseUrl"];
  String hash = page["hash"];
  List<String> data = page["data"];
  for (final file in data) {
    String url = '$baseUrl/data/$hash/$file';
    imageList.add(url);
  }
  return imageList;
}
