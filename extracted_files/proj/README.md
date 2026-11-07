# مكتبتي الرقمية — تطبيق iOS

تطبيق يغلّف الموقع: https://allmohsen.github.io/Alrubeiy-libry/

## الطريقة 1: بدون جهاز Mac (عبر GitHub)
1. أنشئ مستودعاً جديداً على GitHub وارفع محتويات هذا المجلد كما هي (بما فيها مجلد .github).
2. افتح تبويب Actions ← Build IPA ← Run workflow.
3. بعد انتهاء البناء حمّل الملف AlrubeiyLibrary.ipa من Artifacts.
4. ملف IPA هنا غير موقّع. ثبّته على الآيفون باستخدام Sideloadly أو AltStore (يكفي Apple ID مجاني، ويحتاج تجديداً كل 7 أيام).

## الطريقة 2: على Mac
1. brew install xcodegen
2. xcodegen generate
3. افتح AlrubeiyLibrary.xcodeproj في Xcode، اختر Team في Signing & Capabilities.
4. شغّله على جهازك، أو Product ← Archive لتصدير IPA موقّع.

ملاحظات:
- يحتاج التطبيق إنترنت لتحميل الموقع. عند انقطاعه تظهر صفحة "إعادة المحاولة".
- بيانات الكتب محفوظة داخل التطبيق نفسه، فخذ نسخة احتياطية من داخل الموقع بشكل دوري.
