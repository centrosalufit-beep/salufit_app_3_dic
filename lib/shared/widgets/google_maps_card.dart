import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GoogleMapsReviewCard extends StatelessWidget {
  const GoogleMapsReviewCard({
    super.key,
    this.rating = 5.0,
    this.reviewsCount = 523,
  });

  final double rating;
  final int reviewsCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(
          'https://www.google.com/maps/place/SALUFIT+%7C+Centro+integral+en+Calpe/@38.6514863,0.0717062,17z/data=!4m8!3m7!1s0x129dff5c0a60d747:0x843fa58120d75000!8m2!3d38.6514863!4d0.0717062!9m1!1b1!16s%2Fg%2F11h7z1lcb9?hl=es&entry=ttu&g_ep=EgoyMDI2MDIwNC4wIKXMDSoASAFQAw%3D%3D',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                height: 18,
                width: 18,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFB8860B),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Tu ayuda nos hace crecer!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Text(
                    'Deja tu reseña en Google Maps',
                    style: TextStyle(
                      color: Color(0xFFEEEEEE),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${rating.toStringAsFixed(1)} ⭐',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($reviewsCount reseñas)',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
