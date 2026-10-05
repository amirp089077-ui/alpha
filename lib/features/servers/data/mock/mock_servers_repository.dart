import '../models/server_models.dart';

class MockServersRepository {
  static const List<ServerGroup> _groups = [
    ServerGroup(
      id: 'uk',
      country: 'انگلیس',
      flagEmoji: '🇬🇧',
      locations: [
        ServerLocation(id: 'uk-1', name: 'انگلیس - ۱', flagEmoji: '🇬🇧', ping: 120),
        ServerLocation(id: 'uk-2', name: 'انگلیس - ۲', flagEmoji: '🇬🇧', ping: 145),
        ServerLocation(id: 'uk-3', name: 'انگلیس - ۳', flagEmoji: '🇬🇧', ping: 138),
        ServerLocation(id: 'uk-4', name: 'انگلیس - ۴', flagEmoji: '🇬🇧', ping: 165, badge: ServerBadge.b),
      ],
    ),
    ServerGroup(
      id: 'de',
      country: 'آلمان',
      flagEmoji: '🇩🇪',
      locations: [
        ServerLocation(id: 'de-1', name: 'آلمان - ۱', flagEmoji: '🇩🇪', ping: 95),
        ServerLocation(id: 'de-2', name: 'آلمان - ۲', flagEmoji: '🇩🇪', ping: 110, badge: ServerBadge.b),
        ServerLocation(id: 'de-3', name: 'آلمان - ۳', flagEmoji: '🇩🇪', ping: 102),
      ],
    ),
    ServerGroup(
      id: 'fr',
      country: 'فرانسه',
      flagEmoji: '🇫🇷',
      locations: [
        ServerLocation(id: 'fr-1', name: 'فرانسه - ۱', flagEmoji: '🇫🇷', ping: 130),
        ServerLocation(id: 'fr-2', name: 'فرانسه - ۲', flagEmoji: '🇫🇷', ping: 155),
      ],
    ),
    ServerGroup(
      id: 'special',
      country: 'مناطق خاص',
      flagEmoji: '🌐',
      isSpecial: true,
      locations: [
        ServerLocation(id: 'sp-1', name: 'مناطق خاص - ۱', flagEmoji: '🌐', ping: 88),
        ServerLocation(id: 'sp-2', name: 'مناطق خاص - ۲', flagEmoji: '🌐', ping: 92),
        ServerLocation(id: 'sp-3', name: 'مناطق خاص - ۳', flagEmoji: '🌐', ping: 76),
        ServerLocation(id: 'sp-4', name: 'مناطق خاص - ۴', flagEmoji: '🌐', ping: 110),
      ],
    ),
    ServerGroup(
      id: 'se',
      country: 'سوئد',
      flagEmoji: '🇸🇪',
      locations: [
        ServerLocation(id: 'se-1', name: 'سوئد - ۱', flagEmoji: '🇸🇪', ping: 150),
        ServerLocation(id: 'se-2', name: 'سوئد - ۲', flagEmoji: '🇸🇪', ping: 162),
        ServerLocation(id: 'se-3', name: 'سوئد - ۳', flagEmoji: '🇸🇪', ping: 145),
      ],
    ),
    ServerGroup(
      id: 'es',
      country: 'اسپانیا',
      flagEmoji: '🇪🇸',
      locations: [
        ServerLocation(id: 'es-1', name: 'اسپانیا - ۱', flagEmoji: '🇪🇸', ping: 175, badge: ServerBadge.b),
        ServerLocation(id: 'es-2', name: 'اسپانیا - ۲', flagEmoji: '🇪🇸', ping: 188),
      ],
    ),
  ];

  Future<List<ServerGroup>> fetchServers() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _groups;
  }

  Future<void> refreshPings() async {
    await Future.delayed(const Duration(milliseconds: 1200));
  }
}
