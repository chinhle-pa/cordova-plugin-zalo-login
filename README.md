# cordova-plugin-zalo-login

> Use Zalo SDK in Cordova projects

## Table of contents

- [Installation](#installation)
- [Usage](#usage)
- [Sample repo](#sample-repo)
- [Compatibility](#compatibility)
- [Facebook SDK](#facebook-sdk)
- [API](#api)

## Installation

See npm package for versions - https://www.npmjs.com/package/cordova-plugin-facebook-connect

Make sure you've registered your Zalo app with Zalo and have an `ZALO_APP_ID` [https://developers.zalo.me/app](https://developers.zalo.me/app).

```bash
$ cordova plugin add cordova-plugin-zalo-login --save --variable ZALO_APP_ID="123456789"
```

If you need to change your `ZALO_APP_ID` after installation, it's recommended that you remove and then re-add the plugin as above. Note that changes to the `ZALO_APP_ID` value in your `config.xml` file will *not* be propagated to the individual platform builds.

### Android config.xml
		<plugin name="cordova-plugin-zalo-login" spec="1.0.0">
            <variable name="ZALO_APP_ID" default="2382863458001662740" />
        </plugin>
        <edit-config file="app/src/main/AndroidManifest.xml" target="/manifest/application" mode="merge">
            <application android:name="com.zing.zalo.zalosdk.oauth.ZaloSDKApplication" />
        </edit-config>

## Compatibility

  * Cordova >= 5.0.0
  * cordova-android >= 7.0.0


