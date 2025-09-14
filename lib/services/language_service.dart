import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageService extends GetxService {
  static LanguageService get to => Get.find();

  final GetStorage _storage = GetStorage();
  final RxString currentLanguage = 'en'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  void _loadLanguage() {
    final savedLanguage = _storage.read('language') ?? 'en';
    currentLanguage.value = savedLanguage;
  }

  void changeLanguage(String languageCode) {
    Locale newLocale;
    if (languageCode == 'fa') {
      newLocale = const Locale('fa', 'IR');
    } else {
      newLocale = const Locale('en', 'US');
    }

    Get.updateLocale(newLocale);
    _storage.write('language', languageCode);
    currentLanguage.value = languageCode;

    // Force rebuild of all screens to update language
    Get.forceAppUpdate();
  }

  String getLocalizedText(String key) {
    if (currentLanguage.value == 'fa') {
      switch (key) {
        // Settings Screen
        case 'Settings':
          return 'تنظیمات';
        case 'Additional Settings':
          return 'تنظیمات اضافی';
        case 'Control File':
          return 'فایل کنترل';
        case 'FAQs':
          return 'سوالات متداول';
        case 'Contact us':
          return 'تماس با ما';
        case 'About':
          return 'درباره';
        case 'Language':
          return 'زبان';
        case 'Share':
          return 'اشتراک‌گذاری';
        case 'Rate':
          return 'امتیاز';
        case 'SUPPORT US':
          return 'حمایت از ما';
        case 'English':
          return 'English';
        case 'Persian':
          return 'فارسی';
        case 'Additional Settings Description':
          return 'تنظیمات اضافی در اینجا پیاده‌سازی خواهد شد.';
        case 'Control File Description':
          return 'تنظیمات فایل کنترل در اینجا پیاده‌سازی خواهد شد.';
        case 'FAQs Description':
          return 'سوالات متداول در اینجا نمایش داده خواهد شد.';
        case 'Contact Us Description':
          return 'اطلاعات تماس در اینجا نمایش داده خواهد شد.';
        case 'About Description':
          return 'یک برنامه هوشمند کنترل بلوتوث.';
        case 'Support Us Description':
          return 'گزینه‌های پشتیبانی در اینجا نمایش داده خواهد شد.';
        case 'Share Message':
          return 'این برنامه شگفت‌انگیز اندروید فری را بررسی کنید!';
        case 'Share Subject':
          return 'برنامه اندروید فری';

        // Navigation
        case 'Charge':
          return 'شارژ';
        case 'Schedule':
          return 'برنامه‌ریزی';
        case 'Timer':
          return 'تایمر';

        // Bluetooth Screen
        case 'Fairy Bluetooth':
          return 'اندروید فری';
        case 'Battery Information':
          return 'اطلاعات باتری';
        case 'Temperature':
          return 'دما';
        case 'Status':
          return 'وضعیت';
        case 'Good':
          return 'خوب';
        case 'Normal':
          return 'عادی';
        case 'Low':
          return 'کم';
        case 'Critical':
          return 'بحرانی';
        case 'Current Battery':
          return 'باتری فعلی';
        case 'Target':
          return 'هدف';
        case 'Charging Control':
          return 'کنترل شارژ';
        case 'Charging to':
          return 'شارژ تا';
        case 'Not Charging':
          return 'شارژ نمی‌شود';
        case 'Exit App':
          return 'خروج از برنامه';
        case 'Do you want to close the app?':
          return 'آیا می‌خواهید برنامه را ببندید؟';
        case 'Yes':
          return 'بله';
        case 'No':
          return 'خیر';
        case 'Refresh Permissions':
          return 'تازه‌سازی مجوزها';

        // Schedule Screen
        case 'No device connected':
          return 'دستگاه متصل نیست';
        case 'Scheduled':
          return 'برنامه‌ریزی شده';
        case 'Failed to send':
          return 'ارسال ناموفق';
        case 'Cancel':
          return 'لغو';
        case 'Set Time':
          return 'تنظیم زمان';
        case 'Hour':
          return 'ساعت';
        case 'Minute':
          return 'دقیقه';

        // Timer Screen
        case 'Start':
          return 'شروع';
        case 'Stop':
          return 'توقف';
        case 'Reset':
          return 'بازنشانی';
        case 'Set Timer':
          return 'تنظیم تایمر';
        case 'Hours':
          return 'ساعت';
        case 'Minutes':
          return 'دقیقه';
        case 'Seconds':
          return 'ثانیه';

        default:
          return key;
      }
    } else {
      return key;
    }
  }
}
