import 'dart:convert';
import 'package:http/http.dart' as http;
import 'character_model.dart';

class RickMortyService {
  static const String baseUrl = 'https://rickandmortyapi.com/api';

  // Obtener personajes con filtros
  static Future<ApiResponse> getCharacters({
    int page = 1,
    String? status,
    String? species,
    String? gender,
    String? name,
  }) async {
    try {
      String url = '$baseUrl/character?page=$page';

      if (status != null && status.isNotEmpty) {
        url += '&status=$status';
      }
      if (species != null && species.isNotEmpty) {
        url += '&species=$species';
      }
      if (gender != null && gender.isNotEmpty) {
        url += '&gender=$gender';
      }
      if (name != null && name.isNotEmpty) {
        url += '&name=$name';
      }

      print('API URL: $url'); // Para debug

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse.fromJson(jsonData);
      } else {
        throw Exception('Error al cargar personajes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Métodos específicos para cada categoría
  static Future<ApiResponse> getAllCharacters({int page = 1}) async {
    return getCharacters(page: page);
  }

  static Future<ApiResponse> getHumans({int page = 1}) async {
    return getCharacters(page: page, species: 'Human');
  }

  static Future<ApiResponse> getAliens({int page = 1}) async {
    // Para aliens, necesitamos obtener todos y filtrar los que NO son humanos
    // La API no soporta species!=Human, así que usaremos especies específicas
    return getCharacters(page: page, species: 'Alien');
  }

  static Future<ApiResponse> getAliveCharacters({int page = 1}) async {
    return getCharacters(page: page, status: 'Alive');
  }

  static Future<ApiResponse> getDeadCharacters({int page = 1}) async {
    return getCharacters(page: page, status: 'Dead');
  }

  static Future<ApiResponse> getUnknownCharacters({int page = 1}) async {
    return getCharacters(page: page, status: 'unknown');
  }

  static Future<ApiResponse> getMaleCharacters({int page = 1}) async {
    return getCharacters(page: page, gender: 'Male');
  }

  static Future<ApiResponse> getFemaleCharacters({int page = 1}) async {
    return getCharacters(page: page, gender: 'Female');
  }

  // Buscar personajes por nombre
  static Future<ApiResponse> searchCharacters(
    String name, {
    int page = 1,
  }) async {
    return getCharacters(page: page, name: name);
  }
}
