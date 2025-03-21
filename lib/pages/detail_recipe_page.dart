import 'package:flutter/material.dart';
import 'package:simple_recipe_app/models/recipe_model.dart';
import 'package:simple_recipe_app/pages/add_recipe_page.dart';
import 'package:simple_recipe_app/services/recipe_service.dart';

class DetailRecipePage extends StatefulWidget {
  final RecipeModel recipe;
  const DetailRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  State<DetailRecipePage> createState() => _DetailRecipePageState();
}

class _DetailRecipePageState extends State<DetailRecipePage> {
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Detail Resep'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            color: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddRecipePage(recipe: widget.recipe),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.white,
            onPressed: () {
              _showDeleteConfirmation();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.network(
                      //gambar resep
                      widget.recipe.image,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(Icons.image_not_supported, size: 50),
                          ),
                        );
                      },
                    ),

                    //tampilan detail resep
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.recipe.title, //ambil data title
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                widget
                                    .recipe
                                    .category
                                    .name, //ambil data kategori
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Divider(thickness: 1),
                          SizedBox(height: 16),
                          Text(
                            'Deskripsi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.recipe.description, //ambil data deskripsi
                            style: TextStyle(fontSize: 16, height: 1.5),
                          ),
                          SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Added: ${_formatDate(widget.recipe.createdAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.update, size: 16, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Updated: ${_formatDate(widget.recipe.updatedAt)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  //untuk pop up konfirmasi hapus
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Recipe'),
          content: Text('Are you sure you want to delete this recipe?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); //close pop up konfirmasi
                _deleteRecipe();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  //untuk hapus resep
  void _deleteRecipe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _recipeService.deleteRecipe(widget.recipe.id);

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recipe deleted successfully')));
        // Return to previous screen
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete recipe')));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }
}
