import 'package:alsaif_gallery/screens/SearchScreen.dart';
import 'package:alsaif_gallery/screens/favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:alsaif_gallery/api/home_api_service.dart';
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeApiService apiService = HomeApiService();
  List<String> parentCategories = ['All'];
  List<dynamic> advertisements = [];
  bool isLoadingParent = true;
  bool isLoadingAds = false;
  bool isLoadingSearch = false;
  String? selectedParentCategory;
  String searchQuery = '';

  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];

  int _selectedIndex = 0;
  int currentIndex = 0;
  Color bColor = Colors.white;

  PageController _pageController = PageController();

  final List<String> _topBanners = [
    'assets/payment_banner.png',
    'assets/paywitharab.png',
  ];

  @override
  void initState() {
    super.initState();
    fetchParentCategories();
    fetchAdvertisements();
    fetchAllProducts();
  }

  Future<void> fetchParentCategories() async {
    try {
      final response =
          await apiService.get('/api/v1/category/getParentCategories');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          setState(() {
            parentCategories.addAll(List<String>.from(data['data']
                .map((category) => category['categoryName'] ?? '')));
            selectedParentCategory =
                parentCategories.isNotEmpty ? parentCategories[0] : null;
          });
        }
      }
    } catch (e) {
      // Handle error here
    } finally {
      setState(() {
        isLoadingParent = false;
      });
    }
  }

  Future<void> fetchAdvertisements() async {
    setState(() => isLoadingAds = true);
    try {
      final response = await http.get(Uri.parse(
          "http://alsaifgallery.onrender.com/api/v1/advertisement/getSampleAdd"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          advertisements = data['data'] ?? [];
        });
      }
    } catch (e) {
      // Handle error here
    } finally {
      setState(() {
        isLoadingAds = false;
      });
    }
  }

  Future<void> fetchAllProducts() async {
    setState(() => isLoadingSearch = true);
    try {
      final response = await apiService.get('/api/v1/products/getAllProducts');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          allProducts = data['data'] ?? [];
          filteredProducts = allProducts;
        });
      }
    } catch (e) {
      // Handle error here
    } finally {
      setState(() {
        isLoadingSearch = false;
      });
    }
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query;
      filteredProducts = allProducts
          .where((product) => product['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/loggo.png', height: 33),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            SearchScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 35.0,
                    child: TextField(
                      enabled: false, // Disable editing
                      decoration: InputDecoration(
                        hintText: 'Find it here...',
                        hintStyle:
                            TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 14.0),
                        suffixIcon: Icon(Icons.search,
                            color: Colors.grey[600], size: 20.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.black),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(favoriteProducts: []),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                Container(height: 1.0, color: Colors.grey[300]),
                searchQuery.isNotEmpty
                    ? isLoadingSearch
                        ? const Center(child: CircularProgressIndicator())
                        : filteredProducts.isEmpty
                            ? const Center(child: Text("No products found"))
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return ListTile(
                                    title: Text(
                                        product['name'] ?? 'Unnamed Product'),
                                    onTap: () {},
                                  );
                                },
                              )
                    : buildCategoriesAndAds(),
              ],
            )
          : Container(),
    );
  }

  Widget buildCategoriesAndAds() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          height: 46,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parentCategories.length,
            itemBuilder: (context, index) {
              final categoryName = parentCategories[index];
              return Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedParentCategory = categoryName;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(
                          bottom: BorderSide(
                            color: selectedParentCategory == categoryName
                                ? Colors.red
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(categoryName,
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  if (index < parentCategories.length - 1)
                    VerticalDivider(
                        color: Colors.grey[300], width: 1, thickness: 1),
                ],
              );
            },
          ),
        ),
        if (selectedParentCategory != null &&
            selectedParentCategory == parentCategories.first) ...[
          CarouselSlider(
            options: CarouselOptions(
              height: 31.0,
              autoPlay: true,
              viewportFraction: 1.0,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {});
              },
            ),
            items: _topBanners.map((banner) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    margin: EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(color: Colors.amber),
                    child: Image.asset(banner, fit: BoxFit.cover),
                  );
                },
              );
            }).toList(),
          ),
          SizedBox(height: 5),
        ],
        isLoadingAds
            ? const Center(child: CircularProgressIndicator())
            : advertisements.isEmpty
                ? const Center(child: Text("No advertisements"))
                : buildAdvertisements(),
      ],
    );
  }

  Widget buildAdvertisements() {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: advertisements.length,
          itemBuilder: (context, index, realIndex) {
            final ad = advertisements[index];
            final adImageUrl =
                ad['imageId'] != null ? ad['imageId']['data'] : null;

            return GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(8.0)),
                child: adImageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          adImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 50, color: Colors.grey)),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.broken_image,
                            size: 50, color: Colors.grey)),
              ),
            );
          },
          options: CarouselOptions(
            autoPlay: true,
            enlargeCenterPage: true,
            aspectRatio: 16 / 9,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() {
                currentIndex = index;
              });
            },
          ),
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(advertisements.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              height: 8.0,
              width: currentIndex == index ? 20.0 : 8.0,
              decoration: BoxDecoration(
                color: currentIndex == index ? Colors.red : Colors.grey,
                borderRadius: BorderRadius.circular(5.0),
              ),
            );
          }),
        ),
      ],
    );
  }
}