/// انواع اعلان
enum NotifType {
  broadcast,    // بنر اصلی — همیشه پین
  offer,        // پیشنهاد ویژه با badge و discount
  tip,          // نکته آموزشی
  announcement, // اطلاعیه عمومی
  success,      // موفقیت/خبر خوش
  warning,      // هشدار
  error,        // خطا/مشکل
  info,         // اطلاعات
}

extension NotifTypeX on NotifType {
  static NotifType fromString(String s) {
    switch (s.toLowerCase()) {
      case 'broadcast':    return NotifType.broadcast;
      case 'offer':        return NotifType.offer;
      case 'tip':          return NotifType.tip;
      case 'announcement': return NotifType.announcement;
      case 'success':      return NotifType.success;
      case 'warning':      return NotifType.warning;
      case 'error':        return NotifType.error;
      default:             return NotifType.info;
    }
  }
}

// ─── مدل اعلان ────────────────────────────────────────────────────────────────

class AppNotification {
  final String   id;
  final NotifType type;
  final String   title;
  final String   body;
  final String   tone;        // info | warning | success | error
  final String   actionUrl;
  final String   actionLabel;
  final String   imageUrl;
  final String   badge;
  final String   expiresAt;
  final String   discount;    // فقط برای offer
  final bool     isNew;
  final bool     pinned;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.tone        = 'info',
    this.actionUrl   = '',
    this.actionLabel = '',
    this.imageUrl    = '',
    this.badge       = '',
    this.expiresAt   = '',
    this.discount    = '',
    this.isNew       = false,
    this.pinned      = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id:          (j['id']           as Object?)?.toString() ?? '',
      type:        NotifTypeX.fromString((j['type'] as String?) ?? 'info'),
      title:       (j['title']        as String?) ?? '',
      body:        (j['body']         as String?) ?? '',
      tone:        (j['tone']         as String?) ?? 'info',
      actionUrl:   (j['action_url']   as String?) ?? '',
      actionLabel: (j['action_label'] as String?) ?? '',
      imageUrl:    (j['image_url']    as String?) ?? '',
      badge:       (j['badge']        as String?) ?? '',
      expiresAt:   (j['expires_at']   as String?) ?? '',
      discount:    (j['discount']     as String?) ?? '',
      isNew:       (j['is_new']       as bool?)   ?? false,
      pinned:      (j['pinned']       as bool?)   ?? false,
    );
  }

  AppNotification copyWith({bool? isNew}) => AppNotification(
    id:          id,
    type:        type,
    title:       title,
    body:        body,
    tone:        tone,
    actionUrl:   actionUrl,
    actionLabel: actionLabel,
    imageUrl:    imageUrl,
    badge:       badge,
    expiresAt:   expiresAt,
    discount:    discount,
    isNew:       isNew ?? this.isNew,
    pinned:      pinned,
  );
}

// ─── State ────────────────────────────────────────────────────────────────────

enum NotifStatus { initial, loading, loaded, error }

class NotificationsState {
  final NotifStatus            status;
  final List<AppNotification>  items;
  final int                    unread;
  final String?                errorMessage;

  const NotificationsState({
    this.status       = NotifStatus.initial,
    this.items        = const [],
    this.unread       = 0,
    this.errorMessage,
  });

  int get unreadCount => items.where((n) => n.isNew).length;

  /// فقط اعلان‌هایی که در home نشون داده میشن
  List<AppNotification> get homeItems => items
      .where((n) => n.type == NotifType.offer || n.type == NotifType.tip)
      .toList();

  NotificationsState copyWith({
    NotifStatus?           status,
    List<AppNotification>? items,
    int?                   unread,
    String?                errorMessage,
  }) {
    return NotificationsState(
      status:       status       ?? this.status,
      items:        items        ?? this.items,
      unread:       unread       ?? this.unread,
      errorMessage: errorMessage,
    );
  }
}
