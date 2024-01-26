import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'discover.dart';
import 'getChapterlist.dart';

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
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'Home'),
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
  bool isEditingTitle = false; // Track whether the title is being edited
  TextEditingController titleController = TextEditingController();
  List<Map<String, String>> mangaList = [];
  bool isLoadingPage = true;
  bool isLoadingMore = false;
  int offset = 0;
  bool searchMode = false;
  String searchString = "";
  bool backIcon = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchData();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        // Reached the bottom of the list, load more data
        _loadMoreData();
      }
    });
  }

  Future<void> fetchData() async {
    try {
      List<Map<String, String>> data =
          await fetchMangaData(offset, searchMode, searchString);
      setState(() {
        mangaList = data;
        isLoadingPage = false;
      });
    } catch (e) {
      // Handle error
      print('Error fetching data: $e');
      setState(() {
        isLoadingPage = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore) {
      return; // Do not load more data if already loading
    }

    setState(() {
      isLoadingMore = true;
      offset += 50; // Increment the offset for pagination
    });

    try {
      List<Map<String, String>> newData =
          await fetchMangaData(offset, searchMode, searchString);

      setState(() {
        mangaList.addAll(newData); // Append new data to the existing list
        isLoadingMore = false;
      });
    } catch (e) {
      print('Error fetching more data: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      isLoadingPage = true;
      mangaList.clear();
      offset = 0;
      if (!searchMode) {
        isEditingTitle = false;
      }
    });

    try {
      await fetchData();
    } finally {
      setState(() {
        isLoadingPage = false;
      });
    }
  }

  // ignore: non_constant_identifier_names
  Future<void> _searchManga(String title) async {
    setState(() {
      isLoadingPage = true;
      mangaList.clear();
      offset = 0;
      searchMode = true;
      searchString = title;
      backIcon = true;
    });

    try {
      await fetchData();
    } finally {
      setState(() {
        isLoadingPage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !backIcon,
      onPopInvoked: (bool didPop) {
        searchMode = false;
        searchString = "";
        backIcon = false;
        _handleRefresh();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: backIcon
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    searchMode = false;
                    searchString = "";
                    backIcon = false;
                    _handleRefresh();
                  },
                )
              : null,
          actions: [
            Visibility(
              visible: !backIcon,
              child: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    if (isEditingTitle) {
                      isEditingTitle = false;
                    } else {
                      isEditingTitle = true;
                      titleController.text = "";
                    }
                  });
                },
              ),
            ),
          ],
          title: isEditingTitle
              ? TextField(
                  controller: titleController,
                  onSubmitted: (newTitle) {
                    _searchManga(newTitle);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search....',
                    border: InputBorder.none,
                  ),
                  style: TextStyle(color: Colors.white),
                )
              : Padding(
                  padding: EdgeInsets.only(
                      left:
                          backIcon ? 0 : 16.0), // Adjust the padding as needed
                  child: Text('Home'),
                ),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: isLoadingPage
                      ? CircularProgressIndicator()
                      : GridView.builder(
                          controller: _scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 15.0,
                            childAspectRatio: 2 / 3,
                            mainAxisSpacing: 15.0,
                          ),
                          itemCount: mangaList.length,
                          itemBuilder: (BuildContext context, int index) {
                            String? mangaid = mangaList[index]['manga_id'];
                            String? filename = mangaList[index]['filename'];
                            String? title = mangaList[index]['title'];
                            String titleLabel = title!.isNotEmpty
                                ? title.length > 50
                                    ? '-${title.substring(0, 50 - 3)}...'
                                    : '-$title'
                                : '';

                            String imageUrl =
                                'https://mangadex.org/covers/$mangaid/$filename';

                            return GestureDetector(
                              onTap: () {
                                // Navigate to the new page when an item is tapped
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MangaDetailPage(
                                        mangaData: mangaList[index]),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  AspectRatio(
                                    aspectRatio: 2 / 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        placeholder: (context, url) => Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                        fit: BoxFit.cover,
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
                                            Colors.black.withOpacity(0.6),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        '$titleLabel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
              if (isLoadingMore)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
          ],
          //currentIndex: _selectedIndex,
          //onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class MangaDetailPage extends StatefulWidget {
  final Map<String, String> mangaData;

  MangaDetailPage({required this.mangaData});

  @override
  _MangaDetailPageState createState() => _MangaDetailPageState();
}

class _MangaDetailPageState extends State<MangaDetailPage> {
  bool shouldShowPartialDescription = true;
  String authorName = ''; // Add a variable to store the author name
  bool isLoading = true;
  List<Map<String, dynamic>> chapterList = [];

  @override
  void initState() {
    super.initState();
    // Call the function to get the author name when the page is loaded
    _loadAuthorName();
    _getChapterList();
  }

  Future<void> _loadAuthorName() async {
    try {
      String? authorId = widget
          .mangaData['authorId']; // Replace with the actual key for authorId

      // Call the getAuthorName function and set the result to the authorName variable
      String? name = await getAuthorName(authorId!); // Make name nullable
      setState(() {
        authorName = name; // Use the null-aware operator to handle null
      });
    } catch (e) {
      print('Error loading author name: $e');
    }
  }

  Future<void> _getChapterList() async {
    try {
      String? mangaId = widget.mangaData['manga_id'];
      List<Map<String, dynamic>>? data = await getChapters(mangaId!);
      setState(() {
        chapterList = data!;
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

  Future<void> _refresh() async {
    await _loadAuthorName();
    chapterList.clear();
    await _getChapterList();
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.mangaData['title'] ?? 'Unknown Title';
    String coverUrl =
        'https://mangadex.org/covers/${widget.mangaData['manga_id']}/${widget.mangaData['filename']}';
    String description =
        widget.mangaData['description'] ?? 'No description available';
    String status = widget.mangaData['status'] ?? 'Unknown Status';

    return Scaffold(
      appBar: AppBar(),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          child: Center(
            child: isLoading
                ? CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image and Title in a Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image on the left
                              Container(
                                width: MediaQuery.of(context).size.width * 0.3,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: coverUrl,
                                    placeholder: (context, url) => Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              SizedBox(width: 16.0),
                              // Title on the right
                              Flexible(
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 5.0),
                                      Text(
                                        title,
                                        style: TextStyle(fontSize: 20.0),
                                      ),
                                      SizedBox(height: 8.0),
                                      Text(
                                        '$authorName',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600,
                                            color: Color.fromARGB(
                                                255, 170, 170, 170)),
                                      ),
                                      SizedBox(height: 5.0),
                                      Text(
                                        '$status',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w500,
                                            color: Color.fromARGB(
                                                255, 170, 170, 170)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            shouldShowPartialDescription &&
                                    description.length > 100
                                ? '${description.substring(0, 100)}...'
                                : description,
                            style: TextStyle(
                                fontSize: 16.0,
                                color: Color.fromARGB(255, 161, 161, 161)),
                          ),
                          if (description.length > 100)
                            Align(
                              alignment: Alignment.center,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    shouldShowPartialDescription =
                                        !shouldShowPartialDescription;
                                  });
                                },
                                child: Text(
                                  shouldShowPartialDescription
                                      ? 'Show All'
                                      : 'Show Less',
                                ),
                              ),
                            ),
                          SizedBox(height: 8.0),
                          SizedBox(height: 16.0),
                          Text(
                            '${chapterList.length} chapters',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8.0),

                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: chapterList.length,
                            itemBuilder: (context, index) {
                              String? mangaId = widget.mangaData['manga_id'];
                              final chapter = chapterList[index];
                              List<String> coverIds = chapterList
                                  .map((item) => item['chapter_id'].toString())
                                  .toList();
                              final volume = chapter['volume'] ?? "";
                              final chapterNumber =
                                  chapter['chapterNumber'] ?? "";
                              final title = chapter['title'] ?? "";
                              final volLabel =
                                  volume.isNotEmpty ? 'Vol.$volume' : "";
                              final chapLabel = chapterNumber.isNotEmpty
                                  ? 'Ch.$chapterNumber'
                                  : "";
                              final titleLabel = title.isNotEmpty
                                  ? title.length > 35
                                      ? '-${title.substring(0, 35 - 3)}...'
                                      : '-$title'
                                  : '';

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 1.0),
                                child: GestureDetector(
                                  onTap: () {
                                    // Navigate to the photo_view page and pass mangaId and coverId
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChapterViewPage(
                                          mangaId: mangaId,
                                          coverIds: coverIds,
                                          pageIndex: index,
                                          // Add other parameters if needed
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 1.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '$volLabel$chapLabel$titleLabel',
                                            style: TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          Text(
                                            '${chapter['publishDate']?.split("T")[0]}',
                                            style: TextStyle(
                                              fontSize: 12.0,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          SizedBox(height: 20.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class ChapterViewPage extends StatefulWidget {
  final String? mangaId;
  List<String> coverIds;
  final int pageIndex;
  final int initialIndex; // If you want to show a specific image initially

  ChapterViewPage({
    required this.mangaId,
    required this.coverIds,
    required this.pageIndex,
    this.initialIndex = 0,
  });

  @override
  _ChapterPageState createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterViewPage> {
  List<String> imageUrls = [];
  late PageController pageController;
  late Future<List<String>> imageUrlsFuture;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the list of image URLs based on mangaId and coverId
    pageIndex = widget.pageIndex;
    _initializeImageUrls();
    pageController = PageController(initialPage: widget.initialIndex);
  }

  Future<void> _initializeImageUrls() async {
    imageUrlsFuture = getChapterPages(widget.coverIds[pageIndex]);
    try {
      List<String> fetchedImages = await imageUrlsFuture;
      setState(() {
        imageUrls = fetchedImages;
      });
    } catch (e) {
      // Handle error
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<String>>(
        future: imageUrlsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    imageUrlsFuture =
                        getChapterPages(widget.coverIds[pageIndex]);
                  });
                },
                child: Text('Refresh'),
              ),
            );
          } else {
            return _buildPhotoViewGallery();
          }
        },
      ),
    );
  }

  Widget _buildPhotoViewGallery() {
    return PhotoViewGallery.builder(
      itemCount: imageUrls.length,
      builder: (context, index) {
        return PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(imageUrls[index]),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
        );
      },
      scrollPhysics: BouncingScrollPhysics(),
      backgroundDecoration: BoxDecoration(
        color: Colors.black,
      ),
      pageController: pageController,
      onPageChanged: (index) {},
    );
  }
}
