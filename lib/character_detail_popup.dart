import 'package:flutter/material.dart';
import 'character_model.dart';
import 'favorites_service.dart';

class CharacterDetailPopup extends StatefulWidget {
  final Character character;

  const CharacterDetailPopup({Key? key, required this.character})
    : super(key: key);

  @override
  State<CharacterDetailPopup> createState() => _CharacterDetailPopupState();
}

class _CharacterDetailPopupState extends State<CharacterDetailPopup> {
  bool isFavorite = false;
  bool isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final favorite = await FavoritesService.isFavorite(widget.character.id);
      if (mounted) {
        setState(() {
          isFavorite = favorite;
        });
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (isLoadingFavorite) return;

    setState(() {
      isLoadingFavorite = true;
    });

    try {
      final newFavoriteStatus = await FavoritesService.toggleFavorite(
        widget.character,
      );

      if (mounted) {
        setState(() {
          isFavorite = newFavoriteStatus;
          isLoadingFavorite = false;
        });

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFavoriteStatus
                  ? '${widget.character.name} añadido a favoritos ❤️'
                  : '${widget.character.name} eliminado de favoritos 💔',
            ),
            backgroundColor: newFavoriteStatus ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingFavorite = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.character.status.toLowerCase()) {
      case 'alive':
        return Colors.green;
      case 'dead':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getGenderIcon() {
    switch (widget.character.gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      case 'genderless':
        return Icons.circle;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header con imagen y nombre
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _getStatusColor().withOpacity(0.8),
                    _getStatusColor().withOpacity(0.6),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Botón de cerrar
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Botón de favorito
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: _toggleFavorite,
                      icon:
                          isLoadingFavorite
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: Colors.white,
                              ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.3),
                      ),
                    ),
                  ),
                  // Contenido del header
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Imagen del personaje
                        Hero(
                          tag: 'character_${widget.character.id}',
                          child: ClipOval(
                            child: Image.network(
                              widget.character.image,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: const BoxDecoration(
                                    color: Colors.white30,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Nombre del personaje
                        Text(
                          widget.character.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        // Estado con indicador
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getStatusColor(),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.character.status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
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

            // Contenido del cuerpo
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildSectionTitle('Información Básica'),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.person,
                      'Especie',
                      widget.character.species,
                    ),
                    _buildInfoRow(
                      _getGenderIcon(),
                      'Género',
                      widget.character.gender,
                    ),
                    if (widget.character.type.isNotEmpty)
                      _buildInfoRow(
                        Icons.category,
                        'Tipo',
                        widget.character.type,
                      ),

                    const SizedBox(height: 20),

                    // Ubicación
                    _buildSectionTitle('Ubicaciones'),
                    const SizedBox(height: 12),
                    _buildLocationCard(
                      'Ubicación Actual',
                      widget.character.location.name,
                      Icons.location_on,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildLocationCard(
                      'Origen',
                      widget.character.origin.name,
                      Icons.home,
                      Colors.green,
                    ),

                    const SizedBox(height: 20),

                    // Estadísticas
                    _buildSectionTitle('Detalles'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tag, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'ID del Personaje: #${widget.character.id}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isLoadingFavorite ? null : _toggleFavorite,
                      icon:
                          isLoadingFavorite
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                              ),
                      label: Text(
                        isFavorite ? 'Quitar Favorito' : 'Añadir Favorito',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isFavorite ? Colors.orange : Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Información de ${widget.character.name} compartida',
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    String title,
    String location,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
