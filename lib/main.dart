import 'package:flutter/material.dart';
import 'discover.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, String>> mangaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      List<Map<String, String>> data = await fetchMangaData();
      setState(() {
        mangaList = data;
        isLoading = false;
      });
    } catch (e) {
      // Handle error
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Manga App'),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : mangaList.isEmpty
              ? Center(
                  child: Text('No manga data available.'),
                )
              : Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 2 / 3,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: mangaList.length,
                        itemBuilder: (BuildContext context, int index) {
                          String? mangaid = mangaList[index]['manga_id'];
                          String? filename = mangaList[index]['filename'];
                          String? title = mangaList[index]['title'];

                          String imageUrl =
                              'https://mangadex.org/covers/$mangaid/$filename';

                          return Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 2 / 3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: Image.network(
                                      imageUrl,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    '$title',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    BottomNavigationBar(
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
