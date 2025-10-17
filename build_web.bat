@echo off
echo Building WhispTask for Web...

REM Clean previous builds
flutter clean

REM Get dependencies
flutter pub get

REM Build web version (excluding problematic packages)
flutter build web --release --web-renderer html --dart-define=FLUTTER_WEB_USE_SKIA=false --dart-define=FLUTTER_WEB_AUTO_DETECT=false

echo Web build completed!
echo Output location: build\web\

pause
