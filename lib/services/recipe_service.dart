import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:simple_recipe_app/models/category_model.dart';
import 'package:simple_recipe_app/models/recipe_model.dart';

//untuk menyambungkan data api
class RecipeService {
  static final RecipeService _instance = RecipeService._internal();

  factory RecipeService() {
    return _instance;
  }

  RecipeService._internal();

  //konfigurasi dio untuk req
  Dio _dio() {
    final options = BaseOptions(
      baseUrl: 'https://tokopaedi.arfani.my.id/api',
      followRedirects: false,
    );
    var dio = Dio(options);
    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, requestHeader: true, maxWidth: 134),
    );
    return dio;
  }

  //endpoint api
  Dio get dio => _dio();
  final String baseUrl =
      "https://tokopaedi.arfani.my.id/api/recipes"; //data resep
  final String categoriesUrl =
      "https://tokopaedi.arfani.my.id/api/categories"; //data kategori

  //method get data list resep
  Future<List<RecipeModel>> getAllRecipes({int page = 1}) async { //jadi 1 tapi ada 3 parameter, yaitu resep, search  dan kategori
    try {
      final response = await dio.get("$baseUrl?page=$page");
      print("API Response: ${response.data}");
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey("data") &&
          response.data["data"] is Map<String, dynamic> &&
          response.data["data"].containsKey("data")) {
        List<dynamic> recipesJson = response.data["data"]["data"];
        return recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      } else {
        throw Exception("Invalid response format");
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      throw Exception("Failed to load recipes: $e");
    }
  }

  //method get data kategori
  Future<List<CategoryModel>> getAllCategories() async { 
    try {
      final response = await dio.get(categoriesUrl);
      if (response.data is List) {
        return (response.data as List)
            .map<CategoryModel>((json) => CategoryModel.fromJson(json))
            .toList();
      }
      throw Exception("Invalid categories response format");
    } catch (e) {
      print("Error fetching categories: $e");
      throw Exception("Failed to load categories: $e");
    }
  }

  //method cari resep di searchbar berdasarkan parameter
  Future<List<RecipeModel>> searchRecipes(String query) async { //jadi 1
    try {
      final response = await dio.get(
        "$baseUrl",
        queryParameters: {
          'search': query}, //parameter
        options: Options(headers: {'Accept': 'application/json'}),
      );
      print("API Search Response: ${response.data}");
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey("data") &&
          response.data["data"] is Map<String, dynamic> &&
          response.data["data"].containsKey("data")) {
        List<dynamic> recipesJson = response.data["data"]["data"];
        return recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      } else if (response.data is Map<String, dynamic> &&
          response.data.containsKey("data") &&
          response.data["data"] is List) {
        List<dynamic> recipesJson = response.data["data"];
        return recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      } else {
        print("Format respons tidak dikenali: ${response.data}");
        throw Exception("Invalid search response format");
      }
    } catch (e) {
      print("Error searching recipes: $e");
      throw Exception("Failed to search recipes: $e");
    }
  }

  //method get data resep berdasarkan kategori
  Future<List<RecipeModel>> getRecipesByCategory(int categoryId) async { //jadi 1
    try {
      final response = await dio.get(
        "$baseUrl",
        queryParameters: {'category_id': categoryId}, //parameter
        options: Options(headers: {'Accept': 'application/json'}),
      );
      print("API Category Filter Response: ${response.data}");
      if (response.data is Map<String, dynamic> &&
          response.data.containsKey("data") &&
          response.data["data"] is Map<String, dynamic> &&
          response.data["data"].containsKey("data")) {
        List<dynamic> recipesJson = response.data["data"]["data"];
        return recipesJson.map((json) => RecipeModel.fromJson(json)).toList();
      } else {
        throw Exception("Invalid category filter response format");
      }
    } catch (e) {
      print("Error filtering recipes by category: $e");
      throw Exception("Failed to filter recipes by category: $e");
    }
  }

  //method buat resep
  Future<String?> createRecipe(RecipeModel recipe) async {
    try {
      final formData = FormData.fromMap({
        'title': recipe.title,
        'description': recipe.description,
        'category_id': recipe.categoryId.toString(),
        if (recipe.image.isNotEmpty)
          'image': await MultipartFile.fromFile(
            recipe.image,
            filename: 'image.jpg',
          ),
      });

      final response = await dio.post(
        '$baseUrl',
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']['image'];
      } else {
        throw Exception('Failed to save recipe: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving recipe: $e');
      return null;
    }
  }

  //method ubah resep
  Future<String?> updateRecipe(RecipeModel recipe) async {
    try {
      final formData = FormData.fromMap({
        'title': recipe.title,
        'description': recipe.description,
        'category_id': recipe.categoryId.toString(),
        if (recipe.image.isNotEmpty && recipe.image.startsWith('/'))
          'image': await MultipartFile.fromFile(
            recipe.image,
            filename: 'image.jpg',
          ),
      });

      final response = await dio.post(
        '$baseUrl/${recipe.id}/update', //endpoint
        data: formData,
        options: Options(headers: {'Accept': 'application/json'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['data']['image'];
      } else {
        throw Exception('Failed to update recipe: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating recipe: $e');
      return null;
    }
  }

  //method hapus resep
  Future<bool> deleteRecipe(int id) async {
    try {
      final response = await dio.delete("$baseUrl/$id");
      return response.statusCode == 200;
    } catch (e) {
      print("Error deleting recipe: $e");
      throw Exception("Failed to delete recipe: $e");
    }
  }
}
