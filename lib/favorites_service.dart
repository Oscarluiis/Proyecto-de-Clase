import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'character_model.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtener la referencia de la colección de favoritos del usuario actual
  static CollectionReference get _favoritesCollection {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(user.uid).collection('favorites');
  }

  // Agregar personaje a favoritos
  static Future<void> addToFavorites(Character character) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      await _favoritesCollection.doc(character.id.toString()).set({
        'id': character.id,
        'name': character.name,
        'status': character.status,
        'species': character.species,
        'type': character.type,
        'gender': character.gender,
        'image': character.image,
        'location': {
          'name': character.location.name,
          'url': character.location.url,
        },
        'origin': {'name': character.origin.name, 'url': character.origin.url},
        'addedToFavoritesAt': FieldValue.serverTimestamp(),
      });

      print('Personaje ${character.name} añadido a favoritos');
    } catch (e) {
      print('Error al añadir a favoritos: $e');
      throw Exception('Error al añadir a favoritos: $e');
    }
  }

  // Eliminar personaje de favoritos
  static Future<void> removeFromFavorites(int characterId) async {
    try {
      await _favoritesCollection.doc(characterId.toString()).delete();
      print('Personaje eliminado de favoritos');
    } catch (e) {
      print('Error al eliminar de favoritos: $e');
      throw Exception('Error al eliminar de favoritos: $e');
    }
  }

  // Verificar si un personaje está en favoritos
  static Future<bool> isFavorite(int characterId) async {
    try {
      final doc = await _favoritesCollection.doc(characterId.toString()).get();
      return doc.exists;
    } catch (e) {
      print('Error al verificar favorito: $e');
      return false;
    }
  }

  // Obtener todos los favoritos
  static Future<List<Character>> getFavorites() async {
    try {
      final querySnapshot =
          await _favoritesCollection
              .orderBy('addedToFavoritesAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Character.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error al obtener favoritos: $e');
      throw Exception('Error al obtener favoritos: $e');
    }
  }

  // Stream para escuchar cambios en favoritos en tiempo real
  static Stream<List<Character>> getFavoritesStream() {
    try {
      return _favoritesCollection
          .orderBy('addedToFavoritesAt', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Character.fromJson(data);
            }).toList();
          });
    } catch (e) {
      print('Error en el stream de favoritos: $e');
      return Stream.empty();
    }
  }

  // Alternar favorito (agregar si no está, eliminar si está)
  static Future<bool> toggleFavorite(Character character) async {
    try {
      final isFav = await isFavorite(character.id);
      if (isFav) {
        await removeFromFavorites(character.id);
        return false; // Ya no es favorito
      } else {
        await addToFavorites(character);
        return true; // Ahora es favorito
      }
    } catch (e) {
      print('Error al alternar favorito: $e');
      throw Exception('Error al alternar favorito: $e');
    }
  }
}
