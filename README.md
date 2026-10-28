# تَذَكَّر (Tathakkar)

Flutter + Firebase · Clean Architecture · BLoC · Hive · AR/EN (RTL) · Cairo font

## ما يجب فعله قبل التشغيل (بالترتيب)

1. **إنشاء مجلدات المنصات** (غير موجودة في هذا الملف):
   ```bash
   flutter create --org com.tathakkar --project-name tathakkar .
   ```
   (يحافظ على مجلد `lib/` و`pubspec.yaml` الحاليين؛ إن استبدل `pubspec.yaml` أعد نسخه.)
2. **خط Cairo**: حمّله من Google Fonts وضع الملفات في `assets/fonts/`:
   `Cairo-Regular.ttf`, `Cairo-SemiBold.ttf`, `Cairo-Bold.ttf`.
3. **صوت المنبّه**: ضع ملفاً باسم `assets/sounds/alarm.mp3` (إن غاب لن ينهار التطبيق، فقط لن يُسمع صوت داخل شاشة التذكير).
4. **Firebase**: أنشئ مشروعاً ثم `flutterfire configure` (أو ضع `google-services.json` و`GoogleService-Info.plist`).
   فعّل: Authentication (Email/Password) + Cloud Firestore + Cloud Messaging.
5. **قواعد Firestore**: انشر `backend/firestore.rules` و`backend/firestore.indexes.json`:
   `firebase deploy --only firestore`.
6. **Cloud Functions** (إشعارات مقدّم الرعاية): من `backend/functions`:
   `npm i && firebase deploy --only functions` (يتطلب خطة Blaze).
7. `flutter pub get` ثم `flutter run`. للاختبارات: `flutter test`.

## إعدادات Android (android/app/src/main/AndroidManifest.xml)
داخل `<manifest>`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
داخل `<application>` (لاستعادة التنبيهات بعد إعادة تشغيل الجهاز):
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```
وفي `<activity android:name=".MainActivity" ...>` أضف: `android:showWhenLocked="true" android:turnScreenOn="true"`.
في `android/app/build.gradle(.kts)`: `minSdk = 23` وفعّل `coreLibraryDesugaring` (مطلوب لـ flutter_local_notifications).

## إعدادات iOS
- `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`.
- Capabilities: Push Notifications + Background Modes (Remote notifications).
- مفتاح APNs في Firebase للإشعارات البعيدة. ملاحظة: iOS لا يسمح بعرض بملء الشاشة فوق القفل؛ يُستخدم تنبيه Time-Sensitive بدلاً منه.

## هيكل المشروع
```
lib/
  core/        constants, theme, localization, errors, forms, utils, di, router, storage, services, widgets
  features/    <feature>/{domain,data,presentation}
    splash · onboarding · settings · auth · profiles · medications · doses
    reminders · care_link · history · inbox · home · account · connectivity
```
كل ميزة: `bloc/` فيه ملفات منفصلة `*_event.dart` و`*_state.dart` و`*_bloc.dart`.
لإضافة نص جديد: أضف المفتاح في `l10n_keys.dart` ثم `strings_ar.dart` و`strings_en.dart`.

## قرارات تصميم
- **flutter_screenutil غير مستخدم**: التجاوب يتم بحدّ أقصى للعرض على التابلت (`ResponsiveBody`) + تمرير آمن + ضبط حجم الخط (0.9–1.35). مستخدم واحد لا يحتاج تحجيم البكسل.
- **الأمان**: الصلاحيات تُفرض في الـ UseCase **وفي قواعد Firestore** معاً. المسن الخاضع للرعاية يعدّل فقط عدّاد المخزون (عند تأكيد الجرعة).
- **الصور**: تُحفظ كمسار محلي على الجهاز (لا تتزامن بين الهاتفين). للمزامنة أضف `firebase_storage`.
- **دون إنترنت**: قوائم الأدوية في Hive، وFirestore offline persistence، وتأكيد الجرعة يُوضع في طابور الكتابة.
- الجرعات تُخصم مرة واحدة فقط (معرّف سجل حتمي + transaction).
- التذكير بعد التأجيل ثم تذكير أخير (بحد أقصى تأجيلين) وفق ما تقرر.

## حدود معروفة / قرارات مفتوحة
- أزرار "أخذت/تأجيل" داخل الإشعار نفسه غير مضافة (تتطلب background isolate)؛ الضغط على الإشعار يفتح شاشة التذكير.
- إشعار "غير مؤكدة" يعتمد على Cloud Function كل 5 دقائق (دقة ±5 دقائق).
- تعارض التعديلات بين الهاتفين: Last-write-wins حالياً (نقطة مفتوحة في المواصفات).
- فك الارتباط: للمسن فقط حالياً (سياسة مقدّم الرعاية لم تُحدَّد بعد).
- لم يُشغَّل الكود في بيئة Flutter (غير متوفرة هنا)؛ فُحصت الواردات والمفاتيح والأقواس آلياً فقط. توقّع بضع تعديلات صغيرة عند أول `flutter analyze`، خصوصاً توقيعات الحزم (flutter_timezone, mobile_scanner).
