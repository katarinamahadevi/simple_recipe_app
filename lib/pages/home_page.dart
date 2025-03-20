import 'package:flutter/material.dart';
import 'package:simple_recipe_app/models/category_model.dart';
import 'package:simple_recipe_app/models/recipe_model.dart' show RecipeModel;
import 'package:simple_recipe_app/pages/add_recipe_page.dart';
import 'package:simple_recipe_app/pages/detail_recipe_page.dart';
import 'package:simple_recipe_app/services/recipe_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool showFilterOptions = false; //filter kategori
  TextEditingController searchController =
      TextEditingController(); //controller searchbar

  final RecipeService _recipeService = RecipeService();
  List<RecipeModel> _recipes = []; //daftar resep yang ditampilin
  List<CategoryModel> _categories = []; //daftar kategori
  bool _isLoading = false;

  // Filter and search states
  String _searchQuery = ''; //menyimpan teks pencarian yang sedang dicari
  CategoryModel? _selectedCategory; //menyimpan kategori yang dipilih

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _fetchCategories();
    await _fetchRecipes();
  }

  //mengambil daftar resep
  Future<void> _fetchRecipes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedRecipes =
          await _recipeService
              .getAllRecipes(); //memanggil untuk ngambil data resep
      setState(() {
        _recipes = fetchedRecipes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _recipes = [];
        _isLoading = false;
      });
      _showErrorSnackBar("Error loading recipes");
    }
  }

  //mengambil daftar kategori
  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories =
          await _recipeService
              .getAllCategories(); //memanggil untuk ngambil data kategori
      setState(() {
        _categories = fetchedCategories;
      });
    } catch (e) {
      _showErrorSnackBar("Error loading categories");
    }
  }

  //buat searchbar
  Future<void> _searchRecipes(String query) async {
    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      // If query is empty, reset to original state
      if (query.isEmpty) {
        if (_selectedCategory != null) {
          await _getRecipesByCategory(_selectedCategory!);
        } else {
          await _fetchRecipes();
        }
        return;
      }

      // Fetch all recipes first
      final allRecipes = await _recipeService.getAllRecipes();

      // Filter recipes based on title (case-insensitive)
      final searchedRecipes =
          allRecipes
              .where(
                (recipe) =>
                    recipe.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      // If a category is selected, further filter by category
      if (_selectedCategory != null) {
        setState(() {
          _recipes =
              searchedRecipes
                  .where((recipe) => recipe.categoryId == _selectedCategory!.id)
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _recipes = searchedRecipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Error searching recipes");
    }
  }

  //ngambil data resep berdasarkan kategori
  Future<void> _getRecipesByCategory(CategoryModel category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      final categoryRecipes = await _recipeService.getRecipesByCategory(
        category.id,
      );

      // Apply search filter if there's a query
      if (_searchQuery.isNotEmpty) {
        setState(() {
          _recipes =
              categoryRecipes
                  .where(
                    (recipe) => recipe.title.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _recipes = categoryRecipes;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar("Error filtering recipes by category");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        automaticallyImplyLeading: false,
        title: Text("Aplikasi Resep", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      if (value.length > 0 || value.isEmpty) {
                        _searchRecipes(value);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: "Cari...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.filter_list, color: Colors.blueGrey),
                  onPressed: () {
                    setState(() {
                      showFilterOptions = !showFilterOptions;
                    });
                  },
                ),
              ],
            ),
          ),

          //filter kategori
          if (showFilterOptions)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "Filter berdasarkan kategori:",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        // "All" filter chip
                        FilterChip(
                          label: const Text("Semua"),
                          selected: _selectedCategory == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = null;
                              });
                              _searchRecipes(_searchQuery);
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.blueGrey,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color:
                                _selectedCategory == null
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ),

                        //opsi kategori
                        ..._categories.map((category) {
                          final isSelected =
                              _selectedCategory?.id == category.id;
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _getRecipesByCategory(category);
                              } else {
                                setState(() {
                                  _selectedCategory = null;
                                });
                                _searchRecipes(_searchQuery);
                              }
                            },
                            backgroundColor: Colors.grey.shade200,
                            selectedColor: Colors.blueGrey,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Recipe List
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _recipes.isEmpty
                    ? Center(
                      child: Text(
                        _selectedCategory != null && _searchQuery.isNotEmpty
                            ? "Tidak ada hasil untuk '$_searchQuery' dalam kategori '${_selectedCategory!.name}'"
                            : _selectedCategory != null
                            ? "Tidak ada resep dalam kategori '${_selectedCategory!.name}'"
                            : _searchQuery.isNotEmpty
                            ? "Tidak ada hasil untuk '$_searchQuery'"
                            : "Tidak ada resep yang tersedia",
                      ),
                    )
                    : ListView.builder(
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          DetailRecipePage(recipe: recipe),
                                ),
                              ).then((_) {
                                if (_selectedCategory != null) {
                                  _getRecipesByCategory(_selectedCategory!);
                                } else if (_searchQuery.isNotEmpty) {
                                  _searchRecipes(_searchQuery);
                                } else {
                                  _fetchRecipes();
                                }
                              });
                            },
                            leading: SizedBox(
                              width: 50,
                              height: 50,
                              child: Image.network(
                                recipe.image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade300,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Text(
                              recipe.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.description,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    recipe.category.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddRecipePage()),
          ).then((_) {
            if (_selectedCategory != null) {
              _getRecipesByCategory(_selectedCategory!);
            } else if (_searchQuery.isNotEmpty) {
              _searchRecipes(_searchQuery);
            } else {
              _fetchRecipes();
            }
          });
        },
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("Tambah Resep"),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }
}
