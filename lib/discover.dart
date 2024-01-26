import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, String>>> fetchMangaDataWithRetry(
    int offset, bool searchMode, String searchString) async {
  // Number of times to retry the API call
  const int maxRetries = 3;
  int retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      return await fetchMangaData(offset, searchMode, searchString);
    } catch (e) {
      retryCount++;
    }
  }

  // If all retries fail, throw the last encountered error
  throw Exception('Failed to fetch manga data after $maxRetries retries');
}

Future<List<Map<String, String>>> fetchMangaData(
    int offset, bool searchMode, String searchString) async {
  String title = "";
  if (searchMode) {
    title = "&title=$searchString";
  }
  final String mangaApiUrl =
      'https://api.mangadex.org/manga?limit=50&offset=$offset&order[followedCount]=desc$title';

  List<Map<String, String>> mangaListData = [];
  List<String> coverIds = [];

  try {
    final mangaResponse = await http.get(Uri.parse(mangaApiUrl));

    if (mangaResponse.statusCode == 200) {
      final Map<String, dynamic> mangaJsonResponse =
          json.decode(mangaResponse.body);

      final List<dynamic> mangaList = mangaJsonResponse['data'];

      for (final manga in mangaList) {
        final String id = manga['id'];
        final Map<String, dynamic> titleMap = manga['attributes']['title'];
        final String title = titleMap.values.first ?? 'Unknown Title';
        final String description =
            manga['attributes']['description']['en'] ?? 'No Description.';
        final String status = manga['attributes']['status'] ?? 'Unknown';
        final String coverId = manga['relationships'].firstWhere(
            (relationship) => relationship['type'] == 'cover_art')['id'];

        final String autorId = manga['relationships'].firstWhere(
            (relationship) => relationship['type'] == 'author')['id'];
        coverIds.add(coverId);
        mangaListData.add({
          'manga_id': id,
          'title': title,
          'description': description,
          'status': status,
          'coverId': coverId,
          'authorId': autorId,
        });
      }

      final String coverApiUrl =
          'https://api.mangadex.org/cover?limit=50&ids[]=${coverIds.join("&ids[]=")}';
      final coverResponse = await http.get(Uri.parse(coverApiUrl));

      if (coverResponse.statusCode == 200) {
        final Map<String, dynamic> coverJsonResponse =
            json.decode(coverResponse.body);

        final List<dynamic> coverDataList = coverJsonResponse['data'];

        for (int i = 0; i < mangaListData.length; i++) {
          final String fileName = coverDataList[i]['attributes']['fileName'];
          final String cid = coverDataList[i]['id'];
          for (int y = 0; y < mangaListData.length; y++) {
            if (mangaListData[y]['coverId'] == cid) {
              mangaListData[y]['filename'] = fileName;
            }
          }
        }
      } else {
        /*print(
            'Error retrieving cover information: ${coverResponse.statusCode}');*/
      }
    } else {
      //print('Error retrieving manga information: ${mangaResponse.statusCode}');
    }
  } catch (e) {
    //print('Error: $e');
    // Rethrow the error to be caught by the retry mechanism
    rethrow;
  }

  return mangaListData;
}

Future<String> getAuthorName(String authorId) async {
  String authorName = "";
  final String authorUrl = 'https://api.mangadex.org/author/$authorId';

  try {
    final authorResponse = await http.get(Uri.parse(authorUrl));

    if (authorResponse.statusCode == 200) {
      final Map<String, dynamic> authorJsonResponse =
          json.decode(authorResponse.body);
      authorName =
          authorJsonResponse['data']['attributes']['name'] ?? 'Unknown Author';
    } else {
      /*print(
          'Error retrieving author information: ${authorResponse.statusCode}');*/
    }
  } catch (e) {
    //print('Error: $e');
    // Handle the error as needed
  }

  return authorName;
}
