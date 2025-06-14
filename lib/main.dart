import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'login_page.dart';
import 'auth_wrapper.dart';
import 'rick_morty_service.dart';
import 'character_model.dart';
import 'character_card.dart';
import 'category_model.dart';
import 'category_chip.dart';
import 'character_detail_popup.dart';
import 'favorites_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agenda Personal',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;
  double _scale = 1.0;
  final AuthService _authService = AuthService();

  // Variables para la API de Rick and Morty
  List<Character> characters = [];
  bool isLoading = false;
  String errorMessage = '';
  int currentPage = 1;
  bool hasMorePages = true;

  // Variables para categorías
  String selectedCategoryId = 'all';
  CharacterCategory get selectedCategory =>
      CategoryData.getCategoryById(selectedCategoryId);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    // Cargar personajes al iniciar
    _loadCharacters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método para cargar personajes desde la API según la categoría
  Future<void> _loadCharacters({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      if (!loadMore) {
        characters.clear();
        currentPage = 1;
        hasMorePages = true;
      }
      errorMessage = '';
    });

    try {
      // Si es la categoría de favoritos, usar el servicio de favoritos
      if (selectedCategory.isFavorites) {
        final favoriteCharacters = await FavoritesService.getFavorites();
        setState(() {
          characters = favoriteCharacters;
          hasMorePages = false; // Los favoritos no tienen paginación
          isLoading = false;
        });
      } else if (selectedCategory.apiCall != null) {
        // Usar la API normal para otras categorías (verificamos que no sea null)
        final response = await selectedCategory.apiCall!(page: currentPage);

        // Verificar que response no sea null
        if (response != null && response.results != null) {
          setState(() {
            if (loadMore) {
              characters.addAll(response.results);
            } else {
              characters = response.results;
            }
            hasMorePages = response.next != null;
            if (loadMore) currentPage++;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'No se recibieron datos del servidor';
          });
        }
      } else {
        // Si no hay apiCall ni es favoritos, mostrar error
        setState(() {
          isLoading = false;
          errorMessage = 'No se puede cargar esta categoría';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  // Método para cambiar de categoría
  void _selectCategory(String categoryId) {
    if (selectedCategoryId != categoryId) {
      setState(() {
        selectedCategoryId = categoryId;
      });
      _loadCharacters();
    }
  }

  // Método para buscar personajes
  Future<void> _searchCharacters(String query) async {
    if (query.isEmpty) {
      _loadCharacters();
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await RickMortyService.searchCharacters(query);

      // Verificar que response y results no sean null
      if (response != null && response.results != null) {
        setState(() {
          characters = response.results;
          isLoading = false;
          hasMorePages = false; // No paginación en búsqueda
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'No se encontraron resultados';
          characters = [];
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        characters = [];
      });
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = Colors.blue,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.displayName?.split(' ')[0] ?? 'Usuario'}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Inicio'),
            Tab(icon: Icon(Icons.tv), text: 'Rick & Morty'),
            Tab(icon: Icon(Icons.settings), text: 'Ajustes'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              _showSnackBar(context, 'Notificaciones presionadas');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              accountName: Text(user?.displayName ?? 'Usuario'),
              accountEmail: Text(user?.email ?? 'email@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundImage:
                    user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                child:
                    user?.photoURL == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {
                _tabController.animateTo(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tv),
              title: const Text('Rick & Morty'),
              onTap: () {
                _tabController.animateTo(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ajustes'),
              onTap: () {
                _tabController.animateTo(2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                await _authService.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Primer tab - Inicio con información del usuario
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user?.photoURL != null)
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user!.photoURL!),
                  ),
                const SizedBox(height: 20),
                Text(
                  '¡Bienvenido, ${user?.displayName ?? 'Usuario'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  user?.email ?? 'email@example.com',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    _showSnackBar(context, 'Contenedor presionado');
                  },
                  onDoubleTap: () {
                    setState(() {
                      _scale = _scale == 1.0 ? 1.5 : 1.0;
                    });
                    _showSnackBar(
                      context,
                      'Contenedor escalado: ${_scale == 1.5 ? 'Ampliado' : 'Normal'}',
                      backgroundColor: Colors.green,
                    );
                  },
                  child: AnimatedScale(
                    scale: _scale,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.teal[200],
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.touch_app,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Segundo tab - Rick & Morty API con categorías
          Column(
            children: [
              // Barra de búsqueda
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar personajes...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _loadCharacters(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  onSubmitted: _searchCharacters,
                ),
              ),

              // Chips de categorías
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: CategoryData.categories.length,
                  itemBuilder: (context, index) {
                    final category = CategoryData.categories[index];
                    return CategoryChip(
                      category: category,
                      isSelected: selectedCategoryId == category.id,
                      onTap: () => _selectCategory(category.id),
                    );
                  },
                ),
              ),

              // Header de categoría seleccionada
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: selectedCategory.color.withOpacity(0.1),
                  border: Border(
                    bottom: BorderSide(
                      color: selectedCategory.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedCategory.icon,
                      color: selectedCategory.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedCategory.description,
                      style: TextStyle(
                        color: selectedCategory.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (!isLoading && characters.isNotEmpty)
                      Text(
                        '${characters.length} personajes',
                        style: TextStyle(
                          color: selectedCategory.color.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),

              // Lista de personajes
              Expanded(child: _buildCharactersList()),
            ],
          ),

          // Tercer tab - Ajustes
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Pantalla de Ajustes',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _showSnackBar(
                      context,
                      'Ajustes guardados',
                      backgroundColor: Colors.green,
                    );
                  },
                  child: const Text('Guardar ajustes'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _currentIndex == 1
              ? FloatingActionButton(
                onPressed: () {
                  if (hasMorePages && !isLoading) {
                    currentPage++;
                    _loadCharacters(loadMore: true);
                  } else {
                    _showSnackBar(
                      context,
                      hasMorePages ? 'Cargando...' : 'No hay más personajes',
                      backgroundColor:
                          hasMorePages ? Colors.blue : Colors.orange,
                    );
                  }
                },
                backgroundColor: selectedCategory.color,
                child:
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.add),
                tooltip: 'Cargar más personajes',
              )
              : FloatingActionButton(
                onPressed: () {
                  _showSnackBar(
                    context,
                    'FloatingActionButton presionado en Tab: ${_tabController.index + 1}',
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Agregar',
              ),
    );
  }

  Widget _buildCharactersList() {
    if (isLoading && characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: selectedCategory.color),
            const SizedBox(height: 16),
            Text(
              'Cargando ${selectedCategory.name.toLowerCase()}...',
              style: TextStyle(color: selectedCategory.color),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty && characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Error al cargar ${selectedCategory.name.toLowerCase()}',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadCharacters(),
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCategory.color,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selectedCategory.icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No se encontraron ${selectedCategory.name.toLowerCase()}',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCharacters(),
      color: selectedCategory.color,
      child: ListView.builder(
        itemCount: characters.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == characters.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: selectedCategory.color),
              ),
            );
          }

          final character = characters[index];
          return CharacterCard(
            character: character,
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return CharacterDetailPopup(character: character);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Widget personalizado (CustomCard)
class CustomCard extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onPressed;
  final bool useIcon;
  final IconData icon;
  final Color iconColor;

  const CustomCard({
    Key? key,
    required this.title,
    required this.description,
    required this.onPressed,
    this.useIcon = false,
    this.icon = Icons.star,
    this.iconColor = Colors.amber,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: InkWell(
        onTap: onPressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useIcon)
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10.0),
                  ),
                ),
                child: Icon(icon, size: 60, color: iconColor),
                alignment: Alignment.center,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
