**Owal** mobile
===================
Introduction
-------------
This is the application project for the mobile client of the Owal platform.

How to run the application
-------------

#### <i class="icon-file"></i> iOS

1- Clone the repository
```
git clone https://github.com/owal/mobile.git owal-mobile
cd owal
git fetch; git submodule update --init
```

2- Install all the dependencies
```
cd <root-folder>/ && npm install
```

3- Run the application in the simulator

```
react-native run-ios
```

To view logs:

```
react-native logs-ios
```

----------
#### <i class="icon-file"></i> Android
1- Clone the repository
```
git clone https://github.com/owal/mobile.git owal-mobile
```

2- Install all the dependencies
```
cd <root-folder>/ && npm install
```
3- Install the Android SDK
Android Studio puts it in ~/Library/Android/sdk
Make sure you get Android SDK Build Tools 23.0.2
```
~/Library/Android/sdk/tools/android
```

Tell react-native where your Anroid SDK is. In your ~/.profile, add:
```
export ANDROID_HOME="/Users/{username}/Library/Android/sdk/"
```

4- Run the application using the Android SDK
```
react-native run-android
```

If it complains that you don't have an emulator, then open Android Studio and
click the AVD Manager button. Create (or launch) an AVD; I use Nexus 5X on
API 23 (Marshmallow) w/ Google APIs. Make sure it's an x86 - x86_64 uses
unnecessarily more RAM, and an ARM would be too slow.


