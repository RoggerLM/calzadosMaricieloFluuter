// pages/add_product_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:calzados_luciana/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../services/api_service.dart';



class AddProductPage extends StatefulWidget {
  final Function() onProductAdded;

  const AddProductPage({super.key, required this.onProductAdded});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  XFile? _selectedImage;

  // Controladores para los campos de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String _selectedCategory = '';
  // Variables para el estado
  //bool _isNew = false;
  bool _addHalfDozen = false;
  bool _isLoadingCategories = true;
  List<String> _categories = [];
  final Map<String, int> _sizes = {
    '35': 0,
    '36': 0,
    '37': 0,
    '38': 0,
    '39': 0,
    '40': 0,
  };

  @override
  void initState(){
    super.initState();
    _loadDefaultCategorias();
  }

  Future<void> _loadDefaultCategorias() async{
    try {
      //final apiService = ApiService();
      final categories = await ApiService.getCategories();

      print(categories);

      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar categorías: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Producto'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProduct,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de imagen
              _buildImageSection(),
              const SizedBox(height: 20),


              // Código del producto
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Código del Producto',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.code),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el código del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Color
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el color';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Precio
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingresa un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              _isLoadingCategories
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                value: _selectedCategory.isNotEmpty ? _selectedCategory : null,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor selecciona una categoría';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Título de tallas
              const Text(
                'Stock por Tallas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Checkbox para media docena
              CheckboxListTile(
                title: const Text('Agregar media docena'),
                value: _addHalfDozen,
                onChanged: (value) {
                  setState(() {
                    _addHalfDozen = value!;
                    if (_addHalfDozen) {
                      // Agregar  unidades a todas las tallas
                      _sizes.updateAll((size, value) => value + (size == "37" ? 2 : 1));

                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Grid de tallas
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1.8,
                ),
                itemCount: _sizes.length,
                itemBuilder: (context, index) {
                  final size = _sizes.keys.elementAt(index);
                  final stock = _sizes[size]!;

                  return _buildSizeCard(size, stock);
                },
              ),
              const SizedBox(height: 30),

              // Botón de agregar producto
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveProduct,
                  child: const Text(
                    'Agregar Producto',
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
    );
  }

  Widget _buildImageSection() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: _selectedImage != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedImage!.path),
                    fit: BoxFit.cover,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 65,
                      color: Colors.grey.shade400,
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Imagen del\nProducto',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
          ),
        ),

        const SizedBox(height: 16),

        // Botones separados para Cámara y Galería
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón para Cámara
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Cámara'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
             ),
            ),
            // Botón para Galería
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Galería'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeCard(String size, int stock) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(2),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Talla $size',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        if (stock > 0) _sizes[size] = stock - 1;
                      });
                    },
                  ),

                ),
                Text(
                  '$stock',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        _sizes[size] = stock + 1;
                      });
                    },
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Método para abrir la cámara
  Future<void> _pickImageFromCamera() async {
    // Solicitar permiso primero
    final hasPermission = await _requestCameraPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso para usar la cámara'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir cámara: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _requestGalleryPermission() async {
    try {
      print('=== SOLICITANDO PERMISOS GALERÍA ===');

      // Obtener información del dispositivo
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      print('📱 Versión Android SDK: $sdkInt');

      Permission permission;

      // Determinar qué permiso usar basado en la versión de Android
      if (sdkInt >= 33) {
        // Android 13+ (API 33+) - usar READ_MEDIA_IMAGES
        permission = Permission.photos;
        print('📱 Android 13+ detectado, usando Permission.photos');
      } else {
        // Android 12 o inferior - usar READ_EXTERNAL_STORAGE
        permission = Permission.storage;
        print('📱 Android 12 o inferior, usando Permission.storage');
      }

      // Verificar estado actual
      PermissionStatus status = await permission.status;
      print('Estado del permiso: $status');

      if (status.isGranted) {
        print('✅ Permiso ya concedido');
        return true;
      }

      if (status.isDenied) {
        print('🔄 Solicitando permiso...');
        status = await permission.request();
        print('📝 Resultado después de solicitar: $status');

        if (status.isGranted) {
          print('✅ Permiso concedido después de solicitud');
          return true;
        }
      }

      if (status.isPermanentlyDenied) {
        print('🔒 Permiso denegado permanentemente');
        if (mounted) {
          await _showPermissionSettingsDialog('galería');
        }
      }

      return status.isGranted;
    } catch (e) {
      print('❌ Error en permisos de galería: $e');
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      // Primero verificar si ya tenemos permiso
      if (await Permission.camera.isGranted) {
        return true;
      }

      // Solicitar permiso
      PermissionStatus status = await Permission.camera.request();

      if (status.isPermanentlyDenied && mounted) {
        await _showPermissionSettingsDialog('cámara');
      }

      return status.isGranted;
    } catch (e) {
      print('Error al solicitar permisos de cámara: $e');
      return false;
    }
  }

  Future<void> _showPermissionSettingsDialog(String feature) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: Text(
          'Para usar la $feature necesitas conceder permiso manualmente en la configuración de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }
  // Método para abrir la galería
  Future<void> _pickImageFromGallery() async {
    // Solicitar permiso primero
    final hasPermission = await _requestGalleryPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso para acceder a la galería'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir galería: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  /*
  Future<void> _saveProduct() async {

    if (_formKey.currentState!.validate()) {
      try {

        //final firestoreService = Provider.of<FirestoreService>(context,listen: false);

        String? imagenBase64;

        // Convertir imagen a Base64 si existe
        if (_selectedImage != null) {
          final file = File(_selectedImage!.path);
          final bytes = await file.readAsBytes();
          imagenBase64 = base64Encode(bytes);
          print('✅ Imagen convertida a Base64 (${imagenBase64.length} caracteres)');
        }

        final productData = {
          'codigo': _codeController.text,
          'color': _colorController.text,
          'precio': double.parse(_priceController.text),
          'categoria': _selectedCategory,
          'imagen':  imagenBase64, // ← String con la URL
          'tallas': _sizes,
        };
        // Guardar en Firebase
        await firestoreService.addProduct(productData);

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        // Llamar callback y regresar
        widget.onProductAdded();
        Navigator.pop(context);
      }
      catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 */
  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final apiService = ApiService();

        String? imagenBase64;
        if (_selectedImage != null) {
          final file = File(_selectedImage!.path);
          final bytes = await file.readAsBytes();
          imagenBase64 = base64Encode(bytes);
        }

        final productData = {
          'codigo': _codeController.text,
          'color': _colorController.text,
          'precio': double.parse(_priceController.text),
          'categoria': _selectedCategory,
          //'nuevo': _isNew,
          'imagen': imagenBase64,
          'tallas': _sizes,
        };

        await apiService.createProduct(productData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto agregado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          widget.onProductAdded();
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar producto: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _colorController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}