import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<Map<String, String>>> fetchMangaData() async {
  final String mangaApiUrl =
      'https://api.mangadex.org/manga?limit=10&order[followedCount]=desc';

  List<Map<String, String>> mangaListData = [];

  try {
    final mangaResponse = await http.get(Uri.parse(mangaApiUrl));

    if (mangaResponse.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> mangaJsonResponse =
          json.decode(mangaResponse.body);

      // Access the 'data' field containing the list of manga
      final List<dynamic> mangaList = mangaJsonResponse['data'];

      // Iterate through each manga and add the data to the list
      for (final manga in mangaList) {
        final String id = manga['id'];
        final Map<String, dynamic> titleMap = manga['attributes']['title'];

        // Find the first available title, regardless of language
        final String title = titleMap.values.first ?? 'Unknown Title';

        final String coverId = manga['relationships'].firstWhere(
            (relationship) => relationship['type'] == 'cover_art')['id'];

        // Make a separate API call to get cover information
        final String coverApiUrl =
            'https://api.mangadex.org/cover?ids[]=$coverId';
        final coverResponse = await http.get(Uri.parse(coverApiUrl));

        if (coverResponse.statusCode == 200) {
          final Map<String, dynamic> coverJsonResponse =
              json.decode(coverResponse.body);

          // Access the 'data' field containing cover information
          final Map<String, dynamic> coverData = coverJsonResponse['data'][0];
          final String fileName = coverData['attributes']['fileName'];

          // Add the manga information to the list
          mangaListData.add({
            'manga_id': id,
            'title': title,
            'filename': fileName,
          });
        } else {
          print(
              'Error retrieving cover information: ${coverResponse.statusCode}');
        }
      }
    } else {
      print('Error retrieving manga information: ${mangaResponse.statusCode}');
    }
  } catch (e) {
    print('Error: $e');
  }

  return mangaListData;
}
