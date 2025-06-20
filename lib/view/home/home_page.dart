// File: lib/view/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Untuk HTTP requests
import 'dart:convert'; // Untuk JSON decoding
import 'package:shared_preferences/shared_preferences.dart'; // Untuk token & username

// Import komponen kustom Anda
import 'package:masak2/view/home/popup_search.dart';
import 'package:masak2/view/component/trending_recipe_card.dart'; // Pastikan file ini sudah diupdate
import 'package:masak2/view/component/bottom_navbar.dart';
import 'package:masak2/view/component/category_tab.dart';
import 'package:masak2/theme/theme.dart';

// Import models Anda
import 'package:masak2/models/food_model.dart'; // <<< PASTIKAN FILE INI SUDAH DIUPDATE
import 'package:masak2/models/user_profile_model.dart'; // <<< PASTIKAN FILE INI SUDAH DIUPDATE
import 'package:masak2/models/category_model.dart'; // Pastikan file ini sudah diupdate

// Impor FoodCard sebagai komponen eksternal
import 'package:masak2/view/component/food_card_widget.dart'; // <<< PASTIKAN FILE INI SUDAH DIUPDATE

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variables for fetched data
  bool _isLoading = true; 
  bool _hasError = false; 
  String _errorMessage = ''; 

  String _loggedInUsername = 'people'; // Default ke 'people' jika belum login
  List<Food> _trendingRecipes = []; 
  List<UserProfile> _bestUsers = []; 
  List<Food> _latestRecipes = []; 
  List<Food> _userRecipes = []; 
  List<Category> _categories = []; // Ini akan menampung kategori dari API

  int _selectedCategoryIndex = -1;



  // Base URL for your backend API
  final String _baseUrl = 'http://192.168.100.44:3000'; // <<<--- GANTI DENGAN IP BACKEND ANDA YANG BENAR

  @override
  void initState() {
    super.initState();
    _fetchHomeData(); // Panggil fetching API saat initState
  }

  Future<void> _fetchHomeData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token'); 
      final usernameFromPrefs = prefs.getString('username'); 

      // Atur username: jika ada, gunakan username; jika tidak, gunakan 'people'
      if (usernameFromPrefs != null && usernameFromPrefs.isNotEmpty) {
        _loggedInUsername = usernameFromPrefs; 
      } else {
        _loggedInUsername = 'people';
      }
      print('DEBUG: Mulai fetch home data. Username dari prefs: $_loggedInUsername');

      final response = await http.get(
        Uri.parse('$_baseUrl/home'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token', 
        },
      );

      print('DEBUG: Status Code API: ${response.statusCode}');
      print('DEBUG: Response Body API: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...'); // Cetak sebagian saja agar tidak terlalu panjang

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final Map<String, dynamic> data = responseData['data'];

        print('DEBUG: JSON data parsed successfully.');

        setState(() {
          print('DEBUG: Parsing trending recipes...');
          _trendingRecipes = (data['trendingRecipes'] as List)
              .map((jsonItem) {
                print('  DEBUG Parsing Trending Item: $jsonItem');
                final food = Food.fromJson(jsonItem);
                print('  DEBUG Parsed Food (Trending): name="${food.name}", image="${food.image}", rating="${food.rating}", cookingTime="${food.cookingTime}", price="${food.price}", description="${food.description}"');
                return food;
              })
              .toList();
          print('DEBUG: Trending recipes parsed. Count: ${_trendingRecipes.length}');

          print('DEBUG: Parsing best users...');
          _bestUsers = (data['bestUsers'] as List)
              .map((jsonItem) {
                print('  DEBUG Parsing Best User Item: $jsonItem');
                final user = UserProfile.fromJson(jsonItem);
                print('  DEBUG Parsed UserProfile: username="${user.username}", profilePicture="${user.profilePicture}", recipeCount="${user.recipeCount}", fullName="${user.fullName}", email="${user.email}"');
                return user;
              }) 
              .toList();
          print('DEBUG: Best users parsed. Count: ${_bestUsers.length}');

          print('DEBUG: Parsing latest recipes...');
          _latestRecipes = (data['latestRecipes'] as List)
              .map((jsonItem) => Food.fromJson(jsonItem))
              .toList();
          print('DEBUG: Latest recipes parsed. Count: ${_latestRecipes.length}');

          print('DEBUG: Parsing user recipes...');
          if (data['userRecipes'] != null && (data['userRecipes'] as List).isNotEmpty) {
            _userRecipes = (data['userRecipes'] as List)
                .map((jsonItem) => Food.fromJson(jsonItem))
                .toList();
          } else {
            _userRecipes = [];
          }
          print('DEBUG: User recipes parsed. Count: ${_userRecipes.length}');

          print('DEBUG: Parsing categories...');
          _categories = (data['categories'] as List) 
              .map((jsonItem) => Category.fromJson(jsonItem)) 
              .toList();
          print('DEBUG: Categories parsed. Count: ${_categories.length}');

          _isLoading = false;
          print('DEBUG: SetState complete. Loading finished.');
        }); // End setState
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Gagal memuat data beranda: ${response.statusCode} ${response.reasonPhrase}';
          _isLoading = false;
        });
        print('[ERROR] Failed to load home data: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      print('[EXCEPTION] Error fetching home data in catch block: $e'); 
      rethrow; // Re-throw error untuk melihat stack trace lengkap
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavbar(
      Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopSection(context),
                        CategoryTabBar(
                          // Ini akan menggunakan kategori dari API.
                          // Jika Anda benar-benar ingin hardcoded 'mealTypes', GANTI BARIS DI BAWAH INI:
                          // categories: mealTypes,
                          categories: _categories.map((cat) => cat.name).toList(), 
                          selectedIndex: _selectedCategoryIndex,
                          primaryColor: AppTheme.primaryColor,
                          onCategorySelected: (index) {
                            setState(() {
                              _selectedCategoryIndex = index;
                              // TODO: Implement filtering logic jika diperlukan
                            });
                          },
                           // Ganti dengan warna utama Anda
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- SEMUA SECTION KONTEN UTAMA DIBAWAH INI AKAN DIAKTIFKAN ---
                                _buildTrendingRecipeSection(context),
                                
                                if (_userRecipes.isNotEmpty) 
                                  _buildYourRecipesSection(context),
                                
                                _buildTopUsersSection(context),
                                
                                _buildRecentlyAddedRecipeSection(context),

                                const SizedBox(height: 70), 
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // --- DEFINISI WIDGET SECTION LAINNYA DI DALAM CLASS INI ---

  Widget _buildTopSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB( AppTheme.spacingXLarge, AppTheme.spacingXLarge, AppTheme.spacingXXLarge, AppTheme.spacingLarge, ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text( 'Hi! $_loggedInUsername', style: TextStyle( color: AppTheme.primaryColor, fontSize: 24, fontWeight: FontWeight.bold, ), ),
              SizedBox(height: AppTheme.spacingSmall),
              const Text( 'Masak apa hari ini?', style: TextStyle(fontSize: 14, color: Colors.black54), ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () { Navigator.pushNamed(context, '/notif'); },
                child: Container(
                  width: AppTheme.favoriteButtonSize, height: AppTheme.favoriteButtonSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, image: DecorationImage( image: AssetImage('images/notif.png'), fit: BoxFit.cover, ), ), ),
              ),
              SizedBox(width: AppTheme.spacingMedium),
              GestureDetector(
                onTap: () { Navigator.pushNamed(context, '/penjadwalan'); },
                child: Container(
                  width: AppTheme.favoriteButtonSize, height: AppTheme.favoriteButtonSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, image: DecorationImage( image: AssetImage('images/calendar.png'), fit: BoxFit.cover, ), ), ),
              ),
              SizedBox(width: AppTheme.spacingMedium),
              GestureDetector(
                onTap: () { showRecipeRecommendationsTopSheet(context); },
                child: Container(
                  width: AppTheme.favoriteButtonSize, height: AppTheme.favoriteButtonSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle, image: DecorationImage( image: AssetImage('images/search.png'), fit: BoxFit.cover, ), ), ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingRecipeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXXLarge, top: AppTheme.spacingMedium, bottom: AppTheme.spacingMedium, ),
          child: GestureDetector(
            onTap: () { Navigator.pushNamed(context, '/trending-resep'); },
            child: Text( 'Resep Trending >', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, ), ), ),
        ),
        SizedBox(
          height: 280, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXLarge),
            itemCount: _trendingRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _trendingRecipes[index];
              return TrendingRecipeCard(
                imagePath: recipe.image, // Food.image (sudah null-safe di model)
                title: recipe.name, // Food.name (sudah null-safe di model)
                description: recipe.description ?? 'Tidak ada deskripsi', 
                favorites: recipe.likes?.toString() ?? '0', 
                duration: recipe.cookingTime != null ? '${recipe.cookingTime}menit' : 'N/A', 
                price: recipe.price ?? 'Gratis', 
                detailRoute: '/detail-resep/${recipe.id}', // Pastikan ini sesuai dengan route detail resep Anda
              
                // Tambahkan onTap jika perlu
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
      ],
    );
  }

  Widget _buildYourRecipesSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration( color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium), ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXXLarge, top: AppTheme.spacingXLarge, bottom: AppTheme.spacingXLarge, ),
            child: GestureDetector(
              onTap: () { Navigator.pushNamed(context, '/resep-anda'); },
              child: Text( 'Resep Anda >', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, ), ), ),
          ),
          SizedBox(
            height: 250, 
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXLarge, ),
              itemCount: _userRecipes.length,
              itemBuilder: (context, index) {
                final recipe = _userRecipes[index];
                return FoodCard( 
                  food: recipe, 
                  onCardTap: () { 
                    Navigator.pushNamed(context, '/detail-resep', arguments: recipe.id);
                  },
                  onFavoritePressed: () {
                    print('Favorite pressed for ${recipe.name}');
                  },
                );
              },
            ),
          ),
          SizedBox(height: AppTheme.spacingXXLarge),
        ],
      ),
    );
  }

  Widget _buildTopUsersSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXXLarge, top: AppTheme.spacingXLarge, bottom: AppTheme.spacingXLarge, ),
          child: GestureDetector(
            onTap: () { Navigator.pushNamed(context, '/pengguna-terbaik'); },
            child: Text( 'Pengguna Terbaik >', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, ), ), ),
        ),
        SizedBox(
          height: 100, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXLarge, ),
            itemCount: _bestUsers.length,
            itemBuilder: (context, index) {
              final user = _bestUsers[index];
              return Padding(
                padding: const EdgeInsets.only(right: AppTheme.spacingXLarge),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: user.profilePicture != null && user.profilePicture!.isNotEmpty
                          ? NetworkImage(user.profilePicture!)
                          : const AssetImage('images/user_placeholder.png') as ImageProvider,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
      ],
    );
  }

  Widget _buildRecentlyAddedRecipeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only( left: AppTheme.spacingXLarge, right: AppTheme.spacingXXLarge, top: AppTheme.spacingXLarge, bottom: AppTheme.spacingXLarge, ),
          child: Text( 'Baru Saja Ditambahkan', style: TextStyle( fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, ), ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXLarge),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingMedium,
              mainAxisSpacing: AppTheme.spacingMedium,
              childAspectRatio: 0.75,
            ),
            itemCount: _latestRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _latestRecipes[index];
              return FoodCard( 
                food: recipe, 
                onCardTap: () {
                   Navigator.pushNamed(context, '/detail-resep/${recipe.id}'); // <<< PERBAIKAN DI SINI
                },
                onFavoritePressed: () {
                  print('Favorite pressed for ${recipe.name}');
                },
              );
            },
          ),
        ),
        const SizedBox(height: AppTheme.spacingXXLarge),
      ],
    );
  }
}