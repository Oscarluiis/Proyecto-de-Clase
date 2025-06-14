import 'package:flutter/material.dart';
import 'rick_morty_service.dart';
import 'character_model.dart';

class CharacterCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Future<ApiResponse> Function({int page}) apiCall;

  const CharacterCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.apiCall,
  });
}

class CategoryData {
  static const List<CharacterCategory> categories = [
    CharacterCategory(
      id: 'all',
      name: 'Todos',
      description: 'Todos los personajes',
      icon: Icons.groups,
      color: Colors.blue,
      apiCall: RickMortyService.getAllCharacters,
    ),
    CharacterCategory(
      id: 'alive',
      name: 'Vivos',
      description: 'Personajes vivos',
      icon: Icons.favorite,
      color: Colors.green,
      apiCall: RickMortyService.getAliveCharacters,
    ),
    CharacterCategory(
      id: 'dead',
      name: 'Muertos',
      description: 'Personajes muertos',
      icon: Icons.heart_broken,
      color: Colors.red,
      apiCall: RickMortyService.getDeadCharacters,
    ),
    CharacterCategory(
      id: 'unknown',
      name: 'Desconocidos',
      description: 'Estado desconocido',
      icon: Icons.help,
      color: Colors.orange,
      apiCall: RickMortyService.getUnknownCharacters,
    ),
    CharacterCategory(
      id: 'human',
      name: 'Humanos',
      description: 'Personajes humanos',
      icon: Icons.person,
      color: Colors.purple,
      apiCall: RickMortyService.getHumans,
    ),
    CharacterCategory(
      id: 'male',
      name: 'Masculinos',
      description: 'Personajes masculinos',
      icon: Icons.male,
      color: Colors.indigo,
      apiCall: RickMortyService.getMaleCharacters,
    ),
    CharacterCategory(
      id: 'female',
      name: 'Femeninos',
      description: 'Personajes femeninos',
      icon: Icons.female,
      color: Colors.pink,
      apiCall: RickMortyService.getFemaleCharacters,
    ),
  ];

  static CharacterCategory getCategoryById(String id) {
    return categories.firstWhere((category) => category.id == id);
  }
}
