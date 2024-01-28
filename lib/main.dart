// ignore_for_file: empty_catches, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'discover.dart';
import 'get_chapters.dart';

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
  final FocusNode titleFocus = FocusNode();
  List<Map<String, String>> mangaList = [];
  bool isLoadingPage = true;
  bool isLoadingMore = false;
  bool isError = false;
  String errorMessage = '';

  bool withText = false;
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

  @override
  void dispose() {
    titleController.dispose();
    titleFocus.dispose();
    super.dispose();
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
        isError = false;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        isLoadingPage = false;
        isError = true;
        errorMessage = 'Unable to fetch data. Please try again.';
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
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (!isEditingTitle || searchMode) {
                      searchMode = false;
                      searchString = "";
                      backIcon = false;
                      _handleRefresh();
                    } else {
                      setState(() {
                        backIcon = false;
                        titleController.text = "";
                        isEditingTitle = false;
                        titleFocus.unfocus();
                      });
                    }
                  },
                )
              : null,
          actions: [
            Visibility(
              visible: !isEditingTitle,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    isEditingTitle = true;
                    backIcon = true;
                    titleController.text = "";
                    titleFocus.requestFocus();
                  });
                },
              ),
            ),
            Visibility(
              visible: withText && isEditingTitle,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    isEditingTitle = true;
                    withText = false;
                    titleController.text = "";
                    titleFocus.requestFocus();
                  });
                },
              ),
            ),
          ],
          title: isEditingTitle
              ? TextField(
                  controller: titleController,
                  focusNode: titleFocus,
                  onChanged: (newTitle) {
                    setState(() {
                      withText = newTitle.isNotEmpty ? true : false;
                    });
                  },
                  onSubmitted: (newTitle) {
                    _searchManga(newTitle);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search....',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                )
              : Padding(
                  padding: EdgeInsets.only(
                      left:
                          backIcon ? 0 : 16.0), // Adjust the padding as needed
                  child: const Text('Home'),
                ),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: isError && !isLoadingPage
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(errorMessage),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _handleRefresh,
                              child: Text('Try Again'),
                            ),
                          ],
                        )
                      : (isLoadingPage
                          ? const CircularProgressIndicator()
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
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            MangaDetailPage(
                                          mangaData: mangaList[index],
                                        ),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          const begin = 0.0;
                                          const end = 5.0;
                                          var tween =
                                              Tween(begin: begin, end: end);
                                          var opacityAnimation =
                                              animation.drive(tween);

                                          return FadeTransition(
                                            opacity: opacityAnimation,
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 2 / 3,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            placeholder: (context, url) =>
                                                const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
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
                                            titleLabel,
                                            style: const TextStyle(
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
                            )),
                ),
              ),
              if (isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(8.0),
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
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
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

  const MangaDetailPage({required this.mangaData});

  @override
  MangaDetailPageState createState() => MangaDetailPageState();
}

class MangaDetailPageState extends State<MangaDetailPage> {
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
    } catch (e) {}
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
                ? const CircularProgressIndicator()
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image and Title in a Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image on the left
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: CachedNetworkImage(
                                  imageUrl: coverUrl,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(Icons.error),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            const SizedBox(width: 16.0),
                            // Title and Add to Favorites on the right
                            Flexible(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5.0),
                                    Text(
                                      title,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      authorName,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            Color.fromARGB(255, 170, 170, 170),
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    Text(
                                      status,
                                      style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            Color.fromARGB(255, 170, 170, 170),
                                      ),
                                    ),
                                    const SizedBox(height: 5.0),
                                    // Heart icon button and "Add to Favorites" text
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite_border,
                                          color: Color.fromARGB(255, 170, 170,
                                              170), // Change the color as needed
                                        ),
                                        const SizedBox(width: 5.0),
                                        Text(
                                          "Add to Favorites",
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            color: Color.fromARGB(
                                                255, 170, 170, 170),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16.0),
                        Text(
                          shouldShowPartialDescription &&
                                  description.length > 100
                              ? '${description.substring(0, 100)}...'
                              : description,
                          style: const TextStyle(
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
                        const SizedBox(height: 8.0),
                        const SizedBox(height: 16.0),
                        Text(
                          '${chapterList.length} chapters',
                          style: const TextStyle(
                              fontSize: 18.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: chapterList.length,
                          itemBuilder: (context, index) {
                            String? mangaId = widget.mangaData['manga_id'];
                            final chapter = chapterList[index];
                            final volume = chapter['volume'].isNotEmpty
                                ? 'Vol.${chapter['volume']}'
                                : "";
                            final chapterNumber = {
                              chapter['chapterNumber'].toString()
                            }.isNotEmpty
                                ? 'Ch.${chapter['chapterNumber'].toString()}'
                                : "";
                            final title = chapter['title'].toString();
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
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          ChapterViewPage(
                                        mangaId: mangaId,
                                        chapterList: chapterList,
                                        pageIndex: index,
                                        mangaTitle: widget.mangaData['title'],
                                        // Add other parameters if needed
                                      ),
                                      transitionsBuilder: (context, animation,
                                          secondaryAnimation, child) {
                                        const begin = 0.0;
                                        const end = 5.0;
                                        var tween =
                                            Tween(begin: begin, end: end);
                                        var opacityAnimation =
                                            animation.drive(tween);

                                        return FadeTransition(
                                          opacity: opacityAnimation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: const BoxDecoration(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 1.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$volume$chapterNumber$titleLabel',
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        Text(
                                          '${chapter['publishDate']?.split("T")[0]}',
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 20.0),
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
    );
  }
}

class ChapterViewPage extends StatefulWidget {
  final String? mangaId;
  final List<Map<String, dynamic>> chapterList;
  final int pageIndex;
  final int initialIndex;
  final String? mangaTitle;

  const ChapterViewPage({
    required this.mangaId,
    required this.chapterList,
    required this.pageIndex,
    this.initialIndex = 2,
    required this.mangaTitle,
  });

  @override
  ChapterPageState createState() => ChapterPageState();
}

class ChapterPageState extends State<ChapterViewPage> {
  List<String> imageUrls = [];
  late PageController pageController;
  late Future<List<String>> imageUrlsFuture;

  int pageIndex = 0;
  bool isPrevious = false;
  bool isAppBarVisible = false;

  int currentPage = 1;

  late String volume;
  late String chapterNumber;
  late String title;
  late String titleLabel;

  @override
  void initState() {
    super.initState();
    // Initialize the list of image URLs based on mangaId and coverId
    pageIndex = widget.pageIndex;
    _initializeImageUrls();
    _updateAppbartext();
  }

  Future<void> _initializeImageUrls() async {
    imageUrlsFuture =
        getChapterPages(widget.chapterList[pageIndex]['chapter_id']);
    try {
      List<String> fetchedImages = await imageUrlsFuture;
      setState(() {
        imageUrls.clear();
        imageUrls = fetchedImages;

        int offset = pageIndex != widget.chapterList.length - 1 ? 0 : 1;
        if (isPrevious) {
          pageController =
              PageController(initialPage: imageUrls.length + 1 - offset);
          currentPage = imageUrls.length;
        } else {
          pageController =
              PageController(initialPage: widget.initialIndex - offset);
          currentPage = 1;
        }
      });
    } catch (e) {
      // Handle error
    }
  }

  void _updateAppbartext() {
    final chapter = widget.chapterList[pageIndex];
    volume = {chapter['volume'].toString()}.isNotEmpty
        ? 'Vol.${chapter['volume'].toString()}'
        : "";
    chapterNumber = {chapter['chapterNumber'].toString()}.isNotEmpty
        ? 'Ch.${chapter['chapterNumber'].toString()}'
        : "";
    final titleUnformated = chapter['title'].toString();
    title = titleUnformated.isNotEmpty
        ? titleUnformated.length > 35
            ? '-${titleUnformated.substring(0, 35 - 3)}...'
            : '-$titleUnformated'
        : '';
  }

  void nextChapter() {
    setState(() {
      isPrevious = false;
      pageIndex--;
      _initializeImageUrls();
      _updateAppbartext();
    });
  }

  void previousChapter() {
    setState(() {
      isPrevious = true;
      pageIndex++;
      _initializeImageUrls();
      _updateAppbartext();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  isAppBarVisible = !isAppBarVisible;
                });
              },
              child: FutureBuilder<List<String>>(
                future: imageUrlsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError || snapshot.data == null) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            imageUrlsFuture = getChapterPages(
                                widget.chapterList[pageIndex]['chapter_id']);
                          });
                        },
                        child: const Text('Refresh'),
                      ),
                    );
                  } else {
                    return _buildPhotoViewGallery();
                  }
                },
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: isAppBarVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: AppBar(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.mangaTitle}',
                      style: const TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$volume $chapterNumber$title',
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
                centerTitle: false, // Align the title to the left
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoViewGallery() {
    return FutureBuilder<List<String>>(
      future: imageUrlsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  imageUrlsFuture = getChapterPages(
                      widget.chapterList[pageIndex]['chapter_id']);
                });
              },
              child: const Text('Refresh'),
            ),
          );
        } else {
          int itemcount = 0;
          if (pageIndex == widget.chapterList.length - 1 || pageIndex == 0) {
            itemcount = imageUrls.length + 3;
          } else {
            itemcount = imageUrls.length + 4;
          }
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: PhotoViewGallery.builder(
                      itemCount: itemcount,
                      builder: (context, index) {
                        int offset =
                            pageIndex != widget.chapterList.length - 1 ? 1 : 0;
                        if (index < 1 + offset) {
                          if (pageIndex != widget.chapterList.length - 1) {
                            final chapter = widget.chapterList[pageIndex + 1];
                            String prevvolume =
                                {chapter['volume'].toString()}.isNotEmpty
                                    ? 'Vol.${chapter['volume'].toString()}'
                                    : "";
                            String prevchapterNumber = {
                              chapter['chapterNumber'].toString()
                            }.isNotEmpty
                                ? 'Ch.${chapter['chapterNumber'].toString()}'
                                : "";
                            final prevTitle = chapter['title'].toString();
                            final currentTitle = widget.chapterList[pageIndex]
                                    ['title']
                                .toString();
                            return PhotoViewGalleryPageOptions.customChild(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Previous:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "$prevvolume $prevchapterNumber$prevTitle",
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                    const Text(
                                      'Current:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$volume $chapterNumber$currentTitle',
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                  ],
                                ),
                              ),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                            );
                          } else {
                            return PhotoViewGalleryPageOptions.customChild(
                              child: Container(
                                alignment: Alignment.center,
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "There's no previous chapter.",
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 20.0),
                                    ),
                                  ],
                                ),
                              ),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                            );
                          }
                        } else if (index > imageUrls.length + offset) {
                          if (pageIndex != 0) {
                            final chapter = widget.chapterList[pageIndex - 1];
                            String prevvolume =
                                {chapter['volume'].toString()}.isNotEmpty
                                    ? 'Vol.${chapter['volume'].toString()}'
                                    : "";
                            String prevchapterNumber = {
                              chapter['chapterNumber'].toString()
                            }.isNotEmpty
                                ? 'Ch.${chapter['chapterNumber'].toString()}'
                                : "";
                            final prevTitle = chapter['title'].toString();
                            final currentTitle = widget.chapterList[pageIndex]
                                    ['title']
                                .toString();
                            return PhotoViewGalleryPageOptions.customChild(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Next:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "$prevvolume $prevchapterNumber$prevTitle",
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                    const Text(
                                      'Current:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$volume $chapterNumber$currentTitle',
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                  ],
                                ),
                              ),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                            );
                          } else {
                            final currentTitle = widget.chapterList[pageIndex]
                                    ['title']
                                .toString();
                            return PhotoViewGalleryPageOptions.customChild(
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(30.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Finished:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '$volume $chapterNumber$currentTitle',
                                      softWrap: true,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                  ],
                                ),
                              ),
                              minScale: PhotoViewComputedScale.contained,
                              maxScale: PhotoViewComputedScale.covered * 2,
                            );
                          }
                        } else {
                          return PhotoViewGalleryPageOptions(
                            imageProvider: CachedNetworkImageProvider(
                              imageUrls[index - (1 + offset)],
                            ),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          );
                        }
                      },
                      scrollPhysics: const BouncingScrollPhysics(),
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.black,
                      ),
                      pageController: pageController,
                      onPageChanged: (index) {
                        int offset =
                            pageIndex != widget.chapterList.length - 1 ? 0 : 1;
                        setState(() {
                          currentPage = index - (1 - offset);
                        });
                        if (index == 0) {
                          if (pageIndex == widget.chapterList.length - 1) {
                            return;
                          }
                          previousChapter();
                        } else if (index == imageUrls.length + 3 - offset) {
                          if (pageIndex == 0) {
                            return;
                          }
                          nextChapter();
                        }
                      },
                    ),
                  ),
                ],
              ),
              Visibility(
                visible: currentPage < 1 || currentPage > imageUrls.length
                    ? false
                    : true,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    color: Colors.black.withOpacity(0),
                    child: Text(
                      '$currentPage / ${imageUrls.length}',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        }
      },
    );
  }
}
