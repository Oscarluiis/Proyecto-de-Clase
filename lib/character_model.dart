class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String type;
  final String gender;
  final String image;
  final Location origin;
  final Location location;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.image,
    required this.origin,
    required this.location,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      species: json['species'],
      type: json['type'] ?? '',
      gender: json['gender'],
      image: json['image'],
      origin: Location.fromJson(json['origin']),
      location: Location.fromJson(json['location']),
    );
  }
}

class Location {
  final String name;
  final String url;

  Location({required this.name, required this.url});

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(name: json['name'], url: json['url']);
  }
}

class ApiResponse {
  final List<Character> results;
  final int count;
  final int pages;
  final String? next;
  final String? prev;

  ApiResponse({
    required this.results,
    required this.count,
    required this.pages,
    this.next,
    this.prev,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      results:
          (json['results'] as List)
              .map((character) => Character.fromJson(character))
              .toList(),
      count: json['info']['count'],
      pages: json['info']['pages'],
      next: json['info']['next'],
      prev: json['info']['prev'],
    );
  }
}
