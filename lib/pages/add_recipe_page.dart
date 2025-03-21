import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:simple_recipe_app/models/category_model.dart';
import 'package:simple_recipe_app/models/recipe_model.dart';
import 'package:simple_recipe_app/services/recipe_service.dart';

class AddRecipePage extends StatefulWidget {
  final RecipeModel? recipe; 
  const AddRecipePage({Key? key, this.recipe}) : super(key: key);

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final RecipeService _recipeService = RecipeService();

  //implementasi flutter quill di deskripsi
  late QuillController _descriptionController;

  CategoryModel? _selectedCategory;
  List<CategoryModel> _categories = [];
  bool _isLoading = false; //status
  bool _isSaving = false; //status
  bool _isEditMode = false; //status

  //image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _descriptionController = QuillController.basic();

    //mode edit
    if (widget.recipe != null) {
      _isEditMode = true;
      _titleController.text = widget.recipe!.title;
      _imageUrl = widget.recipe!.image;

      final document = Document()..insert(0, widget.recipe!.description);
      _descriptionController = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final fetchedCategories = await _recipeService.getAllCategories();

      if (!mounted) return;
      setState(() {
        _categories = fetchedCategories;
        if (_isEditMode && widget.recipe != null) {
          _selectedCategory = _categories.firstWhere(
            (category) => category.id == widget.recipe!.categoryId,
            orElse:
                () =>
                    _categories.isNotEmpty
                        ? _categories.first
                        : CategoryModel(
                          id: 1,
                          name: "Default Category",
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
          );
        } else if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }

        _isLoading = false;
      });
    } catch (e) {
      print("Error loading categories: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _categories = [
            CategoryModel(
              id: 1,
              name: "Default Category",
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ];
          _selectedCategory = _categories.first;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories. Using default category.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to access gallery: $e')));
    }
  }

  Future<void> _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });
      try {
        final recipe = RecipeModel(
          id: _isEditMode ? widget.recipe!.id : 0,
          title: _titleController.text,
          description: _descriptionController.document.toPlainText().trim(),
          image: _imageFile?.path ?? _imageUrl ?? '',
          categoryId: _selectedCategory!.id,
          createdAt: _isEditMode ? widget.recipe!.createdAt : DateTime.now(),
          updatedAt: DateTime.now(),
          category: _selectedCategory!,
        );
        String? result;
        if (_isEditMode) {
          result = await _recipeService.updateRecipe(recipe);
        } else {
          result = await _recipeService.createRecipe(recipe);
        }

        if (result != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Resep berhasil tersimpan')));

          // Navigate back
          Navigator.pop(context);
        } else {
          throw Exception("Gagal menyimpan resep");
        }
      } catch (e) {
        print("Error saving recipe: $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving recipe: $e')));
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Resep' : 'Tambah Resep'),
        backgroundColor: Colors.blueGrey,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: GestureDetector(
        //untuk ngeclose keyboard
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child:
            _isLoading || _isSaving
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blueGrey),
                      SizedBox(height: 16),
                      Text(_isSaving ? 'Uploading image...' : 'Loading...'),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  physics: ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child:
                              _imageFile != null || _imageUrl != null
                                  ? ClipRect(
                                    child:
                                        _imageFile != null
                                            ? Image.file(
                                              _imageFile!,
                                              fit: BoxFit.cover,
                                              height: 200,
                                              width: double.infinity,
                                            )
                                            : Image.network(
                                              _imageUrl!,
                                              fit: BoxFit.cover,
                                              height: 200,
                                              width: double.infinity,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                    color: Colors.blueGrey,
                                                  ),
                                                );
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.error_outline,
                                                    color: Colors.red,
                                                    size: 40,
                                                  ),
                                                );
                                              },
                                            ),
                                  )
                                  : Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_outlined,
                                          size: 64,
                                          color: Colors.blueGrey,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Tambah gambar resep',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                        ),
                      ),

                      //form tambah resep
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Resep',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Ketik nama resep...',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.blueGrey,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                style: TextStyle(fontSize: 16),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Isi nama resep';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Kategori',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              _categories.isEmpty
                                  ? Text(
                                    "Tidak ada kategori tersedia",
                                    style: TextStyle(color: Colors.red),
                                  )
                                  : DropdownButtonFormField<CategoryModel>(
                                    decoration: InputDecoration(
                                      hintText: 'Pilih Kategori',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.blueGrey,
                                          width: 2,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    value: _selectedCategory,
                                    items:
                                        _categories.map((category) {
                                          return DropdownMenuItem<
                                            CategoryModel
                                          >(
                                            value: category,
                                            child: Text(category.name),
                                          );
                                        }).toList(),
                                    onChanged: (CategoryModel? newValue) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Pilih kategori';
                                      }
                                      return null;
                                    },
                                  ),
                              SizedBox(height: 16),
                              Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    // Toolbar for formatting
                                    QuillSimpleToolbar(
                                      controller: _descriptionController,
                                      config: const QuillSimpleToolbarConfig(
                                        showBoldButton: true,
                                        showItalicButton: true,
                                        showUnderLineButton: true,
                                        showStrikeThrough: false,
                                        showColorButton: false,
                                        showBackgroundColorButton: false,
                                        showClearFormat: true,
                                        showAlignmentButtons: false,
                                        showLeftAlignment: false,
                                        showCenterAlignment: false,
                                        showRightAlignment: false,
                                        showJustifyAlignment: false,
                                        showHeaderStyle: false,
                                        showListNumbers: true,
                                        showListBullets: true,
                                        showListCheck: false,
                                        showCodeBlock: false,
                                        showQuote: false,
                                        showIndent: false,
                                        showLink: false,
                                        showUndo: true,
                                        showRedo: true,
                                        showDirection: false,
                                        showSearchButton: false,
                                        showSubscript: false,
                                        showSuperscript: false,
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        child: QuillEditor.basic(
                                          controller: _descriptionController,
                                          config: const QuillEditorConfig(
                                            placeholder:
                                                'Tulis deskripsi resep Anda di sini...',
                                            padding: EdgeInsets.all(8),
                                            scrollable: true,
                                            autoFocus: false,
                                            expands: false,
                                            // readOnly: false,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _saveRecipe,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Text(
                                    _isEditMode ? 'Ubah Resep' : 'Simpan Resep',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
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
}
