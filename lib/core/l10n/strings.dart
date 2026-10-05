/// All Persian UI strings in one place.
/// No Persian literals should appear in Widget files.
class S {
  // ── App ──────────────────────────────────────────────────────────────────
  static const appName        = 'ALPHA VPN';
  static const appSlogan      = 'اینترنت آزاد، سریع و امن';
  static const appWelcome     = 'به دنیای اینترنت آزاد خوش آمدید';

  // ── Nav tabs ─────────────────────────────────────────────────────────────
  static const navHome         = 'خانه';
  static const navServers      = 'سرورها';
  static const navSubscription = 'اشتراک';
  static const navSettings     = 'تنظیمات';

  // ── Login ─────────────────────────────────────────────────────────────────
  static const loginTitle       = 'ورود به حساب';
  static const loginSubtitle    = 'نام کاربری و رمزی که از پشتیبانی دریافت‌کرده‌اید را وارد کنید';
  static const loginUsername    = 'نام کاربری';
  static const loginPassword    = 'رمز عبور';
  static const loginButton      = 'ورود';
  static const loginSupport     = 'در صورت مشکل به ما در تلگرام پیام دهید ';
  static const loginSupportArrow = '❯';
  static const loginErrorEmpty  = 'نام کاربری و رمز عبور را وارد کنید';
  static const loginErrorInvalid = 'نام کاربری یا رمز عبور اشتباه است';
  static const loginLoading     = 'در حال ورود...';

  // ── Home ──────────────────────────────────────────────────────────────────
  static const homeConnected      = 'متصل هستید';
  static const homeNotConnected   = 'متصل نیستید';
  static const homeConnecting     = 'در حال اتصال...';
  static const homeDisconnecting  = 'در حال قطع اتصال...';
  static const homeTapToConnect   = 'برای اتصال لمس کنید';
  static const homePing           = 'پینگ';
  static const homeUsage          = 'مصرف این اتصال';
  static const homeMeg            = 'مگ';
  static const homeGig            = 'گیگ';
  static const homeDay            = 'روز';
  static const homeDays           = 'روز';
  static const homeRemainingVolume = 'حجم باقیمانده';
  static const homeRemainingTime  = 'زمان باقیمانده';

  // ── Servers ───────────────────────────────────────────────────────────────
  static const serversTitle        = 'سرورها';
  static const serversSubtitle     = 'سرور در دسترس';   // prepend count
  static const serversSmartServer  = 'سرور هوشمند';
  static const serversSmartSubtitle = 'اتصال خودکار به کمترین پینگ';
  static const serversLocations    = 'لوکیشن';           // append count
  static const serversRefresh      = 'بروزرسانی';
  static const serversSortPing     = 'مرتب بر اساس پینگ';

  // ── Subscription ─────────────────────────────────────────────────────────
  static const subTitle            = 'اشتراک من';
  static const subRemainingVolume  = 'حجم باقیمانده';
  static const subRemainingTime    = 'زمان باقیمانده';
  static const subTotalUsage       = 'مصرف کل';
  static const subTotalVolume      = 'حجم کل اشتراک';
  static const subPurchasedDays    = 'روزهای خریداری‌شده';
  static const subRemainingDays    = 'روزهای باقیمانده';
  static const subExpiry           = 'پایان اشتراک';
  static const subGiftCode         = 'کد هدیه دارید؟';
  static const subGiftCodeHint     = 'کد هدیه را اینجا وارد کنید';
  static const subGiftCodeSubmit   = 'ثبت کد';
  static const subGiftCodeSuccess  = 'کد هدیه با موفقیت اعمال شد';
  static const subGiftCodeError    = 'کد هدیه نامعتبر است';
  static const subRefresh          = 'بروزرسانی';
  static const subGig              = 'گیگ';
  static const subDay              = 'روز';
  static const subFrom             = 'از';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const settingsTitle          = 'تنظیمات';
  static const settingsAppearance     = 'ظاهر برنامه';
  static const settingsDisplayMode    = 'حالت نمایش';
  static const settingsThemeAuto      = 'خودکار';
  static const settingsThemeLight     = 'روشن';
  static const settingsThemeDark      = 'تیره';
  static const settingsConnection     = 'اتصال';
  static const settingsWhitelist      = 'لیست سفید برنامه‌ها';
  static const settingsWhitelistSub   = 'همه برنامه‌ها از VPN استفاده می‌کنند';
  static const settingsDirectIran     = 'عبور مستقیم سایت‌های ایرانی';
  static const settingsDirectIranSub  = 'سایت‌های ایرانی سریع‌تر و بدون مصرف حجم باز می‌شوند';
  static const settingsAdBlock        = 'مسدودسازی تبلیغات';
  static const settingsAdBlockSub     = 'تبلیغات شناخته‌شده در همه برنامه‌ها حذف می‌شود';
  static const settingsUsername       = 'نام کاربری';
  static const settingsDevice         = 'شناسه دستگاه';
  static const settingsLogout         = 'خروج از حساب';
  static const settingsLogoutConfirm  = 'آیا می‌خواهید از حساب خارج شوید؟';
  static const settingsLogoutYes      = 'بله، خارج شو';
  static const settingsLogoutNo       = 'انصراف';
  static const settingsLeaveHere      = 'بگذارید';

  // ── Whitelist ─────────────────────────────────────────────────────────────
  static const whitelistTitle       = 'لیست سفید برنامه‌ها';
  static const whitelistSubtitle    = 'برنامه‌هایی که از VPN استفاده می‌کنند';
  static const whitelistSearch      = 'جستجوی برنامه';
  static const whitelistEmpty       = 'برنامه‌ای یافت نشد';
  static const whitelistSelectAll   = 'انتخاب همه';
  static const whitelistDeselectAll = 'لغو انتخاب همه';

  // ── Common ────────────────────────────────────────────────────────────────
  static const ok           = 'باشه';
  static const cancel       = 'انصراف';
  static const retry        = 'تلاش دوباره';
  static const loading      = 'در حال بارگذاری...';
  static const error        = 'خطا';
  static const errorNetwork = 'خطا در اتصال به شبکه';
  static const errorUnknown = 'خطای ناشناخته';
  static const connected    = 'متصل';
  static const disconnected = 'قطع';
  static const back         = 'بازگشت';
  static const save         = 'ذخیره';
  static const confirm      = 'تأیید';
  static const close        = 'بستن';
}
