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
git clone https://github.com/owal/mobile.git
```

2- Install all the dependencies
```
cd <root-folder>/ && npm install
```

3- Install the FacebookSDK for iOS

Download FB sdk here: ***version: 4.13.1***

https://origincache.facebook.com/developers/resources/?id=facebook-ios-sdk-current.zip

Make sure that you put it under ~/Documents/<FB-FOLDER> and then update the Build Framework path on Xcode.

4- Install RNPM and React Native sdk bridge
```
npm install rnpm -g

rnpm install react-native-fbsdk
```

4- Run the application in the simulator

Open the .xcodeproj file under the root /ios folder and then run as you would any other Xcode project in the simulator.

----------
#### <i class="icon-file"></i> Android
1- Clone the repository
```
git clone https://github.com/owal/mobile.git
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
