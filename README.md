# cordova-plugin-zalo-login

> Use Zalo SDK in Cordova projects

## Table of contents

- [Release](#release)
- [Installation](#installation)
- [Usage](#usage)
- [Sample repo](#sample-repo)
- [Compatibility](#compatibility)
- [Zalo SDK](#zalo-sdk)
- [API](#api)

## Release (1.1.2)

Update new ZaloSDK which for Zalo login v4.

- iOS: https://developers.zalo.me/docs/sdk/ios-sdk-196

- Android: https://developers.zalo.me/docs/sdk/android-sdk-203

## Installation

See npm package for versions - https://www.npmjs.com/package/cordova-plugin-zalo-login

Make sure you've registered your Zalo app with Zalo and have an `ZALO_APP_ID` [https://developers.zalo.me/app](https://developers.zalo.me/app).

```bash
$ cordova plugin add cordova-plugin-zalo-login --save --variable ZALO_APP_ID="123456789"
```

If you need to change your `ZALO_APP_ID` after installation, it's recommended that you remove and then re-add the plugin as above. Note that changes to the `ZALO_APP_ID` value in your `config.xml` file will *not* be propagated to the individual platform builds.

### Android config.xml
        <edit-config xmlns:android="http://schemas.android.com/apk/res/android" file="app/src/main/AndroidManifest.xml" mode="merge" target="/manifest/application">
            <application android:name="com.zing.zalo.zalosdk.oauth.ZaloSDKApplication" />
        </edit-config>

## Compatibility

  * Cordova >= 5.0.0
  * cordova-android >= 7.0.0
  * cordova-ios > 5.0.0

## Zalo SDK

## API
### Login

In your `onDeviceReady` event add the following

```js
zaloLoginPlugin.login([], function loginSuccess(data){
    console.log(data)
    },
  function loginError (error) {
    console.error(error)
  }
);
```


